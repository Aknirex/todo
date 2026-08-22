import 'package:flutter_test/flutter_test.dart';

import 'package:aknirex_todo/core/storage/app_database.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';
import 'package:aknirex_todo/features/workspace/todo.dart';

void main() {
  test('workspace loads through a replaceable store seam', () async {
    final store = MemoryTodoWorkspaceStore();
    final workspace = TodoWorkspace(store);

    await workspace.start();

    expect(workspace.current.lists, hasLength(1));
    expect(workspace.current.lists.single.isDefault, isTrue);
    expect(workspace.current.todos, isEmpty);
  });

  test('workspace can be supplied with a custom test list', () async {
    final workspace = TodoWorkspace(
      MemoryTodoWorkspaceStore(
        lists: const [
          WorkspaceList(id: 'test', name: 'Test List', isDefault: true),
        ],
      ),
    );

    await workspace.start();

    expect(workspace.current.lists.single.name, 'Test List');
  });

  test('workspace creates a blank Todo with core defaults', () async {
    final store = MemoryTodoWorkspaceStore();
    final workspace = TodoWorkspace(store);
    await workspace.start();

    final todo = await workspace.createTodo();

    expect(todo.title, isEmpty);
    expect(todo.detail, isEmpty);
    expect(todo.priority, TodoPriority.medium);
    expect(todo.dueDate, isNull);
    expect(todo.tags, isEmpty);
    expect(todo.completed, isFalse);
    expect(workspace.current.todos, hasLength(1));
    expect(workspace.current.todos.single.id, todo.id);
  });

  test(
    'workspace toggles completion and keeps newest active Todo first',
    () async {
      final store = MemoryTodoWorkspaceStore();
      final workspace = TodoWorkspace(store);
      await workspace.start();
      final older = await workspace.createTodo(title: 'Older');
      await workspace.createTodo(title: 'Newer');

      expect(
        workspace.current.todos
            .map((todo) => todo.title)
            .toList(growable: false),
        ['Newer', 'Older'],
      );

      await workspace.toggleTodo(older.id);

      expect(
        workspace.current.todos
            .map((todo) => todo.title)
            .toList(growable: false),
        ['Newer', 'Older'],
      );
      expect(workspace.current.todos.last.completed, isTrue);

      final restarted = TodoWorkspace(store);
      await restarted.start();
      expect(restarted.current.todos.last.completed, isTrue);
    },
  );

  test(
    'workspace submits one changed edit and skips unchanged edits',
    () async {
      final store = _CountingTodoWorkspaceStore();
      final workspace = TodoWorkspace(store);
      await workspace.start();
      final todo = await workspace.createTodo(title: 'Before');
      store.updateCount = 0;

      final unchanged = await workspace.updateTodo(
        todo.copyWith(title: 'Before'),
      );
      expect(unchanged, isFalse);
      expect(store.updateCount, 0);

      final changed = await workspace.updateTodo(
        todo.copyWith(
          title: 'After',
          detail: 'Details',
          priority: TodoPriority.high,
          dueDate: DateTime.utc(2026, 7, 8, 23),
          tags: const [' work ', '', 'work', 'home'],
        ),
      );
      expect(changed, isTrue);
      expect(store.updateCount, 1);
      expect(workspace.current.todos.single.title, 'After');
      expect(workspace.current.todos.single.dueDate, DateTime(2026, 7, 8));
      expect(workspace.current.todos.single.tags, ['work', 'home']);
    },
  );
}

class _CountingTodoWorkspaceStore implements TodoWorkspaceStore {
  final _delegate = MemoryTodoWorkspaceStore();
  int updateCount = 0;

  @override
  Future<WorkspaceSnapshot> load() => _delegate.load();

  @override
  Future<void> insertTodo(Todo todo) => _delegate.insertTodo(todo);

  @override
  Future<void> updateTodoCompletion(
    String id,
    bool completed,
    DateTime updatedAt,
  ) => _delegate.updateTodoCompletion(id, completed, updatedAt);

  @override
  Future<void> updateTodo(Todo todo) async {
    updateCount++;
    await _delegate.updateTodo(todo);
  }
}
