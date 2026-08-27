import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/features/workspace/todo.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  testWidgets('mobile search expands, submits, clears, and collapses', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          _todo('detail', title: 'Alpha', detail: 'needle detail'),
          _todo('tag', title: 'Beta', tags: const ['needle']),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    expect(find.byKey(const ValueKey('mobile-search-input')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mobile-search-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('mobile-search-surface')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('mobile-search-input')),
      'needle',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-search-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-search-input')), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-search-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mobile-search-clear')));
    await tester.pump();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-search-surface')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-search-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-search-surface')), findsNothing);
  });

  testWidgets('search is debounced, highlights titles, and shows no results', (
    tester,
  ) async {
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          _todo('title', title: 'Plan needle review'),
          _todo('detail', title: 'Other', detail: 'needle in details'),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    final search = find.byKey(const ValueKey('todo-search-input'));
    await tester.enterText(search, 'needle');
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.text('Plan needle review'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            (widget.text as TextSpan).toPlainText() == 'Plan needle review',
      ),
      findsOneWidget,
    );
    expect(find.text('Other'), findsOneWidget);
    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            (widget.text as TextSpan).toPlainText() == 'Plan needle review',
      ),
    );
    final spans = richText.text as TextSpan;
    expect(spans.children, isNotEmpty);
    expect(
      spans.children!.whereType<TextSpan>().any(
        (span) => span.style?.fontWeight == FontWeight.bold,
      ),
      isTrue,
    );

    await tester.enterText(search, 'missing');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('todo-empty-results')), findsOneWidget);
    expect(find.text('No Todos match these conditions.'), findsOneWidget);
  });

  testWidgets('priority filter changes the local result set', (tester) async {
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          _todo('high', title: 'High todo', priority: TodoPriority.high),
          _todo('low', title: 'Low todo', priority: TodoPriority.low),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    await tester.tap(find.byKey(const ValueKey('todo-priority-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('High todo'), findsOneWidget);
    expect(find.text('Low todo'), findsNothing);
  });
}

Todo _todo(
  String id, {
  String title = '',
  String detail = '',
  TodoPriority priority = TodoPriority.medium,
  List<String> tags = const [],
}) {
  return Todo.create(
    id: id,
    listId: 'default',
    title: title,
    detail: detail,
    priority: priority,
    tags: tags,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
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
