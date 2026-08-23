# 02 — 默认 List 与 Todo 核心闭环

**What to build:** 用户首次打开 App 时自动获得一个默认 List，并能在首页查看 Todo、创建 Todo、切换完成状态和重新打开 Todo。Todo 的关系数据、默认值和离线持久化贯通到 Flutter 首页，形成第一个可演示的本地 Todo 闭环。

**Blocked by:** 01 — Flutter 根工程与 Todo 工作区 seam

**Status:** done

- [x] 空数据库首次启动时创建且只保留一个默认 List
- [x] Todo 持久化包含 title、detail、priority、dueDate、tags、completed、createdAt 和 updatedAt
- [x] 新建 Todo 默认使用 medium Priority、未完成、无 DueDate 和空 Tag 集合
- [x] 首页展示未完成 Todo 和已完成 Todo 两个分段，未完成内容在前
- [x] 用户可以创建包含标题、详情或其他默认字段的 Todo，并在重启后看到相同数据
- [x] 完全空白的 Todo 仍然是正式 Todo，并在首页保留一行
- [x] 用户点击 Todo 的完成控件后，完成状态立即更新并在重启后保持
- [x] 首页默认按未完成优先、最新创建优先展示 Todo
- [x] Todo 工作区、Drift 持久化和首页 Widget 行为都有外部行为测试
