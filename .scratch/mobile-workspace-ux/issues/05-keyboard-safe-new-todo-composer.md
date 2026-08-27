# 05 — 键盘安全的新建 Todo 表单

**What to build:** 新建 Todo 流程改为适合移动端单手使用的表单。用户输入详情后无需收起键盘即可创建，创建按钮始终可操作；Priority、Tag、DueDate 与核心文本在有限屏幕空间内保持清晰。

**Blocked by:** 01 — Todo 展示摘要与 Tag 输入规范化; 02 — 工作区本地化与分段空状态

**Status:** ready-for-agent

- [ ] 工作区新建入口位于屏幕右下角拇指热区，并遵守底部安全区。
- [ ] 新建表单突出标题和详情输入框。
- [ ] Priority 与 Tag 在同一行布局，Tag 获得相对更宽的输入空间。
- [ ] DueDate 与 Create 在同一行布局，Create 保持足够的触控尺寸。
- [ ] 键盘显示时 Create 仍可见或可直接操作，不要求用户先收起键盘。
- [ ] 创建提交当前标题、详情、Priority、DueDate 和 Tag，不丢失输入内容。
- [ ] 新建 Todo 默认使用 medium Priority，并在返回工作区后立即显示 Priority badge。
- [ ] 新建页面不显示 Undo 或 Redo 控件，已有编辑页面行为不回归。
- [ ] 编辑器 widget 测试覆盖键盘开启时创建、字段布局、默认 Priority 和全角逗号 Tag。
