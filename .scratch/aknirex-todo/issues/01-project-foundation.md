# 01 — 项目基础层

**What to build:** 完整的数据访问层（DAL），包括 TypeScript 类型定义、UUID/平台检测工具函数、SQLite 数据库初始化与迁移（todo/list/undo_record/agent_config 四张表）、以及 Todo/List/Undo 三个 Repository（CRUD + 搜索 + 软删除）。

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] TypeScript 类型定义完整（Todo, CreateTodoInput, UpdateTodoInput, TodoList, UndoRecord, AgentConfig, ApiResponse, TodoFilter）
- [ ] UUID 生成工具可用
- [ ] 平台检测工具可用（mp-weixin / app / h5）
- [ ] SQLite 初始化 + 四张表迁移成功
- [ ] todoRepository 支持 findAll / insert / update / softDelete / toggleComplete / search
- [ ] listRepository 支持 findAll / insert / update / delete / findDefault
- [ ] undoRepository 支持 insert / findRecent / delete / deleteOlderThan
- [ ] agentConfigRepository 支持 load / save
- [ ] 所有 Repository 有单元测试覆盖
