import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/features/workspace/todo.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  testWidgets('compact workspace keeps actions and controls reachable', (
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

    expect(
      find.byKey(const ValueKey('workspace-actions-menu')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byTooltip('Create Todo')).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('todo-priority-filter'))).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byKey(const ValueKey('workspace-actions-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Redo'), findsOneWidget);
    expect(find.text('切换到简体中文'), findsNothing);
  });
}
