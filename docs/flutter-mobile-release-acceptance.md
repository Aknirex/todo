# Flutter 移动端发布验收记录

**日期:** 2026-08-23
**范围:** ticket-08，基于已合并并验证的 `ticket-07-mobile-fidelity-v3`
**目标:** Android+iOS 本地优先 Todo 首版

## 自动化检查

| 检查 | 结果 |
|------|------|
| `flutter pub get` | 通过 |
| `dart format --output=none --set-exit-if-changed lib test` | 通过 |
| `flutter analyze` | 通过；6 个预先存在的 info-level Flutter SDK `Radio` 弃用诊断（无 errors/warnings），CI 使用 `--no-fatal-infos` |
| `flutter test` | 通过；46 tests |
| CI（GitHub Actions，Flutter 3.41.9）| format/analyze/test 全部通过 |
| Android release APK/AAB（CI）| 通过；Flutter 3.41.9 + Gradle 8.14 + AGP 8.11.1 |
| iOS release（CI，unsigned）| 通过；Flutter 3.41.9，`--no-codesign` |

## 自动化覆盖

- 覆盖空白 Todo、空结果查询后清空查询、核心 CRUD、完成切换、搜索/筛选/排序、主题/语言、JSON 合并导入、冲突报告和失败回滚。
- 覆盖 Drift 重启后的默认 List、Todo 数据及 Undo/Redo 状态。
- 覆盖 Golden、Widget、Dart 领域和 SQLite 持久化测试。
- GitHub Actions：push/PR 运行 CI；`v*` tag 或手动触发构建 Android（APK+AAB）与 iOS 并发布 GitHub Release（v0.1.0 已发布）。

## 平台限制

- 当前没有连接 Android 真机，也没有可用 Android 模拟器；CI 构建成功不代表真机流程已验收。
- iOS 为 unsigned 构建（无签名配置）；真机、返回手势和 iOS 键盘/安全区验收无法在 Windows 环境执行。
- 未声称真实设备上的状态栏、键盘、触控目标或返回手势验收完成。
- Swift Package Manager 已在 `pubspec.yaml`（`flutter.config.enable-swift-package-manager: false`）关闭，使用 CocoaPods。

## 发布配置

- 最低 iOS 版本：13.0（`ios/Podfile`）。
- 最低 Android API：24；`targetSdk`/`compileSdk`：36（当前工程跟随 Flutter 3.41.9 默认值）。
- Android 签名：CI 未配置 secrets 时使用 debug 签名；配置 `ANDROID_KEYSTORE_BASE64` 等 secrets 后使用正式签名。
- iOS 签名：配置 `IOS_CERTIFICATE_BASE64`、`IOS_CERTIFICATE_PASSWORD`、`IOS_PROVISIONING_PROFILE_BASE64` secrets 后可构建签名 IPA，否则构建 unsigned。
