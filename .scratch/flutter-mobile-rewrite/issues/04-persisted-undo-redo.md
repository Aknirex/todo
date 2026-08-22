# 04 — 删除与持久化 Undo/Redo

**What to build:** 用户可以直接删除 Todo，并在首页或详情页使用 Undo/Redo 恢复或重做最近的业务命令。历史在 App 重启后仍然存在，编辑按一次用户意图计步，Redo 在新业务操作后清空。

**Blocked by:** 03 — Todo 详情与移动端编辑生命周期

**Status:** ready-for-agent

- [ ] 单个 Todo 删除无需确认即可从当前可见集合移除
- [ ] 删除、创建、完成切换和一次详情编辑分别形成可恢复的业务命令
- [ ] Undo 和 Redo 各自最多保留 50 步，超过上限时丢弃最早记录
- [ ] Undo 将最近业务命令移入 Redo 并应用反向变更
- [ ] Redo 将最近 Undo 命令移回 Undo 并重新应用变更
- [ ] 执行新创建、编辑、完成或删除命令后清空 Redo
- [ ] Undo 或 Redo 本身不产生新的历史命令
- [ ] App 重启后 Undo/Redo 栈和 Todo 当前状态保持一致
- [ ] 首页和详情页都显示 Undo/Redo 控件，并在对应栈为空时置灰
- [ ] 删除空白 Todo、编辑空白 Todo 和完成空白 Todo 都遵循普通 Todo 历史语义
- [ ] Undo/Redo 的领域规则、数据库事务和页面行为都有测试
