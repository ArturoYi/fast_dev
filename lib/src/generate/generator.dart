import '../config/config.dart';
import '../pubspec/parse.dart';
import 'assets/expand.dart';

/// 一次 `gen` 可挂多个生成器。当前内置只有 assets。
///
/// 新增能力时：
/// 1. 实现本接口；
/// 2. 把实例加进 `builtInGenerators`（见 `plan.dart`）；
/// 3. 把配置键从 [kReservedGenerateConfigKeys]（或根级预留键）
///    挪到对应的 known 集合并补解析；
/// 4. 若要读盘，在 `runGenerate` / `composeGenerate` 里准备输入，
///    放进 [GeneratorContext]。
///
/// 阶段与预留扩展见文档站计划页。
abstract interface class Generator {
  /// 稳定 id，用于 skip 文案，并与未来的 `generate.<id>` 配置段对齐。
  String get id;

  /// 根据 [context] 产出文件、告警或跳过说明。
  GeneratorResult generate(GeneratorContext context);
}

/// 单个生成器一轮执行需要的只读输入。
///
/// 字段按现有生成器需要的最小集合来放；新生成器若要更多数据，往这里加
/// 可选字段，避免每个生成器自己再读一遍磁盘。
final class GeneratorContext {
  /// 见各字段说明。
  const GeneratorContext({
    required this.config,
    required this.parsed,
    required this.outputDirectory,
    this.expandedAssets,
  });

  /// 已与默认值合并的配置。
  final FastDevConfig config;

  /// 已解析的 `pubspec.yaml` 清单。
  final FlutterManifestParseResult parsed;

  /// 生成文件目录，相对项目根，以 `/` 结尾。
  ///
  /// 已合并 `generate.output` 与 `build.yaml` 的 `options.output`。
  final String outputDirectory;

  /// 已展开的资源路径。assets 生成器使用；其它生成器可忽略。
  final AssetExpandResult? expandedAssets;
}

/// 单个生成器的产出。
final class GeneratorResult {
  /// 见各字段说明。
  const GeneratorResult({
    this.outputs = const [],
    this.skipped,
    this.warnings = const [],
  });

  /// 要写出的文件。可以为空（例如被关掉或没有输入）。
  final List<PlannedOutput> outputs;

  /// 非空表示本轮没有写文件，文案会进「已跳过」。
  final String? skipped;

  /// 本生成器范围内的非致命告警。
  final List<String> warnings;
}

/// 计划写出的一份源码。
final class PlannedOutput {
  /// 见各字段说明。
  const PlannedOutput({required this.relativePath, required this.contents});

  /// 相对项目根，posix 分隔。
  final String relativePath;

  /// 已格式化的 Dart 源码。
  final String contents;
}
