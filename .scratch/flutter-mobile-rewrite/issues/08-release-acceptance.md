# 08 — 真机集成与发布验收

**What to build:** 对完整 Flutter App 执行从启动到核心用户流程的 Android+iOS 集成验收，确保 Todo、List、Undo、Redo、搜索、筛选、主题、本地化和 JSON 备份在真实移动环境中可用，并清理不再属于首版范围的运行入口与依赖。

**Blocked by:** 07 — 移动端视觉与平台交互硬化

**Status:** done-with-limitations

- [ ] Android 真机完成启动、创建、编辑、完成、删除、Undo、Redo、搜索、筛选和备份恢复流程
- [ ] iOS 模拟器或真机完成启动、创建、编辑、完成、删除、Undo、Redo、搜索、筛选和备份恢复流程
- [ ] Android 系统返回、键盘、状态栏和底部安全区通过集成验收
- [ ] iOS 返回手势、键盘、安全区和主题切换通过集成验收
- [x] App 重启后 Todo、List、主题、语言和 Undo/Redo 状态符合规格
- [x] 空白 Todo、空结果、冲突导入和失败回滚等边界场景通过验收
- [x] Dart、Drift、Widget、Golden 和 integration 测试在干净环境中通过
- [x] 构建产物不再依赖微信小程序、H5、AI、Agent API 或云同步运行入口
- [x] 发布验收记录明确最低 Android/iOS 系统版本、签名配置和已知限制

**限制：** 当前 Windows 环境无 Android/iOS 真机与模拟器，Android 构建因 SDK 36/Gradle TLS 工具链未完成；上述 4 项待有对应环境后验收。详见 `docs/flutter-mobile-release-acceptance.md`。
