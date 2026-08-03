# 02 — 状态管理层

**What to build:** Pinia stores 实现完整业务逻辑 — TodoStore（CRUD + 过滤）、ListStore（列表管理）、UndoStore（撤销栈 ≥50 步，自动持久化）。所有 store 操作自动记录到 UndoStack，支持全局撤销。

**Blocked by:** 01 — 项目基础层

**Status:** ready-for-agent

- [ ] TodoStore: createTodo / updateTodo / deleteTodo / toggleComplete / loadTodos
- [ ] TodoStore: activeTodos / completedTodos / todosByList 计算属性
- [ ] ListStore: createList / updateList / deleteList / loadLists
- [ ] ListStore: 默认列表保护（不可删除）
- [ ] UndoStore: record / undo / canUndo / loadFromDb
- [ ] UndoStore: 撤销栈上限 50，超出丢弃最早记录
- [ ] 所有 TodoStore 操作自动调用 undoStore.record
- [ ] 所有 ListStore 操作自动调用 undoStore.record
- [ ] 撤销操作正确恢复实体状态
- [ ] 所有 Store 有单元测试覆盖
