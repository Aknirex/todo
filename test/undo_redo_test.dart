import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/open.dart';

import 'package:aknirex_todo/app.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
import 'package:aknirex_todo/core/storage/app_database.dart';
import 'package:aknirex_todo/features/workspace/todo.dart';
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

  test('workspace applies and reverses every Todo business command', () async {
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();

    final created = await workspace.createTodo(title: 'Before');
    await workspace.updateTodo(created.copyWith(title: 'After'));
    await workspace.toggleTodo(created.id);
    expect(workspace.current.todos.single.completed, isTrue);

    await workspace.deleteTodo(created.id);
    expect(workspace.current.todos, isEmpty);

    await workspace.undo();
    expect(workspace.current.todos.single.completed, isTrue);
    await workspace.undo();
    expect(workspace.current.todos.single.completed, isFalse);
    await workspace.undo();
    expect(workspace.current.todos.single.title, 'Before');
    await workspace.undo();
    expect(workspace.current.todos, isEmpty);
    expect(workspace.canUndo, isFalse);

    await workspace.redo();
    await workspace.redo();
    await workspace.redo();
    expect(workspace.current.todos.single.title, 'After');
    expect(workspace.current.todos.single.completed, isTrue);
    await workspace.redo();
    expect(workspace.current.todos, isEmpty);
    expect(workspace.canRedo, isFalse);
  });

  test('a new business command clears Redo', () async {
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();

    await workspace.createTodo(title: 'first');
    await workspace.undo();
    expect(workspace.canRedo, isTrue);
    await workspace.createTodo(title: 'second');
    expect(workspace.canRedo, isFalse);

    for (var index = 0; index < 50; index++) {
      await workspace.createTodo(title: 'Todo $index');
    }
    for (var index = 0; index < 50; index++) {
      await workspace.undo();
    }
    expect(workspace.current.todos.map((todo) => todo.title), ['second']);
    expect(workspace.canUndo, isFalse);
    for (var index = 0; index < 50; index++) {
      await workspace.redo();
    }
    expect(workspace.canRedo, isFalse);
  });

  test('Undo and Redo each retain at most 50 commands', () async {
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();

    for (var index = 0; index < 51; index++) {
      await workspace.createTodo(title: 'Todo $index');
    }
    for (var index = 0; index < 50; index++) {
      await workspace.undo();
    }

    expect(workspace.current.todos.map((todo) => todo.title), ['Todo 0']);
    expect(workspace.canUndo, isFalse);
    expect(workspace.canRedo, isTrue);

    for (var index = 0; index < 50; index++) {
      await workspace.redo();
    }
    expect(workspace.current.todos, hasLength(51));
    expect(workspace.canRedo, isFalse);
  });

  test('Drift persists commands and stack direction across restart', () async {
    final directory = await Directory.systemTemp.createTemp('aknirex-todo-');
    final file = File('${directory.path}${Platform.pathSeparator}test.sqlite');
    final first = AppDatabase(
      DatabaseConnection(NativeDatabase(file), closeStreamsSynchronously: true),
    );
    final todo = Todo.create(
      id: 'persisted',
      listId: 'default',
      title: 'Persist me',
      createdAt: DateTime(2026, 8, 22),
      updatedAt: DateTime(2026, 8, 22),
    );
    await first.applyBusinessCommand(TodoCommand.create(todo));
    await first.close();

    final second = AppDatabase(
      DatabaseConnection(NativeDatabase(file), closeStreamsSynchronously: true),
    );
    addTearDown(() async {
      await second.close();
      await directory.delete(recursive: true);
    });

    final history = await second.loadHistory();
    expect(history.undo, hasLength(1));
    expect(await second.undoCommand(), isTrue);
    expect(await second.loadTodos(), isEmpty);
    expect((await second.loadHistory()).redo, hasLength(1));
    expect(await second.redoCommand(), isTrue);
    expect((await second.loadTodos()).single.title, 'Persist me');
    await second.applyBusinessCommand(TodoCommand.delete(todo));
    expect(await second.loadTodos(), isEmpty);
    expect(await second.undoCommand(), isTrue);
    expect((await second.loadTodos()).single.title, 'Persist me');
    expect(await second.undoCommand(), isTrue);
    expect(await second.loadTodos(), isEmpty);
    expect(await second.redoCommand(), isTrue);
    expect((await second.loadTodos()).single.title, 'Persist me');
    expect(await second.redoCommand(), isTrue);
    expect(await second.loadTodos(), isEmpty);
  });

  test(
    'Drift orders history by execution sequence, including delete',
    () async {
      final database = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(database.close);
      final first = Todo.create(
        id: 'first',
        listId: 'default',
        title: 'First',
        createdAt: DateTime(2026, 12, 1),
        updatedAt: DateTime(2026, 12, 1),
      );
      final second = Todo.create(
        id: 'second',
        listId: 'default',
        title: 'Second',
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2020, 1, 1),
      );

      await database.applyBusinessCommand(TodoCommand.create(first));
      await database.applyBusinessCommand(TodoCommand.delete(first));
      await database.applyBusinessCommand(TodoCommand.create(second));

      expect(await database.undoCommand(), isTrue);
      expect(await database.loadTodos(), isEmpty);
      expect(await database.undoCommand(), isTrue);
      expect((await database.loadTodos()).single.id, 'first');
    },
  );

  test('Drift rolls back Todo and history when a command fails', () async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final before = Todo.create(
      id: 'rollback',
      listId: 'default',
      title: 'Before',
    );
    final after = before.copyWith(title: 'After');
    final command = TodoCommand(
      id: 'rollback-command',
      type: TodoCommandType.update,
      before: before,
      after: after,
      createdAt: after.updatedAt,
    );
    await database.insertTodo(before);
    await database.applyBusinessCommand(command);

    final failing = TodoCommand(
      id: command.id,
      type: TodoCommandType.update,
      before: after,
      after: after.copyWith(title: 'Failed'),
      createdAt: DateTime.now(),
    );
    await expectLater(
      database.applyBusinessCommand(failing),
      throwsA(anything),
    );

    expect((await database.loadTodos()).single.title, 'After');
    final history = await database.loadHistory();
    expect(history.undo, hasLength(1));
    expect(history.undo.single.id, command.id);
  });

  testWidgets('home exposes disabled history and direct deletion', (
    tester,
  ) async {
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    final todo = await workspace.createTodo(title: 'Delete me');
    await workspace.read();
    await _pumpApp(tester, workspace);

    final undo = tester.widget<IconButton>(
      find.byKey(const ValueKey('undo-button')),
    );
    final redo = tester.widget<IconButton>(
      find.byKey(const ValueKey('redo-button')),
    );
    expect(undo.onPressed, isNotNull);
    expect(redo.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('undo-button')));
    await tester.pumpAndSettle();
    expect(find.text('Delete me'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('redo-button')));
    await tester.pumpAndSettle();
    expect(find.text('Delete me'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('todo-delete-${todo.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Delete me'), findsNothing);
  });

  testWidgets('detail exposes history controls and direct deletion', (
    tester,
  ) async {
    final workspace = TodoWorkspace(MemoryTodoWorkspaceStore());
    await workspace.start();
    final todo = await workspace.createTodo(title: 'Before detail');
    await workspace.updateTodo(todo.copyWith(title: 'After detail'));
    await _pumpApp(tester, workspace);

    await tester.tap(find.text('After detail'));
    await tester.pumpAndSettle();

    final undo = tester.widget<IconButton>(
      find.byKey(const ValueKey('undo-button')),
    );
    final redo = tester.widget<IconButton>(
      find.byKey(const ValueKey('redo-button')),
    );
    expect(undo.onPressed, isNotNull);
    expect(redo.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('undo-button')));
    await tester.pumpAndSettle();
    expect(find.text('Before detail'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(workspace.current.todos.single.title, 'Before detail');

    await tester.tap(find.text('Before detail'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('redo-button')));
    await tester.pumpAndSettle();
    expect(find.text('After detail'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(workspace.current.todos.single.title, 'After detail');

    await tester.tap(find.text('After detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('todo-detail-delete-button')));
    await tester.pumpAndSettle();
    expect(workspace.current.todos, isEmpty);
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
