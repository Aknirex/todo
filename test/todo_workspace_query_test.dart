import 'package:flutter_test/flutter_test.dart';

import 'package:aknirex_todo/features/workspace/todo.dart';
import 'package:aknirex_todo/features/workspace/todo_query.dart';
import 'package:aknirex_todo/features/workspace/todo_workspace.dart';

void main() {
  test(
    'workspace query reads the current local snapshot without a network seam',
    () async {
      final store = MemoryTodoWorkspaceStore(
        todos: [
          Todo.create(
            id: 'local',
            listId: 'default',
            title: 'Local only',
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          ),
        ],
      );
      final workspace = TodoWorkspace(store);
      await workspace.start();

      final result = workspace.queryTodos(
        query: const TodoQuery(search: 'local'),
        now: DateTime(2026, 8, 12),
      );

      expect(result.todos.single.id, 'local');
    },
  );
}
