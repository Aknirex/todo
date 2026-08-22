# Flutter 移动端发布验收记录

**日期:** 2026-08-23
**范围:** ticket-08，基于已合并并验证的 `ticket-07-mobile-fidelity-v3`
**目标:** Android+iOS 本地优先 Todo 首版

## 自动化检查

| 检查 | 结果 |
|------|------|
| `flutter pub get` | 通过 |
| `dart format --output=none --set-exit-if-changed lib test` | 通过 |
| `flutter analyze` | Exit 0 not claimed；6 个预先存在的 info-level Flutter SDK `Radio` 弃用诊断仍存在；无 errors/warnings |
| `flutter test` | 通过；46 tests |
| Android debug/profile/release | 未完成，Android toolchain 不满足要求 |
| iOS build/simulator/device | 未完成，当前环境为 Windows |

## 自动化覆盖

- 覆盖空白 Todo、空结果查询后清空查询、核心 CRUD、完成切换、搜索/筛选/排序、主题/语言、JSON 合并导入、冲突报告和失败回滚。
- 覆盖 Drift 重启后的默认 List、Todo 数据及 Undo/Redo 状态。
- 覆盖 Golden、Widget、Dart 领域和 SQLite 持久化测试。

## 平台限制

- 当前没有连接 Android 真机，也没有可用 Android 模拟器。
- Android SDK 为 35.0.0；Flutter 检查要求 SDK 36、BuildTools 28.0.3，且 Android license 状态未知。已尝试 debug APK，Gradle 因 Maven TLS 握手失败未完成；profile/release 未执行。
- iOS 构建、模拟器、真机、返回手势和 iOS 键盘/安全区验收无法在 Windows 环境执行。
- 未声称真实设备上的状态栏、键盘、触控目标或返回手势验收完成。

## 发布配置

- 最低 iOS 版本：13.0（`ios/Podfile`）。
- 最低 Android API：24；`targetSdk`/`compileSdk`：36（当前工程跟随 Flutter 3.41.9 默认值）。
- Android/iOS 签名配置未提供，仍需在发布环境配置。
