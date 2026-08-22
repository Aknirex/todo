import 'package:flutter_test/flutter_test.dart';

import 'package:aknirex_todo/features/workspace/todo.dart';
import 'package:aknirex_todo/features/workspace/todo_query.dart';

void main() {
  final now = DateTime(2026, 8, 12, 15);

  test('searches title, detail, and tags with title matches first', () {
    final todos = [
      _todo('detail', title: 'Other', detail: 'Needle in the detail'),
      _todo('title', title: 'Needle in the title'),
      _todo('tag', title: 'Other', tags: const ['needle']),
    ];

    final result = TodoQueryEngine.apply(
      todos,
      const TodoQuery(search: 'NEEDLE'),
      now: now,
    );

    expect(result.todos.map((todo) => todo.id), ['title', 'tag', 'detail']);
    expect(result.matches.first.titleRanges, hasLength(1));
    expect(result.matches.first.titleRanges.single.start, 0);
    expect(result.matches.first.titleRanges.single.end, 6);
  });

  test('applies OR within dimensions and AND across dimensions', () {
    final todos = [
      _todo('high-work', priority: TodoPriority.high, tags: const ['work']),
      _todo('low-home', priority: TodoPriority.low, tags: const ['home']),
      _todo('medium-work', tags: const ['work']),
      _todo(
        'high-home',
        priority: TodoPriority.high,
        tags: const ['home'],
        completed: true,
      ),
    ];

    final result = TodoQueryEngine.apply(
      todos,
      const TodoQuery(
        priorities: {TodoPriority.high, TodoPriority.low},
        tags: {'work', 'home'},
        completed: false,
        sort: TodoSort.priority,
      ),
      now: now,
    );

    expect(result.todos.map((todo) => todo.id), ['high-work', 'low-home']);
  });

  test('uses local DueDate buckets and supports multiple buckets', () {
    final todos = [
      _todo('overdue', dueDate: DateTime(2026, 8, 11)),
      _todo('today', dueDate: DateTime(2026, 8, 12, 22)),
      _todo('week', dueDate: DateTime(2026, 8, 16)),
      _todo('month', dueDate: DateTime(2026, 8, 25)),
      _todo('none'),
      _todo('next-month', dueDate: DateTime(2026, 9, 1)),
    ];

    final result = TodoQueryEngine.apply(
      todos,
      const TodoQuery(
        dueDateFilters: {
          TodoDueDateFilter.today,
          TodoDueDateFilter.overdue,
          TodoDueDateFilter.noDueDate,
        },
        sort: TodoSort.dueDate,
      ),
      now: now,
    );

    expect(result.todos.map((todo) => todo.id), ['overdue', 'today', 'none']);
  });

  test('sorts by priority, DueDate, and title', () {
    final todos = [
      _todo('low', title: 'Bravo', priority: TodoPriority.low),
      _todo(
        'high',
        title: 'Charlie',
        priority: TodoPriority.high,
        dueDate: DateTime(2026, 8, 20),
      ),
      _todo('medium', title: 'Alpha', dueDate: DateTime(2026, 8, 13)),
    ];

    expect(
      TodoQueryEngine.apply(
        todos,
        const TodoQuery(sort: TodoSort.priority),
        now: now,
      ).todos.map((todo) => todo.id),
      ['high', 'medium', 'low'],
    );
    expect(
      TodoQueryEngine.apply(
        todos,
        const TodoQuery(sort: TodoSort.dueDate),
        now: now,
      ).todos.map((todo) => todo.id),
      ['medium', 'high', 'low'],
    );
    expect(
      TodoQueryEngine.apply(
        todos,
        const TodoQuery(sort: TodoSort.titleAscending),
        now: now,
      ).todos.map((todo) => todo.id),
      ['medium', 'low', 'high'],
    );
  });
}

Todo _todo(
  String id, {
  String title = '',
  String detail = '',
  TodoPriority priority = TodoPriority.medium,
  DateTime? dueDate,
  Iterable<String> tags = const <String>[],
  bool completed = false,
}) {
  return Todo.create(
    id: id,
    listId: 'default',
    title: title,
    detail: detail,
    priority: priority,
    dueDate: dueDate,
    tags: tags,
    completed: completed,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}
