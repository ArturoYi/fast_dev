import '../config/config.dart';
import '../pubspec/parse.dart';
import 'assets/expand.dart';
import 'assets/generator.dart';
import 'fonts/generator.dart';
import 'generator.dart';

export 'generator.dart';

/// 当前版本会跑的生成器。加新能力时往这里追加，不要在 [planGenerate] 里写分支。
const List<Generator> builtInGenerators = [AssetsGenerator(), FontsGenerator()];

/// 一次生成要写出的文件、跳过项和告警。CLI 与 `build_runner` 共用。
///
/// 到这一步已经不访问文件系统：调用方负责读配置 / pubspec、展开资源。
final class GeneratePlan {
  /// 见各字段说明。
  const GeneratePlan({
    required this.outputs,
    required this.skipped,
    required this.warnings,
  });

  /// 相对项目根的生成文件。目前是 `assets.gen.dart` / `fonts.gen.dart`。
  final List<PlannedOutput> outputs;

  /// 关掉或没有输入的生成器。
  final List<String> skipped;

  /// pubspec、展开、分组阶段的告警。
  final List<String> warnings;
}

/// 根据已解析配置和已展开路径决定写出哪些文件。
///
/// [outputOverride] 非空时覆盖 `generate.output`（给 `build.yaml` options 用）。
/// [generators] 默认是 [builtInGenerators]；测试或后续模块可以换成自定义列表。
GeneratePlan planGenerate({
  required FastDevConfig config,
  required FlutterManifestParseResult parsed,
  AssetExpandResult? expanded,
  String? outputOverride,
  List<Generator>? generators,
}) {
  final warnings = [...parsed.warnings];
  final skipped = <String>[];
  final outputs = <PlannedOutput>[];
  final context = GeneratorContext(
    config: config,
    parsed: parsed,
    outputDirectory: outputOverride ?? config.generate.output,
    expandedAssets: expanded,
  );

  for (final generator in generators ?? builtInGenerators) {
    final result = generator.generate(context);
    warnings.addAll(result.warnings);
    outputs.addAll(result.outputs);
    final skippedReason = result.skipped;
    if (skippedReason != null) {
      skipped.add(skippedReason);
    }
  }

  return GeneratePlan(
    outputs: List.unmodifiable(outputs),
    skipped: List.unmodifiable(skipped),
    warnings: List.unmodifiable(warnings),
  );
}
