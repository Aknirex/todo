import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aknirex_todo/core/storage/app_database.dart';
import 'package:aknirex_todo/features/workspace/todo.dart';

void main() {
  setUpAll(() {
    if (Platform.isWindows) {
      open.overrideFor(
        OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'),
      );
    }
  });

  test('in-memory Drift database initializes the workspace schema', () async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    final lists = await database.loadLists();

    expect(lists, hasLength(1));
    expect(lists.single.id, 'default');
    expect(lists.single.isDefault, isTrue);
  });

  test(
    'Drift persists all Todo fields and returns active Todos first',
    () async {
      final database = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(database.close);

      final older = Todo.create(
        id: 'older',
        listId: 'default',
        title: 'Older',
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 1, 10),
      );
      final completed = Todo.create(
        id: 'completed',
        listId: 'default',
        title: 'Completed',
        completed: true,
        createdAt: DateTime(2026, 1, 2, 10),
        updatedAt: DateTime(2026, 1, 2, 10),
      );
      final full = Todo.create(
        id: 'full',
        listId: 'default',
        title: 'Plan release',
        detail: 'Write the notes',
        priority: TodoPriority.high,
        dueDate: DateTime(2026, 2, 3, 17),
        tags: const ['work', 'release', 'work'],
        createdAt: DateTime(2026, 1, 3, 10),
        updatedAt: DateTime(2026, 1, 3, 11),
      );

      await database.insertTodo(older);
      await database.insertTodo(completed);
      await database.insertTodo(full);

      final todos = await database.loadTodos(listId: 'default');

      expect(todos.map((todo) => todo.id).toList(growable: false), [
        'full',
        'older',
        'completed',
      ]);
      expect(todos.first.title, 'Plan release');
      expect(todos.first.detail, 'Write the notes');
      expect(todos.first.priority, TodoPriority.high);
      expect(todos.first.dueDate, DateTime(2026, 2, 3));
      expect(todos.first.tags, ['work', 'release']);
      expect(todos.first.completed, isFalse);
      expect(todos.first.createdAt, full.createdAt);
      expect(todos.first.updatedAt, full.updatedAt);
    },
  );

  test('Drift persists a completion toggle', () async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final todo = Todo.create(id: 'toggle', listId: 'default');

    await database.insertTodo(todo);
    await database.updateTodoCompletion(todo.id, true, DateTime(2026, 1, 4));

    final saved = (await database.loadTodos()).single;
    expect(saved.completed, isTrue);
    expect(saved.updatedAt, DateTime(2026, 1, 4));
  });

  test('Drift updates editable Todo fields while preserving completion', () async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final todo = Todo.create(
      id: 'edit',
      listId: 'default',
      completed: true,
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 1, 10),
    );

    await database.insertTodo(todo);
    await database.updateTodo(
      todo.copyWith(
        title: 'Updated title',
        detail: 'Updated detail',
        priority: TodoPriority.low,
        dueDate: DateTime.utc(2026, 4, 5, 22),
        tags: const [' work ', '', 'work', 'home'],
        updatedAt: DateTime(2026, 1, 2, 12),
      ),
    );

    final saved = (await database.loadTodos()).single;
    expect(saved.title, 'Updated title');
    expect(saved.detail, 'Updated detail');
    expect(saved.priority, TodoPriority.low);
    expect(saved.dueDate, DateTime(2026, 4, 5));
    expect(saved.dueDate!.isUtc, isFalse);
    expect(saved.tags, ['work', 'home']);
    expect(saved.completed, isTrue);
    expect(saved.createdAt, todo.createdAt);
    expect(saved.updatedAt, DateTime(2026, 1, 2, 12));
  });
}
