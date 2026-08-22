import 'dart:convert';

import 'package:flutter/material.dart';

import '../settings/settings_controller.dart';
import '../storage/app_database.dart';
import '../../features/workspace/todo.dart';

class BackupConflict {
  const BackupConflict({
    required this.recordType,
    required this.id,
    required this.reason,
  });

  final String recordType;
  final String id;
  final String reason;
}

class BackupImportResult {
  const BackupImportResult({
    required this.insertedLists,
    required this.insertedTodos,
    required this.conflicts,
  });

  final int insertedLists;
  final int insertedTodos;
  final List<BackupConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
}

class BackupValidationException implements Exception {
  const BackupValidationException(this.message);

  final String message;

  @override
  String toString() => 'BackupValidationException: $message';
}

class BackupService {
  const BackupService({required this.database, required this.settingsStore});

  final AppDatabase database;
  final SettingsStore settingsStore;

  Future<String> exportJson() async {
    final lists = await database.loadLists();
    final todos = await database.loadTodos();
    final settings = await settingsStore.load();
    return jsonEncode({
      'version': 1,
      'lists': lists.map(_listToJson).toList(growable: false),
      'todos': todos.map(_todoToJson).toList(growable: false),
      'settings': _settingsToJson(settings),
    });
  }

  Future<BackupImportResult> importJson(String source) async {
    final document = _BackupDocument.parse(source);
    final existingLists = await database.loadLists();
    final existingTodos = await database.loadTodos();
    final existingListsById = {for (final list in existingLists) list.id: list};
    final existingTodosById = {for (final todo in existingTodos) todo.id: todo};

    final conflicts = <BackupConflict>[];
    final listsToInsert = <WorkspaceList>[];
    for (final list in document.lists) {
      final existing = existingListsById[list.id];
      if (existing == null) {
        listsToInsert.add(list);
      } else if (!_sameList(existing, list)) {
        conflicts.add(
          BackupConflict(
            recordType: 'List',
            id: list.id,
            reason: 'The existing List has different content.',
          ),
        );
      }
    }

    final conflictingListIds =
        conflicts
            .where((conflict) => conflict.recordType == 'List')
            .map((conflict) => conflict.id)
            .toSet();
    final todosToInsert = <Todo>[];
    for (final todo in document.todos) {
      final existing = existingTodosById[todo.id];
      if (existing != null) {
        if (!_sameTodo(existing, todo)) {
          conflicts.add(
            BackupConflict(
              recordType: 'Todo',
              id: todo.id,
              reason: 'The existing Todo has different content.',
            ),
          );
        }
      } else if (conflictingListIds.contains(todo.listId)) {
        conflicts.add(
          BackupConflict(
            recordType: 'Todo',
            id: todo.id,
            reason: 'Its referenced List has a content conflict.',
          ),
        );
      } else {
        todosToInsert.add(todo);
      }
    }

    final knownListIds = {...existingListsById.keys, ...document.listIds};
    for (final todo in todosToInsert) {
      if (!knownListIds.contains(todo.listId)) {
        throw const BackupValidationException(
          'Every Todo must reference an existing or imported List.',
        );
      }
    }

    final previousSettings = await settingsStore.load();
    try {
      await database.transaction((executor) async {
        for (final list in listsToInsert) {
          await database.insertList(list, executor: executor);
        }
        for (final todo in todosToInsert) {
          await database.insertTodo(todo, executor: executor);
        }
        await database.clearUndoHistory(executor: executor);
        await settingsStore.save(document.settings);
      });
    } catch (_) {
      // SharedPreferences is not part of SQLite's transaction, so restore it
      // if a transaction or settings write fails after it changed.
      try {
        await settingsStore.save(previousSettings);
      } catch (_) {
        // Preserve the original import failure.
      }
      rethrow;
    }

    return BackupImportResult(
      insertedLists: listsToInsert.length,
      insertedTodos: todosToInsert.length,
      conflicts: List.unmodifiable(conflicts),
    );
  }
}

Map<String, Object?> _listToJson(WorkspaceList list) {
  return {'id': list.id, 'name': list.name, 'isDefault': list.isDefault};
}

Map<String, Object?> _todoToJson(Todo todo) {
  return {
    'id': todo.id,
    'listId': todo.listId,
    'title': todo.title,
    'detail': todo.detail,
    'priority': todo.priority.value,
    'dueDate': todo.dueDate == null ? null : _dateOnlyToString(todo.dueDate!),
    'tags': todo.tags,
    'completed': todo.completed,
    'createdAt': todo.createdAt.toIso8601String(),
    'updatedAt': todo.updatedAt.toIso8601String(),
  };
}

Map<String, Object?> _settingsToJson(AppSettings settings) {
  return {
    'themeMode': switch (settings.themeMode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    },
    'locale':
        settings.locale == null
            ? null
            : settings.locale!.languageCode == 'en'
            ? 'en'
            : 'zh-CN',
  };
}

bool _sameList(WorkspaceList first, WorkspaceList second) {
  return first.id == second.id &&
      first.name == second.name &&
      first.isDefault == second.isDefault;
}

bool _sameTodo(Todo first, Todo second) {
  if (first.id != second.id ||
      first.listId != second.listId ||
      first.title != second.title ||
      first.detail != second.detail ||
      first.priority != second.priority ||
      first.dueDate != second.dueDate ||
      first.completed != second.completed ||
      first.createdAt != second.createdAt ||
      first.updatedAt != second.updatedAt ||
      first.tags.length != second.tags.length) {
    return false;
  }
  for (var index = 0; index < first.tags.length; index++) {
    if (first.tags[index] != second.tags[index]) return false;
  }
  return true;
}

