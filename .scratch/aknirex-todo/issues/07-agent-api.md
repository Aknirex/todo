# 07 — Agent API 服务

**What to build:** Android 端内置 HTTP 服务器，提供 RESTful API 供第三方 Agent 通过局域网操控用户的 todo 列表。包含认证（API Key）、限流（100次/分钟）、完整路由。

**Blocked by:** 01 — 项目基础层, 02 — 状态管理层

**Status:** ready-for-agent

- [ ] HTTP 服务器启动/停止（Android 端，可配置端口）
- [ ] API Key 认证中间件（X-Api-Key 请求头）
- [ ] 限流中间件（按 API Key，100 次/分钟）
- [ ] POST /api/v1/todos — 创建 todo
- [ ] GET /api/v1/todos — 列出 todo（支持筛选参数）
- [ ] GET /api/v1/todos/:id — 获取单个 todo
- [ ] PATCH /api/v1/todos/:id — 更新 todo
- [ ] DELETE /api/v1/todos/:id — 删除 todo
- [ ] POST /api/v1/todos/:id/toggle — 切换完成状态
- [ ] POST /api/v1/todos/batch — 批量创建
- [ ] GET /api/v1/lists — 列出所有列表
- [ ] GET /api/v1/lists/:id — 获取列表详情
- [ ] GET /api/v1/search?q= — 全局搜索
- [ ] POST /api/v1/undo — 撤销最近操作
- [ ] 统一响应格式 { code, message, data }
- [ ] 标准错误码（1001/1002/2001/2002/3001）
