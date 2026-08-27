import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/features/workspace/todo.dart';
import 'package:aknirex_todo/features/workspace/todo_editor_page.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  test('parses mixed comma separators and normalizes Tag values', () {
    expect(parseTodoTags(' work ， home, ,work，home '), ['work', 'home']);
  });

  testWidgets('new Todo editor focuses detail and page back discards it', (
    tester,
  ) async {
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    await _pumpApp(tester, workspace);

    await tester.tap(find.byTooltip('Create Todo'));
    await tester.pumpAndSettle();

    final detail = find.byKey(const ValueKey('todo-detail-input'));
    expect(detail, findsOneWidget);
    expect(tester.widget<TextField>(detail).focusNode!.hasFocus, isTrue);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(workspace.current.todos, isEmpty);
  });

  testWidgets(
    'first system back dismisses new-editor focus and second back discards',
    (tester) async {
      final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
      await workspace.start();
      await _pumpApp(tester, workspace);

      await tester.tap(find.byTooltip('Create Todo'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('todo-detail-input')), findsOneWidget);
      expect(workspace.current.todos, isEmpty);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('todo-detail-input')), findsNothing);
      expect(workspace.current.todos, isEmpty);
    },
  );

  testWidgets(
    'existing Todo loads all fields and saves one normalized edit on back',
    (tester) async {
      final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
      await workspace.start();
      await workspace.createTodo(
        title: 'Before',
        detail: 'Old detail',
        priority: TodoPriority.medium,
        dueDate: DateTime(2026, 6, 7),
        tags: const ['old'],
      );
      await _pumpApp(tester, workspace);

      await tester.tap(find.text('Before'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Todo'), findsOneWidget);
      expect(find.text('Old detail'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data?.contains('2026') == true,
        ),
        findsOneWidget,
      );
      expect(find.text('Separate tags with commas'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('todo-title-input')),
        'After',
      );
      await tester.enterText(
        find.byKey(const ValueKey('todo-detail-input')),
        'New detail',
      );
      await tester.tap(find.byKey(const ValueKey('todo-priority-input')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High').last);
      await tester.enterText(
        find.byKey(const ValueKey('todo-tags-input')),
        ' work , ,work, home ',
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      final saved = workspace.current.todos.single;
      expect(saved.title, 'After');
      expect(saved.detail, 'New detail');
      expect(saved.priority, TodoPriority.high);
      expect(saved.dueDate, DateTime(2026, 6, 7));
      expect(saved.tags, ['work', 'home']);
    },
  );

  testWidgets(
    'system back saves an existing Todo after the keyboard is dismissed',
    (tester) async {
      final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
      await workspace.start();
      await workspace.createTodo(title: 'Before');
      await _pumpApp(tester, workspace);

      await tester.tap(find.text('Before'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('todo-title-input')),
        'Saved by system back',
      );
      tester.testTextInput.hide();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(workspace.current.todos.single.title, 'Saved by system back');
      expect(find.text('Saved by system back'), findsOneWidget);
    },
  );
}

Future<void> _pumpApp(WidgetTester tester, TodoWorkspace workspace) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(
          MemorySettingsStore(const AppSettings(locale: Locale('en'))),
        ),
        todoWorkspaceProvider.overrideWith((ref) async => workspace),
      ],
      child: const TodoApp(),
    ),
  );
  await tester.pumpAndSettle();
}