String _dateOnlyToString(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _BackupDocument {
  const _BackupDocument({
    required this.lists,
    required this.todos,
    required this.settings,
  });

  final List<WorkspaceList> lists;
  final List<Todo> todos;
  final AppSettings settings;

  Iterable<String> get listIds => lists.map((list) => list.id);

  static _BackupDocument parse(String source) {
    final decoded = _decodeMap(source);
    if (decoded['version'] != 1) {
      throw const BackupValidationException('Unsupported backup version.');
    }
    final rawLists = _listValue(decoded, 'lists');
    final rawTodos = _listValue(decoded, 'todos');
    final rawSettings = _mapValue(decoded, 'settings');
    final lists = <WorkspaceList>[];
    final listIds = <String>{};
    for (final value in rawLists) {
      final map = _recordMap(value, 'List');
      final id = _requiredString(map, 'id');
      if (!listIds.add(id)) {
        throw BackupValidationException('Duplicate List id: $id.');
      }
      lists.add(
        WorkspaceList(
          id: id,
          name: _requiredString(map, 'name'),
          isDefault: _requiredBool(map, 'isDefault'),
          createdAt:
              map['createdAt'] == null
                  ? DateTime.now()
                  : _requiredDateTime(map, 'createdAt'),
        ),
      );
    }

    final todos = <Todo>[];
    final todoIds = <String>{};
    for (final value in rawTodos) {
      final map = _recordMap(value, 'Todo');
      final id = _requiredString(map, 'id');
      if (!todoIds.add(id)) {
        throw BackupValidationException('Duplicate Todo id: $id.');
      }
      final rawTags = _listValue(map, 'tags');
      if (rawTags.any((tag) => tag is! String)) {
        throw const BackupValidationException('Todo tags must be strings.');
      }
      final priority = _requiredString(map, 'priority');
      if (!TodoPriority.values.any((value) => value.value == priority)) {
        throw BackupValidationException(
          'Unsupported Todo priority: $priority.',
        );
      }
      final dueDate = map['dueDate'];
      if (dueDate != null && (dueDate is! String || !_isDateOnly(dueDate))) {
        throw const BackupValidationException(
          'Todo dueDate must be YYYY-MM-DD or null.',
        );
      }
      todos.add(
        Todo(
          id: id,
          listId: _requiredString(map, 'listId'),
          title: _stringValue(map, 'title'),
          detail: _stringValue(map, 'detail'),
          priority: todoPriorityFromValue(priority),
          dueDate: dueDate == null ? null : _parseDateOnly(dueDate as String),
          tags: rawTags.cast<String>(),
          completed: _requiredBool(map, 'completed'),
          createdAt: _requiredDateTime(map, 'createdAt'),
          updatedAt: _requiredDateTime(map, 'updatedAt'),
        ),
      );
    }

    return _BackupDocument(
      lists: List.unmodifiable(lists),
      todos: List.unmodifiable(todos),
      settings: _parseSettings(rawSettings),
    );
  }
}

Map<String, Object?> _decodeMap(String source) {
  try {
    final value = jsonDecode(source);
    return _mapValue({'root': value}, 'root');
  } on BackupValidationException {
    rethrow;
  } catch (_) {
    throw const BackupValidationException('Backup must be valid JSON.');
  }
}

Map<String, Object?> _recordMap(Object? value, String type) {
  if (value is Map) return value.cast<String, Object?>();
  throw BackupValidationException('$type records must be JSON objects.');
}

Map<String, Object?> _mapValue(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is Map) return value.cast<String, Object?>();
  throw BackupValidationException('$key must be a JSON object.');
}

List<Object?> _listValue(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is List) return value.cast<Object?>();
  throw BackupValidationException('$key must be a JSON array.');
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  throw BackupValidationException('$key must be a non-empty string.');
}

String _stringValue(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw BackupValidationException('$key must be a string.');
}

bool _requiredBool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is bool) return value;
  throw BackupValidationException('$key must be a boolean.');
}

DateTime _requiredDateTime(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      // Fall through to the shared validation message.
    }
  }
  throw BackupValidationException('$key must be an ISO-8601 date.');
}

AppSettings _parseSettings(Map<String, Object?> map) {
  final theme = map['themeMode'];
  final themeMode = switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => throw const BackupValidationException('Unsupported themeMode.'),
  };
  final localeValue = map['locale'];
  final locale = switch (localeValue) {
    null => null,
    'en' => const Locale('en'),
    'zh-CN' => const Locale('zh', 'CN'),
    _ => throw const BackupValidationException('Unsupported locale.'),
  };
  return AppSettings(themeMode: themeMode, locale: locale);
}

bool _isDateOnly(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  try {
    _parseDateOnly(value);
    return true;
  } catch (_) {
    return false;
  }
}

DateTime _parseDateOnly(String value) {
  final parts = value.split('-').map(int.parse).toList(growable: false);
  final date = DateTime(parts[0], parts[1], parts[2]);
  if (date.year != parts[0] || date.month != parts[1] || date.day != parts[2]) {
    throw const FormatException('Invalid calendar date.');
  }
  return date;
}
