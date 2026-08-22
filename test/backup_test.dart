import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aknirex_todo/core/backup/backup_service.dart';
import 'package:aknirex_todo/core/settings/settings_controller.dart';
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

  test('JSON export contains records and settings but no history', () async {
    final database = _newDatabase();
    addTearDown(database.close);
    final settings = MemorySettingsStore(
      const AppSettings(themeMode: ThemeMode.dark, locale: Locale('en')),
    );
    final todo = Todo.create(
      id: 'todo-export',
      listId: 'default',
      title: 'Export me',
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 1, 11),
    );
    await database.insertTodo(todo);
    await database.transaction(
      (executor) => executor.runCustom(
        'INSERT INTO undo_records (id, direction, payload, created_at) '
        'VALUES (?, ?, ?, ?)',
        ['undo-1', 'undo', '{}', 1],
      ),
    );

    final source =
        await BackupService(
          database: database,
          settingsStore: settings,
        ).exportJson();
    final decoded = jsonDecode(source) as Map<String, dynamic>;

    expect(decoded['version'], 1);
    expect(decoded['lists'], isNotEmpty);
    expect((decoded['todos'] as List).single['id'], 'todo-export');
    expect(decoded['settings'], {'themeMode': 'dark', 'locale': 'en'});
    expect(decoded.containsKey('undoRecords'), isFalse);
  });

  test(
    'JSON import merges records, preserves IDs, settings, and clears history',
    () async {
      final database = _newDatabase();
      addTearDown(database.close);
      final settings = MemorySettingsStore();
      await database.transaction(
        (executor) => executor.runCustom(
          'INSERT INTO undo_records (id, direction, payload, created_at) '
          'VALUES (?, ?, ?, ?)',
          ['undo-1', 'undo', '{}', 1],
        ),
      );
      final importedTodo = _todoJson('imported-todo', 'imported-list');
      final result = await BackupService(
        database: database,
        settingsStore: settings,
      ).importJson(
        jsonEncode({
          'version': 1,
          'lists': [_listJson('imported-list', 'Imported List', false)],
          'todos': [importedTodo],
          'settings': {'themeMode': 'light', 'locale': 'zh-CN'},
        }),
      );

      expect(result.insertedLists, 1);
      expect(result.insertedTodos, 1);
      expect(result.conflicts, isEmpty);
      expect(
        (await database.loadLists()).map((list) => list.id),
        contains('imported-list'),
      );
      expect(
        (await database.loadTodos()).map((todo) => todo.id),
        contains('imported-todo'),
      );
      expect(await database.undoRecordCount(), 0);
      expect(settings.value.themeMode, ThemeMode.light);
      expect(settings.value.locale, const Locale('zh', 'CN'));
    },
  );

  test('same-ID content conflicts are reported without overwriting', () async {
    final database = _newDatabase();
    addTearDown(database.close);
    final existing = Todo.create(
      id: 'same-id',
      listId: 'default',
      title: 'Current value',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    await database.insertTodo(existing);
    final result = await BackupService(
      database: database,
      settingsStore: MemorySettingsStore(),
    ).importJson(
      jsonEncode({
        'version': 1,
        'lists': [],
        'todos': [
          _todoJson('same-id', 'default', title: 'Imported value'),
          _todoJson('new-id', 'default', title: 'New value'),
        ],
        'settings': {'themeMode': 'system', 'locale': null},
      }),
    );

    expect(result.conflicts.single.recordType, 'Todo');
    expect(result.conflicts.single.id, 'same-id');
    final todos = await database.loadTodos();
    expect(
      todos.firstWhere((todo) => todo.id == 'same-id').title,
      'Current value',
    );
    expect(todos.map((todo) => todo.id), contains('new-id'));
  });

  test('settings write failure rolls back all database writes', () async {
    final database = _newDatabase();
    addTearDown(database.close);
    final settings = _FailingSettingsStore(
      const AppSettings(themeMode: ThemeMode.dark),
    );

    await expectLater(
      BackupService(database: database, settingsStore: settings).importJson(
        jsonEncode({
          'version': 1,
          'lists': [_listJson('rollback-list', 'Rollback List', false)],
          'todos': [_todoJson('rollback-todo', 'rollback-list')],
          'settings': {'themeMode': 'light', 'locale': 'en'},
        }),
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      (await database.loadLists()).map((list) => list.id),
      isNot(contains('rollback-list')),
    );
    expect(
      (await database.loadTodos()).map((todo) => todo.id),
      isNot(contains('rollback-todo')),
    );
    expect(settings.value.themeMode, ThemeMode.dark);
  });

  test('invalid references fail before any merge writes', () async {
    final database = _newDatabase();
    addTearDown(database.close);

    await expectLater(
      BackupService(
        database: database,
        settingsStore: MemorySettingsStore(),
      ).importJson(
        jsonEncode({
          'version': 1,
          'lists': [],
          'todos': [_todoJson('invalid-todo', 'missing-list')],
          'settings': {'themeMode': 'system', 'locale': null},
        }),
      ),
      throwsA(isA<BackupValidationException>()),
    );
    expect(await database.loadTodos(), isEmpty);
  });
}

AppDatabase _newDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

Map<String, Object?> _listJson(String id, String name, bool isDefault) {
  return {
    'id': id,
    'name': name,
    'isDefault': isDefault,
    'createdAt': '2026-01-01T00:00:00.000',
  };
}

Map<String, Object?> _todoJson(
  String id,
  String listId, {
  String title = 'Imported',
}) {
  return {
    'id': id,
    'listId': listId,
    'title': title,
    'detail': '',
    'priority': 'medium',
    'dueDate': null,
    'tags': <String>[],
    'completed': false,
    'createdAt': '2026-01-01T00:00:00.000',
    'updatedAt': '2026-01-01T00:00:00.000',
  };
}

class _FailingSettingsStore implements SettingsStore {
  _FailingSettingsStore(this.value);

  AppSettings value;
  bool _failNext = true;

  @override
  Future<AppSettings> load() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
    if (_failNext) {
      _failNext = false;
      throw StateError('settings write failed');
    }
  }
}
