import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/load.dart';
import '../pubspec/parse.dart';
import 'assets/expand.dart';
import 'assets/generator.dart';
import 'exception.dart';
import 'plan.dart';

/// [runGenerate] 的摘要，给 `fast_dev gen` 打印。
final class GenRunResult {
  /// 见各字段说明。
  const GenRunResult({
    required this.written,
    required this.skipped,
    required this.warnings,
  });

  /// 相对项目根写出的文件。
  final List<String> written;

  /// 关掉或没有输入的生成器。
  final List<String> skipped;

  /// 配置加载、pubspec、展开阶段的告警。
  final List<String> warnings;

  /// CLI 用的可读摘要。
  String format() {
    final buf = StringBuffer();
    if (written.isNotEmpty) {
      buf.writeln('已生成：');
      for (final file in written) {
        buf.writeln('  $file');
      }
    }
    if (skipped.isNotEmpty) {
      buf.writeln('已跳过：');
      for (final item in skipped) {
        buf.writeln('  $item');
      }
    }
    buf.writeln('警告：');
    if (warnings.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final warning in warnings) {
        buf.writeln('  - $warning');
      }
    }
    return buf.toString().trimRight();
  }
}

/// 按配置跑已注册的生成器。当前内置是 assets 与 fonts。
///
/// [generators] 默认是 [builtInGenerators]。
GenRunResult runGenerate(
  ConfigLoadResult loaded, {
  List<Generator>? generators,
}) {
  final packageRoot = loaded.packageRoot;
  if (packageRoot == null) {
    throw const GenerateException(
      '找不到项目根目录（pubspec.yaml）。请在 Dart/Flutter 项目内运行，或去掉 --config 后再试。',
    );
  }

  final pubspecFile = File(p.join(packageRoot.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw GenerateException('找不到 pubspec.yaml：${pubspecFile.path}');
  }

  final parsed = parseFlutterManifest(
    pubspecFile.readAsStringSync(),
    sourceUrl: pubspecFile.uri,
  );

  final active = generators ?? builtInGenerators;
  AssetExpandResult? expanded;
  if (loaded.config.generate.assets.enabled &&
      active.any((generator) => generator.id == AssetsGenerator.generatorId)) {
    expanded = expandFlutterAssets(
      packageRoot: packageRoot.path,
      entries: parsed.manifest.assetEntries,
    );
  }

  final plan = planGenerate(
    config: loaded.config,
    parsed: parsed,
    expanded: expanded,
    generators: active,
  );

  final written = <String>[];
  for (final output in plan.outputs) {
    final file = File(p.join(packageRoot.path, output.relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(output.contents);
    written.add(output.relativePath);
  }

  return GenRunResult(
    written: List.unmodifiable(written),
    skipped: plan.skipped,
    warnings: List.unmodifiable([...loaded.warnings, ...plan.warnings]),
  );
}
