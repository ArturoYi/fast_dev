/// Fast Dev：只放在 `dev_dependencies` 的 Flutter 开发期工具。
///
/// 当前实现 assets 代码生成。CLI（`dart run fast_dev`）和 `build_runner`
/// Builder 在同一个包里。fonts / colors / import 整理的扩展方式见
/// [Generator] 与文档站计划页。
library;

export 'src/config/config.dart';
export 'src/config/exception.dart';
export 'src/config/load.dart';
export 'src/config/parse.dart';
export 'src/generate/assets/expand.dart';
export 'src/generate/assets/generate.dart';
export 'src/generate/assets/generator.dart';
export 'src/generate/exception.dart';
export 'src/generate/generator.dart';
export 'src/generate/plan.dart';
export 'src/generate/run.dart';
export 'src/pubspec/parse.dart';
