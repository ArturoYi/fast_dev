import '../generator.dart';
import 'generate.dart';

/// 内置的 fonts 生成器：把 `flutter.fonts` 写成 `fonts.gen.dart`。
final class FontsGenerator implements Generator {
  /// 无状态，可 const。
  const FontsGenerator();

  /// 与配置段 `generate.fonts` 对齐。
  static const String generatorId = 'fonts';

  @override
  String get id => generatorId;

  @override
  GeneratorResult generate(GeneratorContext context) {
    final generate = context.config.generate;
    if (!generate.fonts.enabled) {
      return const GeneratorResult(
        skipped: 'fonts（generate.fonts.enabled: false）',
      );
    }

    final warnings = <String>[];
    final source = generateFontsSource(
      config: generate.fonts,
      lineLength: generate.lineLength,
      families: context.parsed.manifest.fontFamilies,
      packageName: context.parsed.manifest.packageName,
      warnings: warnings,
    );
    if (source == null) {
      return GeneratorResult(
        skipped: 'fonts（pubspec 中没有可用的 flutter.fonts）',
        warnings: warnings,
      );
    }

    return GeneratorResult(
      outputs: [
        PlannedOutput(
          relativePath: '${context.outputDirectory}$kFontsGeneratedFileName',
          contents: source,
        ),
      ],
      warnings: warnings,
    );
  }
}
