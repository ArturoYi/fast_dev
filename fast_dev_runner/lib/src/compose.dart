import 'package:fast_dev/fast_dev.dart';

import 'discover.dart';
import 'manifest.dart';

/// [composeGenerate] 的结果：清单 + 需要打印的告警 / 跳过项。
final class ComposeResult {
  /// 见各字段说明。
  const ComposeResult({
    required this.manifest,
    required this.warnings,
    required this.skipped,
  });

  /// 交给 post-process 的中间结果。
  final FastDevManifest manifest;

  /// 配置解析、展开、分组阶段的告警。
  final List<String> warnings;

  /// 关掉或没有输入的生成器。
  final List<String> skipped;
}

/// 把已经读到的文本和路径组合成清单，不访问文件系统。
///
/// [generators] 默认是 [builtInGenerators]。
ComposeResult composeGenerate({
  required String packageName,
  required String packageRoot,
  required String pubspecContents,
  String? configContents,
  List<String> graphPaths = const [],
  AssetExpandResult? disk,
  String? outputOverride,
  List<Generator>? generators,
}) {
  final parsedConfig = configContents == null
      ? ParseResult(
          config: FastDevConfig.defaults,
          warnings: ['未找到 $kConfigFileName，已使用内置默认值'],
        )
      : parseFastDevConfig(
          configContents,
          sourceUrl: Uri.parse(kConfigFileName),
        );

  final parsedPubspec = parseFlutterManifest(
    pubspecContents,
    sourceUrl: Uri.parse('pubspec.yaml'),
  );

  final active = generators ?? builtInGenerators;
  final wantsAssets =
      parsedConfig.config.generate.assets.enabled &&
      active.any((generator) => generator.id == AssetsGenerator.generatorId);
  final expanded = wantsAssets
      ? mergeDiscoveredAssets(
          entries: parsedPubspec.manifest.assetEntries,
          graphPaths: graphPaths,
          disk: disk,
        )
      : null;

  final plan = planGenerate(
    config: parsedConfig.config,
    parsed: parsedPubspec,
    expanded: expanded,
    outputOverride: outputOverride,
    generators: active,
  );

  return ComposeResult(
    manifest: FastDevManifest(
      packageName: packageName,
      packageRoot: packageRoot,
      outputs: [
        for (final output in plan.outputs)
          ManifestOutput(path: output.relativePath, contents: output.contents),
      ],
    ),
    warnings: [...parsedConfig.warnings, ...plan.warnings],
    skipped: plan.skipped,
  );
}

/// 从 `build.yaml` 的 `options.output` 读出目录，统一成以 `/` 结尾。
String? outputDirFromBuilderConfig(Map<String, dynamic> config) {
  final value = config['output'];
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  var out = trimmed.replaceAll('\\', '/');
  if (!out.endsWith('/')) {
    out = '$out/';
  }
  return out;
}
