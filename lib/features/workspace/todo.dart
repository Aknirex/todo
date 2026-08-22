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

DateTime? _dateOnly(DateTime? date) {
  if (date == null) return null;
  return DateTime(date.year, date.month, date.day);
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
