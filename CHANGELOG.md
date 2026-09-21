## 0.0.1-beta.1

* **Fast Dev**（`fast_dev`）：开发期用的 Flutter 工具，写在 `dev_dependencies`。CLI 和 `build_runner` Builder 在同一个包里。
* 为 Flutter `flutter.assets` 生成类型安全的 `assets.gen.dart`（含 theme / locale 变体）。
* 为 Flutter `flutter.fonts` 生成类型安全的 `fonts.gen.dart`（`FontFamily.raleway`；库模式写出 `packages/$package/Family`；可选 `FontFamily.fallbacks`）。
* 提供 CLI（`config`、`gen`）和 `build_runner` Builder。
* 增加 VitePress 中英文文档、MIT 说明与 Bug 报告规范。
* colors / import 整理尚未实现；配置键已预留，阶段表见文档站计划页。
