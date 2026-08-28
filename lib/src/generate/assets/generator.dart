import '../generator.dart';
import 'expand.dart';
import 'generate.dart';

/// 内置的 assets 生成器：把 `flutter.assets` 写成 `assets.gen.dart`。
final class AssetsGenerator implements Generator {
  /// 无状态，可 const。
  const AssetsGenerator();

  /// 与配置段 `generate.assets` 对齐。
  static const String generatorId = 'assets';

  @override
  String get id => generatorId;

  @override
  GeneratorResult generate(GeneratorContext context) {
    final generate = context.config.generate;
    if (!generate.assets.enabled) {
      return const GeneratorResult(
        skipped: 'assets（generate.assets.enabled: false）',
      );
    }

    final assets =
        context.expandedAssets ??
        const AssetExpandResult(paths: [], warnings: []);
    final warnings = [...assets.warnings];
    final source = generateAssetsSource(
      config: generate.assets,
      lineLength: generate.lineLength,
      assetPaths: assets.paths,
      warnings: warnings,
    );
    if (source == null) {
      return GeneratorResult(
        skipped: 'assets（pubspec 中没有可用的 flutter.assets）',
        warnings: warnings,
      );
    }

    return GeneratorResult(
      outputs: [
        PlannedOutput(
          relativePath: '${context.outputDirectory}$kAssetsGeneratedFileName',
          contents: source,
        ),
      ],
      warnings: warnings,
    );
  }
}
