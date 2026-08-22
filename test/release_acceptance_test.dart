import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/open.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/core/storage/app_database.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/providers.dart';

void main() {
  setUpAll(() {
    if (Platform.isWindows) {
      open.overrideFor(
        OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'),
      );
    }
  });

  testWidgets(
    'blank Todo remains visible after clearing an empty-result query',
    (tester) async {
      final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
      await workspace.start();
      await _pumpApp(tester, workspace);

      await tester.tap(find.byTooltip('Create Todo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('todo-create-button')));
      await tester.pumpAndSettle();

      final blank = workspace.current.todos.single;
      final rowKey = ValueKey('todo-delete-${blank.id}');
      expect(find.byKey(rowKey), findsOneWidget);

      final search = find.byKey(const ValueKey('todo-search-input'));
      await tester.enterText(search, 'missing');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('todo-empty-results')), findsOneWidget);

      await tester.enterText(search, '');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('todo-empty-results')), findsNothing);
      expect(find.byKey(rowKey), findsOneWidget);
    },
  );

  test(
    'Drift workspace restart preserves the default List, Todo, and history',
    () async {
      final directory = await Directory.systemTemp.createTemp('aknirex-todo-');
      final file = File(
        '${directory.path}${Platform.pathSeparator}acceptance.sqlite',
      );

      final firstDatabase = AppDatabase(
        DatabaseConnection(
          NativeDatabase(file),
          closeStreamsSynchronously: true,
        ),
      );
      final firstWorkspace = TodoWorkspace(
        DriftTodoWorkspaceStore(firstDatabase),
      );
      await firstWorkspace.start();
      final created = await firstWorkspace.createTodo();
      await firstWorkspace.updateTodo(
        created.copyWith(title: 'Persisted acceptance Todo'),
      );
      await firstWorkspace.toggleTodo(created.id);
      await firstDatabase.close();

      final secondDatabase = AppDatabase(
        DatabaseConnection(
          NativeDatabase(file),
          closeStreamsSynchronously: true,
        ),
      );
      try {
        final restarted = TodoWorkspace(
          DriftTodoWorkspaceStore(secondDatabase),
        );
        await restarted.start();

        expect(restarted.current.lists, hasLength(1));
        expect(restarted.current.lists.single.id, 'default');
        expect(restarted.current.todos, hasLength(1));
        expect(
          restarted.current.todos.single.title,
          'Persisted acceptance Todo',
        );
        expect(restarted.current.todos.single.completed, isTrue);
        expect(restarted.canUndo, isTrue);
        expect(restarted.canRedo, isFalse);

        await restarted.undo();
        expect(restarted.current.todos.single.completed, isFalse);
        expect(restarted.canRedo, isTrue);
        await restarted.redo();
        expect(restarted.current.todos.single.completed, isTrue);
      } finally {
        await secondDatabase.close();
        await directory.delete(recursive: true);
      }
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
