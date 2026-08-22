# 01 — Flutter 根工程与 Todo 工作区 seam

**What to build:** 从用户可见结果看，App 可以作为一个新的 Flutter Android+iOS 移动 App 启动，并显示一个由项目自有 Design System 驱动的基础工作区。应用层提供统一的 Todo 工作区 seam，页面后续通过它访问领域行为，而不是直接依赖数据库或平台 API。

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] 根工程可构建并启动 Android 与 iOS Flutter App，旧 UniApp 运行目标不再作为首版入口
- [ ] Riverpod 依赖注入、Drift/SQLite 数据库连接和 Todo 工作区应用边界可被测试替换
- [ ] 自有 Design System 提供基础颜色、字号、间距、圆角、触控尺寸、浅色/深色主题 token
- [ ] App 正确处理基础状态栏、安全区和系统主题模式，不遮挡工作区内容
- [ ] 简体中文与 English 的本地化资源可切换，基础壳层没有硬编码用户文案
- [ ] 启动流程和工作区 seam 有可重复运行的 Dart/Widget 测试
