# 04 — 同级筛选与排序面板

**What to build:** 将排序与筛选调整为同级移动端操作，避免排序独占一行；筛选或排序展开后使用不会遮挡触发按钮的 dropdown 或 bottom sheet，让用户可以快速调整结果集合。

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Priority、Tag、完成状态、DueDate 筛选与排序作为同级操作呈现。
- [ ] 排序不再单独占用一整行。
- [ ] 展开的下拉面板或 bottom sheet 与触发控件保持足够间距，不遮挡 Priority 等触发标签。
- [ ] 面板在移动端安全区内可完整查看、选择和关闭。
- [ ] 现有筛选维度内的多选、维度之间的组合以及排序规则保持不变。
- [ ] 筛选和排序展开动画明显快于当前实现，同时保持可感知的过渡。
- [ ] 窄屏 widget 测试覆盖控件可达性、面板选择和结果更新。
