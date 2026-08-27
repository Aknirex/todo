import 'todo.dart';

enum TodoDueDateFilter { today, thisWeek, thisMonth, overdue, noDueDate }

enum TodoSort {
  activeNewest,
  priority,
  dueDate,
  titleAscending,
  titleDescending,
}

class TodoQuery {
  const TodoQuery({
    this.search = '',
    this.priorities = const <TodoPriority>{},
    this.tags = const <String>{},
    this.completed,
    this.dueDateFilters = const <TodoDueDateFilter>{},
    this.sort = TodoSort.activeNewest,
  });

  final String search;
  final Set<TodoPriority> priorities;
  final Set<String> tags;
  final bool? completed;
  final Set<TodoDueDateFilter> dueDateFilters;
  final TodoSort sort;

  TodoQuery copyWith({
    String? search,
    Set<TodoPriority>? priorities,
    Set<String>? tags,
    bool? completed,
    bool clearCompleted = false,
    Set<TodoDueDateFilter>? dueDateFilters,
    TodoSort? sort,
  }) {
    return TodoQuery(
      search: search ?? this.search,
      priorities: priorities ?? this.priorities,
      tags: tags ?? this.tags,
      completed: clearCompleted ? null : completed ?? this.completed,
      dueDateFilters: dueDateFilters ?? this.dueDateFilters,
      sort: sort ?? this.sort,
    );
  }
}

class TodoMatch {
  const TodoMatch({required this.todo, required this.titleRanges});

  final Todo todo;
  final List<TodoTextRange> titleRanges;

  bool get titleMatches => titleRanges.isNotEmpty;
}

class TodoTextRange {
  const TodoTextRange(this.start, this.end);

  final int start;
  final int end;
}

class TodoQueryResult {
  const TodoQueryResult(this.matches);

  final List<TodoMatch> matches;

  List<Todo> get todos =>
      matches.map((match) => match.todo).toList(growable: false);
}

class TodoQueryEngine {
  const TodoQueryEngine._();

  static TodoQueryResult apply(
    Iterable<Todo> source,
    TodoQuery query, {
    DateTime? now,
  }) {
    final localNow = now ?? DateTime.now();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final search = query.search.trim().toLowerCase();
    final matches = <TodoMatch>[];

    for (final todo in source) {
      if (!_matchesFilters(todo, query, today)) continue;

      final titleRanges = _findRanges(todo.title, search);
      if (search.isNotEmpty &&
          titleRanges.isEmpty &&
          !_contains(todo.detail, search) &&
          !todo.tags.any((tag) => _contains(tag, search))) {
        continue;
      }
      matches.add(TodoMatch(todo: todo, titleRanges: titleRanges));
    }

    matches.sort((first, second) {
      if (search.isNotEmpty && first.titleMatches != second.titleMatches) {
        return first.titleMatches ? -1 : 1;
      }
      final result = _compare(first.todo, second.todo, query.sort);
      return result != 0 ? result : second.todo.id.compareTo(first.todo.id);
    });
    return TodoQueryResult(List.unmodifiable(matches));
  }

  static bool _matchesFilters(Todo todo, TodoQuery query, DateTime today) {
    if (query.priorities.isNotEmpty &&
        !query.priorities.contains(todo.priority)) {
      return false;
    }
    if (query.tags.isNotEmpty && !todo.tags.any(query.tags.contains)) {
      return false;
    }
    if (query.completed != null && todo.completed != query.completed) {
      return false;
    }
    if (query.dueDateFilters.isNotEmpty &&
        !_matchesDueDate(todo.dueDate, query.dueDateFilters, today)) {
      return false;
    }
    return true;
  }

  static bool _matchesDueDate(
    DateTime? dueDate,
    Set<TodoDueDateFilter> filters,
    DateTime today,
  ) {
    if (filters.contains(TodoDueDateFilter.noDueDate) && dueDate == null) {
      return true;
    }
    if (dueDate == null) return false;

    final date = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (filters.contains(TodoDueDateFilter.today) && date == today) {
      return true;
    }
    if (filters.contains(TodoDueDateFilter.overdue) && date.isBefore(today)) {
      return true;
    }

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final nextWeek = weekStart.add(const Duration(days: 7));
    if (filters.contains(TodoDueDateFilter.thisWeek) &&
        !date.isBefore(weekStart) &&
        date.isBefore(nextWeek)) {
      return true;
    }

    final monthStart = DateTime(today.year, today.month);
    final nextMonth = DateTime(today.year, today.month + 1);
    return filters.contains(TodoDueDateFilter.thisMonth) &&
        !date.isBefore(monthStart) &&
        date.isBefore(nextMonth);
  }

  static int _compare(Todo first, Todo second, TodoSort sort) {
    switch (sort) {
      case TodoSort.activeNewest:
        return _compareActiveNewest(first, second);
      case TodoSort.priority:
        final priority = _priorityRank(
          first.priority,
        ).compareTo(_priorityRank(second.priority));
        return priority != 0 ? priority : _compareActiveNewest(first, second);
      case TodoSort.dueDate:
        final firstDate = first.dueDate;
        final secondDate = second.dueDate;
        if (firstDate == null && secondDate != null) return 1;
        if (firstDate != null && secondDate == null) return -1;
        if (firstDate != null && secondDate != null) {
          final result = firstDate.compareTo(secondDate);
          if (result != 0) return result;
        }
        return _compareActiveNewest(first, second);
      case TodoSort.titleAscending:
        return _compareTitle(first, second, descending: false);
      case TodoSort.titleDescending:
        return _compareTitle(first, second, descending: true);
    }
  }

  static int _compareActiveNewest(Todo first, Todo second) {
    if (first.completed != second.completed) return first.completed ? 1 : -1;
    final created = second.createdAt.compareTo(first.createdAt);
    return created != 0 ? created : 0;
  }

  static int _compareTitle(
    Todo first,
    Todo second, {
    required bool descending,
  }) {
    final firstTitle = first.displayText.trim().toLowerCase();
    final secondTitle = second.displayText.trim().toLowerCase();
    var result = firstTitle.compareTo(secondTitle);
    if (descending) result = -result;
    if (result != 0) return result;
    return _compareActiveNewest(first, second);
  }

  static int _priorityRank(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return 0;
      case TodoPriority.medium:
        return 1;
      case TodoPriority.low:
        return 2;
    }
  }

  static bool _contains(String value, String query) =>
      value.toLowerCase().contains(query);

  static List<TodoTextRange> _findRanges(String value, String query) {
    if (query.isEmpty) return const <TodoTextRange>[];
    final lower = value.toLowerCase();
    final ranges = <TodoTextRange>[];
    var start = 0;
    while (start < lower.length) {
      final index = lower.indexOf(query, start);
      if (index == -1) break;
      ranges.add(TodoTextRange(index, index + query.length));
      start = index + query.length;
    }
    return List.unmodifiable(ranges);
  }
}
