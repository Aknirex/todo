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

  test(
    'a new business command clears Redo and history is capped at 50',
    () async {
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
    },
  );

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

    await tester.tap(find.byKey(const ValueKey('redo-button')));
    await tester.pumpAndSettle();
    expect(find.text('After detail'), findsOneWidget);

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
