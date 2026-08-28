import 'dart:convert';

import 'package:characters/characters.dart';

enum TodoPriority { high, medium, low }

extension TodoPriorityValue on TodoPriority {
  String get value => name;
}

TodoPriority todoPriorityFromValue(String value) {
  return TodoPriority.values.firstWhere(
    (priority) => priority.value == value,
    orElse: () => TodoPriority.medium,
  );
}

class Todo {
  Todo({
    required this.id,
    required this.listId,
    this.title = '',
    this.detail = '',
    this.priority = TodoPriority.medium,
    DateTime? dueDate,
    Iterable<String> tags = const <String>[],
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
  }) : dueDate = _dateOnly(dueDate),
       tags = List.unmodifiable(normalizeTodoTags(tags));

  factory Todo.create({
    required String id,
    required String listId,
    String title = '',
    String detail = '',
    TodoPriority priority = TodoPriority.medium,
    DateTime? dueDate,
    Iterable<String> tags = const <String>[],
    bool completed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return Todo(
      id: id,
      listId: listId,
      title: title,
      detail: detail,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      completed: completed,
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
  }

  final String id;
  final String listId;
  final String title;
  final String detail;
  final TodoPriority priority;
  final DateTime? dueDate;
  final List<String> tags;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayText {
    if (title.trim().isNotEmpty) return title;
    final summary = detail.trim();
    if (summary.isEmpty) return ' ';
    final characters = summary.characters;
    if (characters.length <= 50) return summary;
    return '${characters.take(50)}…';
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'listId': listId,
      'title': title,
      'detail': detail,
      'priority': priority.value,
      'dueDate':
          dueDate == null
              ? null
              : '${dueDate!.year.toString().padLeft(4, '0')}-'
                  '${dueDate!.month.toString().padLeft(2, '0')}-'
                  '${dueDate!.day.toString().padLeft(2, '0')}',
      'tags': tags,
      'completed': completed,
      'createdAt': createdAt.microsecondsSinceEpoch,
      'updatedAt': updatedAt.microsecondsSinceEpoch,
    };
  }

  factory Todo.fromJson(Map<String, Object?> json) {
    final tags = json['tags'];
    return Todo(
      id: json['id']! as String,
      listId: json['listId']! as String,
      title: json['title']! as String,
      detail: json['detail']! as String,
      priority: todoPriorityFromValue(json['priority']! as String),
      dueDate: _parseDueDate(json['dueDate'] as String?),
      tags: tags is List ? tags.whereType<String>() : const <String>[],
      completed: json['completed']! as bool,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        (json['createdAt']! as num).toInt(),
      ),
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(
        (json['updatedAt']! as num).toInt(),
      ),
    );
  }

  Todo copyWith({
    String? title,
    String? detail,
    TodoPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    Iterable<String>? tags,
    bool? completed,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id,
      listId: listId,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum TodoCommandType { create, update, complete, delete }

class TodoCommand {
  const TodoCommand({
    required this.id,
    required this.type,
    required this.before,
    required this.after,
    required this.createdAt,
  });

  factory TodoCommand.create(Todo todo) {
    return TodoCommand(
      id: _commandId(todo.id, TodoCommandType.create),
      type: TodoCommandType.create,
      before: null,
      after: todo,
      createdAt: todo.updatedAt,
    );
  }

  factory TodoCommand.update({required Todo before, required Todo after}) {
    return TodoCommand(
      id: _commandId(after.id, TodoCommandType.update),
      type: TodoCommandType.update,
      before: before,
      after: after,
      createdAt: after.updatedAt,
    );
  }

  factory TodoCommand.complete({required Todo before, required Todo after}) {
    return TodoCommand(
      id: _commandId(after.id, TodoCommandType.complete),
      type: TodoCommandType.complete,
      before: before,
      after: after,
      createdAt: after.updatedAt,
    );
  }

  factory TodoCommand.delete(Todo todo) {
    return TodoCommand(
      id: _commandId(todo.id, TodoCommandType.delete),
      type: TodoCommandType.delete,
      before: todo,
      after: null,
      createdAt: todo.updatedAt,
    );
  }

  factory TodoCommand.fromJson(String encoded) {
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final type = TodoCommandType.values.firstWhere(
      (value) => value.name == json['type'],
    );
    final before = json['before'];
    final after = json['after'];
    return TodoCommand(
      id: json['id']! as String,
      type: type,
      before:
          before is Map
              ? Todo.fromJson(Map<String, Object?>.from(before))
              : null,
      after:
          after is Map ? Todo.fromJson(Map<String, Object?>.from(after)) : null,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        (json['createdAt']! as num).toInt(),
      ),
    );
  }

  final String id;
  final TodoCommandType type;
  final Todo? before;
  final Todo? after;
  final DateTime createdAt;

  String get encoded => jsonEncode({
    'id': id,
    'type': type.name,
    'before': before?.toJson(),
    'after': after?.toJson(),
    'createdAt': createdAt.microsecondsSinceEpoch,
  });
}

class TodoCommandHistory {
  const TodoCommandHistory({required this.undo, required this.redo});

  final List<TodoCommand> undo;
  final List<TodoCommand> redo;

  bool get canUndo => undo.isNotEmpty;
  bool get canRedo => redo.isNotEmpty;
}

DateTime? _dateOnly(DateTime? date) {
  if (date == null) return null;
  return DateTime(date.year, date.month, date.day);
}

DateTime? _parseDueDate(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-').map(int.parse).toList(growable: false);
  return DateTime(parts[0], parts[1], parts[2]);
}

int _commandSequence = 0;

String _commandId(String todoId, TodoCommandType type) {
  return '$todoId-${type.name}-${DateTime.now().microsecondsSinceEpoch}-'
      '${_commandSequence++}';
}

List<String> normalizeTodoTags(Iterable<String> tags) {
  final result = <String>[];
  for (final tag in tags) {
    final normalized = tag.trim();
    if (normalized.isNotEmpty && !result.contains(normalized)) {
      result.add(normalized);
    }
  }
  return result;
}
