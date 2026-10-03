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

  testWidgets('shows detail summary for untitled Todos and keeps blank rows', (
    tester,
  ) async {
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          _todo('detail', detail: 'Meeting notes for the mobile workspace'),
          _todo('blank'),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    expect(find.text('Meeting notes for the mobile workspace'), findsOneWidget);
    expect(find.byKey(const ValueKey('todo-delete-blank')), findsOneWidget);
  });

  testWidgets('narrow screens expose sibling sort and filter controls', (
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
          _todo('high', title: 'Alpha', priority: TodoPriority.high),
          _todo(
            'high-tag',
            title: 'Zulu',
            priority: TodoPriority.high,
            tags: const ['work'],
          ),
          _todo('low', title: 'Bravo', priority: TodoPriority.low),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    final sort = find.byKey(const ValueKey('todo-sort-filter'));
    await tester.ensureVisible(sort);
    expect(tester.getSize(sort).height, greaterThanOrEqualTo(48));
    await tester.tap(sort);
    await tester.pumpAndSettle();
    expect(find.text('Title Z-A'), findsOneWidget);
    await tester.tap(find.text('Title Z-A').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Title Z-A'), findsOneWidget);

    final priority = find.byKey(const ValueKey('todo-priority-filter'));
    await tester.ensureVisible(priority);
    await tester.tap(priority);
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    final tag = find.byKey(const ValueKey('todo-tag-filter'));
    await tester.ensureVisible(tag);
    await tester.tap(tag);
    await tester.pumpAndSettle();
    await tester.tap(find.text('work').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Zulu'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Bravo'), findsNothing);
  });

  testWidgets('every filter and sort control meets the 48px touch target', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(todos: [_todo('one', title: 'One')]),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    for (final key in const [
      'todo-priority-filter',
      'todo-tag-filter',
      'todo-status-filter',
      'todo-due-date-filter',
      'todo-sort-filter',
    ]) {
      final control = find.byKey(ValueKey(key));
      await tester.ensureVisible(control);
      expect(
        tester.getSize(control).height,
        greaterThanOrEqualTo(48),
        reason: '$key must meet the minimum touch target',
      );
      final menu = tester.widget<PopupMenuButton<Object>>(control);
      expect(
        menu.popUpAnimationStyle?.duration,
        const Duration(milliseconds: 120),
        reason: '$key must open with the faster mobile animation',
      );
      expect(menu.position, PopupMenuPosition.under);
    }
  });

  testWidgets('status filter shows completed and resets via All', (
    tester,
  ) async {
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          _todo('active', title: 'Active one'),
          _todo('done', title: 'Done one', completed: true),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    await tester.tap(find.byKey(const ValueKey('todo-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Done one'), findsOneWidget);
    expect(find.text('Active one'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('todo-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Done one'), findsOneWidget);
    expect(find.text('Active one'), findsOneWidget);
  });

  testWidgets('due date filter multi-selects today, overdue, and no due date', (
    tester,
  ) async {
    final today = DateTime.now();
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          _todo('due-today', title: 'Due today', dueDate: today),
          _todo('overdue', title: 'Overdue one', dueDate: DateTime(2020, 1, 1)),
          _todo('none', title: 'No date one'),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    Future<void> toggle(String label) async {
      await tester.tap(find.byKey(const ValueKey('todo-due-date-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    await toggle('Today');
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Overdue one'), findsNothing);
    expect(find.text('No date one'), findsNothing);

    await toggle('Overdue');
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Overdue one'), findsOneWidget);

    await toggle('No due date');
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Overdue one'), findsOneWidget);
    expect(find.text('No date one'), findsOneWidget);

    await toggle('Overdue');
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Overdue one'), findsNothing);
    expect(find.text('No date one'), findsOneWidget);
  });

  testWidgets('priority filter supports multi-select and deselect', (
    tester,
  ) async {
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          _todo('high', title: 'High one', priority: TodoPriority.high),
          _todo('medium', title: 'Medium one'),
          _todo('low', title: 'Low one', priority: TodoPriority.low),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    Future<void> toggle(String label) async {
      await tester.tap(find.byKey(const ValueKey('todo-priority-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    await toggle('High');
    expect(find.text('High one'), findsOneWidget);
    expect(find.text('Medium one'), findsNothing);

    await toggle('Low');
    expect(find.text('High one'), findsOneWidget);
    expect(find.text('Low one'), findsOneWidget);

    await toggle('High');
    expect(find.text('High one'), findsNothing);
    expect(find.text('Low one'), findsOneWidget);
  });

  testWidgets('expanded mobile search blocks background interaction', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(todos: [_todo('one', title: 'Block me')]),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    await tester.tap(find.byKey(const ValueKey('mobile-search-toggle')));
    await tester.pump();

    final checkbox = find.byType(Checkbox).first;
    await tester.tap(checkbox, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(workspace.current.todos.single.completed, isFalse);
    expect(find.byKey(const ValueKey('mobile-search-surface')), findsOneWidget);
  });

  testWidgets('system back collapses the expanded mobile search', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(todos: [_todo('one', title: 'Still here')]),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    await tester.tap(find.byKey(const ValueKey('mobile-search-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('mobile-search-surface')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-search-surface')), findsNothing);
    expect(find.byKey(const ValueKey('workspace-title')), findsOneWidget);
    expect(find.text('Still here'), findsOneWidget);
  });

  testWidgets('untitled Todo summaries are highlighted by mobile search', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [_todo('notes', detail: 'Meeting notes for the workspace')],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    await tester.tap(find.byKey(const ValueKey('mobile-search-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('mobile-search-input')),
      'meeting',
    );
    await tester.pump(const Duration(milliseconds: 300));

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            (widget.text as TextSpan).toPlainText() ==
                'Meeting notes for the workspace',
      ),
    );
    final spans = richText.text as TextSpan;
    expect(
      spans.children!.whereType<TextSpan>().any(
        (span) => span.style?.fontWeight == FontWeight.bold,
      ),
      isTrue,
    );
  });

  testWidgets('every Todo row shows the priority color bar', (tester) async {
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(todos: [_todo('bare', title: 'Bare todo')]),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    expect(find.text('Bare todo'), findsOneWidget);
    final priorityBar = find.byKey(const ValueKey('todo-priority-bar-bare'));
    expect(priorityBar, findsOneWidget);
    expect(find.text('Medium'), findsNothing);
  });

  testWidgets('crossing to a wide breakpoint collapses the expanded search', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(todos: [_todo('one', title: 'One')]),
    );
    await workspace.start();
    await _pumpApp(tester, workspace);

    await tester.tap(find.byKey(const ValueKey('mobile-search-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('mobile-search-surface')), findsOneWidget);

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-search-surface')), findsNothing);
    expect(find.byKey(const ValueKey('mobile-search-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('todo-search-input')), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
  });
}

Todo _todo(
  String id, {
  String title = '',
  String detail = '',
  TodoPriority priority = TodoPriority.medium,
  DateTime? dueDate,
  Iterable<String> tags = const <String>[],
  bool completed = false,
}) {
  return Todo.create(
    id: id,
    listId: 'default',
    title: title,
    detail: detail,
    priority: priority,
    dueDate: dueDate,
    tags: tags,
    completed: completed,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}

Future<void> _setMobileSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
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
