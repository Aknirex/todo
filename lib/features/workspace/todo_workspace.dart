import 'package:flutter/foundation.dart';

import '../../core/storage/app_database.dart';
import 'todo.dart';

class WorkspaceSnapshot {
  const WorkspaceSnapshot({required this.lists, required this.todos});

  final List<WorkspaceList> lists;
  final List<Todo> todos;
}

abstract interface class TodoWorkspaceStore {
  Future<WorkspaceSnapshot> load();

  Future<void> insertTodo(Todo todo);

  Future<void> updateTodoCompletion(
    String id,
    bool completed,
    DateTime updatedAt,
  );
}

class DriftTodoWorkspaceStore implements TodoWorkspaceStore {
  const DriftTodoWorkspaceStore(this.database);

  final AppDatabase database;

  @override
  Future<WorkspaceSnapshot> load() async {
    final lists = await database.loadLists();
    final defaultList = lists.firstWhere((list) => list.isDefault);
    return WorkspaceSnapshot(
      lists: lists,
      todos: await database.loadTodos(listId: defaultList.id),
    );
  }

  @override
  Future<void> insertTodo(Todo todo) => database.insertTodo(todo);

  @override
  Future<void> updateTodoCompletion(
    String id,
    bool completed,
    DateTime updatedAt,
  ) {
    return database.updateTodoCompletion(id, completed, updatedAt);
  }
}

class MemoryTodoWorkspaceStore implements TodoWorkspaceStore {
  MemoryTodoWorkspaceStore({List<WorkspaceList>? lists, List<Todo>? todos})
      : lists = lists ??
            const [
              WorkspaceList(
                id: 'default',
                name: 'Default List',
                isDefault: true,
              ),
            ],
        todos = List<Todo>.of(todos ?? const <Todo>[]);

  final List<WorkspaceList> lists;
  final List<Todo> todos;

  @override
  Future<WorkspaceSnapshot> load() async {
    final sortedTodos = todos.toList()
      ..sort((a, b) {
        final completedOrder = a.completed == b.completed
            ? 0
            : a.completed
                ? 1
                : -1;
        return completedOrder != 0
            ? completedOrder
            : b.createdAt.compareTo(a.createdAt) != 0
                ? b.createdAt.compareTo(a.createdAt)
                : b.id.compareTo(a.id);
      });
    return WorkspaceSnapshot(
      lists: List.unmodifiable(lists),
      todos: List.unmodifiable(sortedTodos),
    );
  }

  @override
  Future<void> insertTodo(Todo todo) async {
    todos.add(todo);
  }

  @override
  Future<void> updateTodoCompletion(
    String id,
    bool completed,
    DateTime updatedAt,
  ) async {
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    todos[index] = todos[index].copyWith(
      completed: completed,
      updatedAt: updatedAt,
    );
  }
}

class TodoWorkspace extends ChangeNotifier {
  TodoWorkspace(this.store);

  final TodoWorkspaceStore store;
  WorkspaceSnapshot? _snapshot;
  int _idSequence = 0;

  Future<void> start() async {
    _snapshot = await store.load();
    notifyListeners();
  }

  Future<WorkspaceSnapshot> read() async {
    final snapshot = await store.load();
    _snapshot = snapshot;
    notifyListeners();
    return snapshot;
  }

  Future<Todo> createTodo({
    String? listId,
    String title = '',
    String detail = '',
    TodoPriority priority = TodoPriority.medium,
    DateTime? dueDate,
    Iterable<String> tags = const <String>[],
  }) async {
    final activeSnapshot = _snapshot ?? await read();
    final targetListId = listId ??
        activeSnapshot.lists.firstWhere((list) => list.isDefault).id;
    final now = DateTime.now();
    final todo = Todo.create(
      id: '${now.microsecondsSinceEpoch}-${_idSequence++}',
      listId: targetListId,
      title: title,
      detail: detail,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      createdAt: now,
    );
    await store.insertTodo(todo);
    await read();
    return todo;
  }

  Future<void> toggleTodo(String id) async {
    final todo = current.todos.firstWhere((item) => item.id == id);
    await store.updateTodoCompletion(
      id,
      !todo.completed,
      DateTime.now(),
    );
    await read();
  }

  WorkspaceSnapshot get current =>
      _snapshot ??
          const WorkspaceSnapshot(
            lists: <WorkspaceList>[],
            todos: <Todo>[],
          );
}
