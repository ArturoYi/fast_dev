import 'dart:io';

import 'package:build/build.dart';
import 'package:fast_dev/fast_dev.dart';
import 'package:path/path.dart' as p;

import 'compose.dart';
import 'discover.dart';
import 'manifest.dart';
import 'package_root.dart';

/// 中间清单的固定相对路径，对应 `build_extensions`。
const kFastDevManifestPath = '.fast_dev.manifest.json';

/// 读配置 / pubspec / 资源，在内存里生成源码，只写出一份 cache 清单。
final class FastDevBuilder implements Builder {
  /// 用 [BuilderOptions] 构造。`options.output` 可覆盖配置里的输出目录。
  FastDevBuilder(this.options);

  /// 来自应用 `build.yaml` 的 `builders.*.options`。
  final BuilderOptions options;

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$package$': [kFastDevManifestPath],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final packageName = buildStep.inputId.package;
    final packageRoot = await resolvePackageRoot(buildStep) ?? '';

    final pubspecContents = await _readPackageFile(
      buildStep: buildStep,
      relativePath: 'pubspec.yaml',
      packageRoot: packageRoot,
    );
    if (pubspecContents == null) {
      await _writeManifest(
        buildStep,
        FastDevManifest(
          packageName: packageName,
          packageRoot: packageRoot,
          outputs: const [],
        ),
      );
      return;
    }

    final configContents = await _readPackageFile(
      buildStep: buildStep,
      relativePath: kConfigFileName,
      packageRoot: packageRoot,
    );

    AssetExpandResult? disk;
    final parsedForExpand = parseFlutterManifest(pubspecContents);
    final parsedConfigForExpand = configContents == null
        ? FastDevConfig.defaults
        : parseFastDevConfig(configContents).config;
    if (packageRoot.isNotEmpty &&
        parsedConfigForExpand.generate.assets.enabled) {
      disk = expandFlutterAssets(
        packageRoot: packageRoot,
        entries: parsedForExpand.manifest.assetEntries,
      );
    }

    final graphPaths = parsedConfigForExpand.generate.assets.enabled
        ? await discoverGraphAssetPaths(
            buildStep: buildStep,
            entries: parsedForExpand.manifest.assetEntries,
          )
        : const <String>[];

    final composed = composeGenerate(
      packageName: packageName,
      packageRoot: packageRoot,
      pubspecContents: pubspecContents,
      configContents: configContents,
      graphPaths: graphPaths,
      disk: disk,
      outputOverride: outputDirFromBuilderConfig(options.config),
    );

    for (final warning in composed.warnings) {
      log.warning(warning);
    }
    for (final skipped in composed.skipped) {
      log.info('已跳过：$skipped');
    }

    await _writeManifest(buildStep, composed.manifest);
  }
}

Future<String?> _readPackageFile({
  required BuildStep buildStep,
  required String relativePath,
  required String packageRoot,
}) async {
  final id = AssetId(buildStep.inputId.package, relativePath);
  if (await buildStep.canRead(id)) {
    return buildStep.readAsString(id);
  }
  if (packageRoot.isEmpty) {
    return null;
  }
  final file = File(p.join(packageRoot, relativePath));
  if (!file.existsSync()) {
    return null;
  }
  return file.readAsStringSync();
}

Future<void> _writeManifest(
  BuildStep buildStep,
  FastDevManifest manifest,
) {
  return buildStep.writeAsString(
    AssetId(buildStep.inputId.package, kFastDevManifestPath),
    manifest.toJsonString(),
  );
}
