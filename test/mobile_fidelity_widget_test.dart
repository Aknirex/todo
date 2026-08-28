import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/features/workspace/todo.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  testWidgets(
    'compact workspace keeps actions and controls reachable at 390x844',
    (tester) async {
      await _setMobileSurface(tester);
      final workspace = TodoWorkspace(
        MemoryTodoWorkspaceStore(
          todos: [
            Todo.create(
              id: 'mobile',
              listId: 'default',
              title: 'A long title that remains readable on a narrow phone',
              tags: const ['work'],
              createdAt: DateTime(2026, 8, 1),
              updatedAt: DateTime(2026, 8, 1),
            ),
          ],
        ),
      );
      await workspace.start();

      await _pumpApp(tester, workspace, const Locale('en'));

      expect(
        find.byKey(const ValueKey('workspace-actions-menu')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mobile-search-toggle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('todo-priority-filter')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('todo-tag-filter')), findsOneWidget);
      expect(find.byKey(const ValueKey('todo-status-filter')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('todo-due-date-filter')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('todo-sort-filter')), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip('Create Todo')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('todo-priority-filter')))
            .height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.byKey(const ValueKey('workspace-actions-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Redo'), findsOneWidget);
      expect(find.text('切换到简体中文'), findsNothing);
      expect(find.text('Switch to English'), findsNothing);
    },
  );

  testWidgets('search, filter, sort and FAB panels stay inside 390x844', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          Todo.create(
            id: 'a',
            listId: 'default',
            title: 'One',
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          ),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace, const Locale('en'));

    final fab = find.byTooltip('Create Todo');
    expect(tester.getBottomLeft(fab).dy, lessThanOrEqualTo(844));
    expect(tester.getTopLeft(fab).dx, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('mobile-search-toggle')));
    await tester.pump();
    final surface = find.byKey(const ValueKey('mobile-search-surface'));
    expect(surface, findsOneWidget);
    expect(tester.getTopLeft(surface).dy, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(surface).dy, lessThanOrEqualTo(844));

    await tester.tap(find.byKey(const ValueKey('mobile-search-submit')));
    await tester.pumpAndSettle();

    for (final key in const [
      'todo-priority-filter',
      'todo-tag-filter',
      'todo-status-filter',
      'todo-due-date-filter',
      'todo-sort-filter',
    ]) {
      final control = find.byKey(ValueKey(key));
      await tester.ensureVisible(control);
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('bilingual labels cover search, filters, sort, and menus', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          Todo.create(
            id: 'a',
            listId: 'default',
            title: 'One',
            priority: TodoPriority.high,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          ),
        ],
      ),
    );
    await workspace.start();

    await _pumpApp(tester, workspace, const Locale('en'));
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Due date'), findsOneWidget);
    expect(find.text('Active, newest'), findsOneWidget);

    await _pumpApp(tester, workspace, const Locale('zh', 'CN'));
    expect(find.byTooltip('搜索'), findsOneWidget);
    expect(find.text('优先级'), findsOneWidget);
    expect(find.text('标签'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('日期'), findsWidgets);
    expect(find.text('未完成，最新'), findsOneWidget);
    expect(find.text('Active, newest'), findsNothing);
  });

  testWidgets('new Todo composer keeps Create above the keyboard', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    await _pumpApp(tester, workspace, const Locale('en'));

    await tester.tap(find.byTooltip('Create Todo'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final create = find.byKey(const ValueKey('todo-create-button'));
    expect(create, findsOneWidget);
    expect(
      tester.getBottomLeft(create).dy,
      lessThanOrEqualTo(844 - 300 + 24),
      reason: 'Create must stay reachable while the keyboard is shown',
    );
    expect(tester.getSize(create).height, greaterThanOrEqualTo(48));

    await tester.enterText(
      find.byKey(const ValueKey('todo-title-input')),
      'Created with keyboard open',
    );
    await tester.enterText(
      find.byKey(const ValueKey('todo-detail-input')),
      'Detail, 全角， tag',
    );
    await tester.enterText(
      find.byKey(const ValueKey('todo-tags-input')),
      '工作，home',
    );
    await tester.tap(create);
    await tester.pumpAndSettle();

    final created = workspace.current.todos.single;
    expect(created.title, 'Created with keyboard open');
    expect(created.detail, 'Detail, 全角， tag');
    expect(created.tags, ['工作', 'home']);
    expect(created.priority, TodoPriority.medium);
  });

  testWidgets('FAB and Create respect the bottom system inset', (tester) async {
    await _setMobileSurface(tester);
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        todos: [
          Todo.create(
            id: 'a',
            listId: 'default',
            title: 'One',
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          ),
        ],
      ),
    );
    await workspace.start();
    await _pumpApp(tester, workspace, const Locale('en'));

    final fab = find.byTooltip('Create Todo');
    expect(
      tester.getBottomLeft(fab).dy,
      lessThanOrEqualTo(844 - 34 + 1),
      reason: 'FAB must sit above the bottom system inset',
    );

    await tester.tap(fab);
    await tester.pumpAndSettle();
    final create = find.byKey(const ValueKey('todo-create-button'));
    expect(
      tester.getBottomLeft(create).dy,
      lessThanOrEqualTo(844 - 34 + 1),
      reason: 'Create must sit above the bottom system inset',
    );
  });
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

Future<void> _pumpApp(
  WidgetTester tester,
  TodoWorkspace workspace,
  Locale locale,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(
          MemorySettingsStore(AppSettings(locale: locale)),
        ),
        todoWorkspaceProvider.overrideWith((ref) async => workspace),
      ],
      child: const TodoApp(),
    ),
  );
  await tester.pumpAndSettle();
}
