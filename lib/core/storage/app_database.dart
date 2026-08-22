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

class AppDatabase {
  AppDatabase(this._executor);

  final QueryExecutor _executor;
  bool _initialized = false;

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
    await _executor.runCustom(
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
      tags: decodedTags is List
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
