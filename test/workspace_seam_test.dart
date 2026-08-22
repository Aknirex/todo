import 'package:flutter_test/flutter_test.dart';

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

  test('workspace toggles completion and keeps newest active Todo first', () async {
    final store = MemoryTodoWorkspaceStore();
    final workspace = TodoWorkspace(store);
    await workspace.start();
    final older = await workspace.createTodo(title: 'Older');
    final newer = await workspace.createTodo(title: 'Newer');

    expect(
      workspace.current.todos.map((todo) => todo.title).toList(growable: false),
      ['Newer', 'Older'],
    );

    await workspace.toggleTodo(older.id);

    expect(
      workspace.current.todos.map((todo) => todo.title).toList(growable: false),
      ['Newer', 'Older'],
    );
    expect(workspace.current.todos.last.completed, isTrue);

    final restarted = TodoWorkspace(store);
    await restarted.start();
    expect(restarted.current.todos.last.completed, isTrue);
  });
}
