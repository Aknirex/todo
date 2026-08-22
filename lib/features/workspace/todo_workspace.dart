import 'package:flutter/foundation.dart';

import '../../core/storage/app_database.dart';
import 'todo.dart';
import 'todo_query.dart';

class WorkspaceSnapshot {
  const WorkspaceSnapshot({required this.lists, required this.todos});

  final List<WorkspaceList> lists;
  final List<Todo> todos;
}

abstract interface class TodoWorkspaceStore {
  Future<WorkspaceSnapshot> load();

  Future<TodoCommandHistory> loadHistory();

  Future<void> applyBusinessCommand(TodoCommand command);

  Future<bool> undoCommand();

  Future<bool> redoCommand();
}

class DriftTodoWorkspaceStore implements TodoWorkspaceStore {
  const DriftTodoWorkspaceStore(this.database);

  final AppDatabase database;

  @override
  Future<WorkspaceSnapshot> load() async {
    final lists = await database.loadLists();
    return WorkspaceSnapshot(lists: lists, todos: await database.loadTodos());
  }

  @override
  Future<TodoCommandHistory> loadHistory() => database.loadHistory();

  @override
  Future<void> applyBusinessCommand(TodoCommand command) {
    return database.applyBusinessCommand(command);
  }

  @override
  Future<bool> undoCommand() => database.undoCommand();

  @override
  Future<bool> redoCommand() => database.redoCommand();
}

class MemoryTodoWorkspaceStore implements TodoWorkspaceStore {
  MemoryTodoWorkspaceStore({List<WorkspaceList>? lists, List<Todo>? todos})
    : lists =
          lists ??
          const [
            WorkspaceList(id: 'default', name: 'Default List', isDefault: true),
          ],
      todos = List<Todo>.of(todos ?? const <Todo>[]);

  final List<WorkspaceList> lists;
  final List<Todo> todos;
  final List<TodoCommand> undoCommands = <TodoCommand>[];
  final List<TodoCommand> redoCommands = <TodoCommand>[];

  @override
  Future<WorkspaceSnapshot> load() async {
    final sortedTodos =
        todos.toList()..sort((a, b) {
          final completedOrder =
              a.completed == b.completed
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
  Future<TodoCommandHistory> loadHistory() async {
    return TodoCommandHistory(
      undo: List.unmodifiable(undoCommands),
      redo: List.unmodifiable(redoCommands),
    );
  }

  @override
  Future<void> applyBusinessCommand(TodoCommand command) async {
    _applyCommand(command, forward: true);
    redoCommands.clear();
    undoCommands.add(command);
    _trim(undoCommands);
  }

  @override
  Future<bool> undoCommand() async {
    if (undoCommands.isEmpty) return false;
    final command = undoCommands.removeLast();
    _applyCommand(command, forward: false);
    redoCommands.add(command);
    _trim(redoCommands);
    return true;
  }

  @override
  Future<bool> redoCommand() async {
    if (redoCommands.isEmpty) return false;
    final command = redoCommands.removeLast();
    _applyCommand(command, forward: true);
    undoCommands.add(command);
    _trim(undoCommands);
    return true;
  }

  void _applyCommand(TodoCommand command, {required bool forward}) {
    final todo = forward ? command.after : command.before;
    if (todo == null) {
      todos.removeWhere(
        (item) => item.id == (forward ? command.before : command.after)!.id,
      );
      return;
    }
    final index = todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      todos.add(todo);
    } else {
      todos[index] = todo;
    }
  }

  void _trim(List<TodoCommand> commands) {
    if (commands.length > 50) {
      commands.removeRange(0, commands.length - 50);
    }
  }
}

class TodoWorkspace extends ChangeNotifier {
  TodoWorkspace(this.store);

  final TodoWorkspaceStore store;
  WorkspaceSnapshot? _snapshot;
  TodoCommandHistory _history = const TodoCommandHistory(
    undo: <TodoCommand>[],
    redo: <TodoCommand>[],
  );
  int _idSequence = 0;

  Future<void> start() async {
    await _refresh(notify: false);
    notifyListeners();
  }

  Future<WorkspaceSnapshot> read() async {
    await _refresh(notify: true);
    return current;
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
    final targetListId =
        listId ?? activeSnapshot.lists.firstWhere((list) => list.isDefault).id;
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
    await store.applyBusinessCommand(TodoCommand.create(todo));
    await read();
    return todo;
  }

  Future<void> toggleTodo(String id) async {
    final todo = current.todos.firstWhere((item) => item.id == id);
    final updated = todo.copyWith(
      completed: !todo.completed,
      updatedAt: DateTime.now(),
    );
    await store.applyBusinessCommand(
      TodoCommand.complete(before: todo, after: updated),
    );
    await read();
  }

  Future<bool> updateTodo(Todo todo) async {
    final currentTodo = current.todos.firstWhere((item) => item.id == todo.id);
    if (_sameEditableFields(currentTodo, todo)) return false;

    final updated = todo.copyWith(updatedAt: DateTime.now());
    await store.applyBusinessCommand(
      TodoCommand.update(before: currentTodo, after: updated),
    );
    await read();
    return true;
  }

  Future<bool> deleteTodo(String id) async {
    final todo = current.todos.firstWhere((item) => item.id == id);
    await store.applyBusinessCommand(TodoCommand.delete(todo));
    await read();
    return true;
  }

  Future<bool> undo() async {
    final changed = await store.undoCommand();
    if (changed) await read();
    return changed;
  }

  Future<bool> redo() async {
    final changed = await store.redoCommand();
    if (changed) await read();
    return changed;
  }

  bool get canUndo => _history.canUndo;

  bool get canRedo => _history.canRedo;

  Future<void> _refresh({required bool notify}) async {
    _snapshot = await store.load();
    _history = await store.loadHistory();
    if (notify) notifyListeners();
  }

  TodoQueryResult queryTodos({
    TodoQuery query = const TodoQuery(),
    DateTime? now,
  }) {
    return TodoQueryEngine.apply(current.todos, query, now: now);
  }

  WorkspaceSnapshot get current =>
      _snapshot ??
      const WorkspaceSnapshot(lists: <WorkspaceList>[], todos: <Todo>[]);
}

bool _sameEditableFields(Todo first, Todo second) {
  if (first.title != second.title ||
      first.detail != second.detail ||
      first.priority != second.priority ||
      first.dueDate != second.dueDate ||
      first.tags.length != second.tags.length) {
    return false;
  }
  for (var index = 0; index < first.tags.length; index++) {
    if (first.tags[index] != second.tags[index]) return false;
  }
  return true;
}
