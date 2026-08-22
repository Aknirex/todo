import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../features/workspace/todo.dart';

class WorkspaceList {
  const WorkspaceList({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  final String id;
  final String name;
  final bool isDefault;
}

class AppDatabase implements QueryExecutorUser {
  AppDatabase(this._executor);

  final QueryExecutor _executor;
  bool _initialized = false;

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}

  static Future<AppDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'aknirex-todo.sqlite'));
    final database = AppDatabase(NativeDatabase.createInBackground(file));
    await database.initialize();
    return database;
  }

  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  Future<void> initialize() async {
    if (_initialized) return;

    await _executor.ensureOpen(this);
    await _executor.runCustom('PRAGMA foreign_keys = ON');
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS lists (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS todos (
        id TEXT NOT NULL PRIMARY KEY,
        list_id TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        detail TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'medium',
        due_date TEXT,
        tags TEXT NOT NULL DEFAULT '[]',
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (list_id) REFERENCES lists (id)
      )
    ''');
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS undo_records (
        id TEXT NOT NULL PRIMARY KEY,
        direction TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await _executor.runCustom('''
      INSERT INTO lists (id, name, is_default, created_at)
      SELECT 'default', 'Default List', 1, strftime('%s', 'now') * 1000
      WHERE NOT EXISTS (SELECT 1 FROM lists WHERE is_default = 1)
    ''');
    _initialized = true;
  }

  Future<List<WorkspaceList>> loadLists() async {
    await initialize();
    final rows = await _executor.runSelect(
      'SELECT id, name, is_default FROM lists ORDER BY is_default DESC, created_at',
      const [],
    );
    return rows
        .map(
          (row) => WorkspaceList(
            id: row['id']! as String,
            name: row['name']! as String,
            isDefault: (row['is_default']! as int) == 1,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Todo>> loadTodos({String? listId}) async {
    await initialize();
    final rows = await _executor.runSelect(
      listId == null
          ? '''
            SELECT id, list_id, title, detail, priority, due_date, tags,
                   completed, created_at, updated_at
            FROM todos
            ORDER BY completed ASC, created_at DESC, id DESC
          '''
          : '''
            SELECT id, list_id, title, detail, priority, due_date, tags,
                   completed, created_at, updated_at
            FROM todos
            WHERE list_id = ?
            ORDER BY completed ASC, created_at DESC, id DESC
          ''',
      listId == null ? const [] : [listId],
    );
    return rows.map(_todoFromRow).toList(growable: false);
  }

  Future<void> insertTodo(Todo todo) async {
    await initialize();
    await _insertTodo(_executor, todo);
  }

  Future<void> _insertTodo(QueryExecutor executor, Todo todo) async {
    await executor.runCustom(
      '''
        INSERT INTO todos (
          id, list_id, title, detail, priority, due_date, tags,
          completed, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        todo.id,
        todo.listId,
        todo.title,
        todo.detail,
        todo.priority.value,
        _encodeDueDate(todo.dueDate),
        jsonEncode(todo.tags),
        todo.completed ? 1 : 0,
        todo.createdAt.microsecondsSinceEpoch,
        todo.updatedAt.microsecondsSinceEpoch,
      ],
    );
  }

  Future<void> updateTodoCompletion(
    String id,
    bool completed,
    DateTime updatedAt,
  ) async {
    await initialize();
    await _executor.runCustom(
      'UPDATE todos SET completed = ?, updated_at = ? WHERE id = ?',
      [completed ? 1 : 0, updatedAt.microsecondsSinceEpoch, id],
    );
  }

  Future<void> updateTodo(Todo todo) async {
    await initialize();
    await _replaceTodo(_executor, todo);
  }

  Future<void> deleteTodo(String id) async {
    await initialize();
    await _executor.runCustom('DELETE FROM todos WHERE id = ?', [id]);
  }

  Future<TodoCommandHistory> loadHistory() async {
    await initialize();
    final rows = await _executor.runSelect('''
        SELECT direction, payload
        FROM undo_records
        ORDER BY created_at ASC, id ASC
      ''', const []);
    final undo = <TodoCommand>[];
    final redo = <TodoCommand>[];
    for (final row in rows) {
      final command = TodoCommand.fromJson(row['payload']! as String);
      if (row['direction'] == 'undo') {
        undo.add(command);
      } else if (row['direction'] == 'redo') {
        redo.add(command);
      }
    }
    return TodoCommandHistory(
      undo: List.unmodifiable(undo),
      redo: List.unmodifiable(redo),
    );
  }

  Future<void> applyBusinessCommand(TodoCommand command) async {
    await _transaction<void>((executor) async {
      await _applyCommand(executor, command, forward: true);
      await executor.runCustom(
        "DELETE FROM undo_records WHERE direction = 'redo'",
      );
      await executor.runCustom(
        '''
        INSERT INTO undo_records (id, direction, payload, created_at)
        VALUES (?, 'undo', ?, ?)
      ''',
        [command.id, command.encoded, await _nextHistorySequence(executor)],
      );
      await _trimHistory(executor, 'undo');
    });
  }

  Future<bool> undoCommand() async {
    return _transaction<bool>((executor) async {
      final command = await _loadTopCommand(executor, 'undo');
      if (command == null) return false;
      await _applyCommand(executor, command, forward: false);
      await executor.runCustom(
        '''
          UPDATE undo_records
          SET direction = 'redo', created_at = ?
          WHERE id = ?
        ''',
        [await _nextHistorySequence(executor), command.id],
      );
      await _trimHistory(executor, 'redo');
      return true;
    });
  }

  Future<bool> redoCommand() async {
    return _transaction<bool>((executor) async {
      final command = await _loadTopCommand(executor, 'redo');
      if (command == null) return false;
      await _applyCommand(executor, command, forward: true);
      await executor.runCustom(
        '''
          UPDATE undo_records
          SET direction = 'undo', created_at = ?
          WHERE id = ?
        ''',
        [await _nextHistorySequence(executor), command.id],
      );
      await _trimHistory(executor, 'undo');
      return true;
    });
  }

  Future<void> _replaceTodo(QueryExecutor executor, Todo todo) async {
    await executor.runCustom(
      '''
        UPDATE todos
        SET list_id = ?, title = ?, detail = ?, priority = ?, due_date = ?,
            tags = ?, completed = ?, created_at = ?, updated_at = ?
        WHERE id = ?
      ''',
      [
        todo.listId,
        todo.title,
        todo.detail,
        todo.priority.value,
        _encodeDueDate(todo.dueDate),
        jsonEncode(todo.tags),
        todo.completed ? 1 : 0,
        todo.createdAt.microsecondsSinceEpoch,
        todo.updatedAt.microsecondsSinceEpoch,
        todo.id,
      ],
    );
  }

  Future<void> _applyCommand(
    QueryExecutor executor,
    TodoCommand command, {
    required bool forward,
  }) async {
    final todo = forward ? command.after : command.before;
    if (todo == null) {
      final id = (forward ? command.before : command.after)!.id;
      await executor.runCustom('DELETE FROM todos WHERE id = ?', [id]);
      return;
    }

    if ((command.type == TodoCommandType.create && forward) ||
        (command.type == TodoCommandType.delete && !forward)) {
      await _insertTodo(executor, todo);
    } else {
      await _replaceTodo(executor, todo);
    }
  }

  Future<TodoCommand?> _loadTopCommand(
    QueryExecutor executor,
    String direction,
  ) async {
    final rows = await executor.runSelect(
      '''
        SELECT payload
        FROM undo_records
        WHERE direction = ?
        ORDER BY created_at DESC, id DESC
        LIMIT 1
      ''',
      [direction],
    );
    if (rows.isEmpty) return null;
    return TodoCommand.fromJson(rows.single['payload']! as String);
  }

  Future<int> _nextHistorySequence(QueryExecutor executor) async {
    final rows = await executor.runSelect(
      'SELECT COALESCE(MAX(created_at), 0) + 1 AS next_sequence FROM undo_records',
      const [],
    );
    return (rows.single['next_sequence']! as num).toInt();
  }

  Future<void> _trimHistory(QueryExecutor executor, String direction) {
    return executor.runCustom(
      '''
        DELETE FROM undo_records
        WHERE direction = ?
          AND id NOT IN (
            SELECT id
            FROM undo_records
            WHERE direction = ?
            ORDER BY created_at DESC, id DESC
            LIMIT 50
          )
      ''',
      [direction, direction],
    );
  }

  Future<T> _transaction<T>(
    Future<T> Function(TransactionExecutor executor) action,
  ) async {
    await initialize();
    final transaction = _executor.beginTransaction();
    await transaction.ensureOpen(this);
    try {
      final result = await action(transaction);
      await transaction.send();
      return result;
    } catch (_) {
      await transaction.rollback();
      rethrow;
    }
  }

  Todo _todoFromRow(Map<String, Object?> row) {
    final tagsValue = row['tags']! as String;
    final decodedTags = jsonDecode(tagsValue);
    return Todo(
      id: row['id']! as String,
      listId: row['list_id']! as String,
      title: row['title']! as String,
      detail: row['detail']! as String,
      priority: todoPriorityFromValue(row['priority']! as String),
      dueDate: _decodeDueDate(row['due_date'] as String?),
      tags:
          decodedTags is List
              ? decodedTags.whereType<String>()
              : const <String>[],
      completed: (row['completed']! as int) == 1,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(row['created_at']! as int),
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(row['updated_at']! as int),
    );
  }

  String? _encodeDueDate(DateTime? dueDate) {
    if (dueDate == null) return null;
    return '${dueDate.year.toString().padLeft(4, '0')}-'
        '${dueDate.month.toString().padLeft(2, '0')}-'
        '${dueDate.day.toString().padLeft(2, '0')}';
  }

  DateTime? _decodeDueDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('-').map(int.parse).toList(growable: false);
    return DateTime(parts[0], parts[1], parts[2]);
  }

  Future<void> close() => _executor.close();
}
