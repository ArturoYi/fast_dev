import 'package:build/build.dart';
import 'package:fast_dev/fast_dev.dart';
import 'package:glob/glob.dart';

/// 用 [BuildStep.findAssets] 收集 pubspec 条目对应的文件，并 [BuildStep.digest]
/// 登记依赖，这样资源在 build graph 里时增量重建才有效。
Future<List<String>> discoverGraphAssetPaths({
  required BuildStep buildStep,
  required List<FlutterAssetEntry> entries,
}) async {
  final package = buildStep.inputId.package;
  final found = <String>{};
  for (final entry in entries) {
    final trimmed = posixAssetKey(entry.path);
    if (trimmed.isEmpty) {
      continue;
    }
    final fileId = AssetId(package, trimmed);
    if (await buildStep.canRead(fileId)) {
      await buildStep.digest(fileId);
      found.add(fileId.path);
      continue;
    }
    await for (final id in buildStep.findAssets(Glob('$trimmed/**'))) {
      await buildStep.digest(id);
      found.add(id.path);
    }
  }
  return found.toList()..sort();
}

/// 合并磁盘展开与 build graph 发现的路径，缺条目时告警。
///
/// 默认 build_runner 源集合不含 `assets/`，所以 graph 经常是空的，这时以
/// 磁盘为准；`testBuilder` 则相反，只有 graph。两边并集才能两种入口都对。
AssetExpandResult mergeDiscoveredAssets({
  required List<FlutterAssetEntry> entries,
  required List<String> graphPaths,
  AssetExpandResult? disk,
  Iterable<String> exclude = const [],
}) {
  final fromGraph = normalizeDiscoveredAssetPaths(
    posixPaths: graphPaths,
    exclude: exclude,
  );
  final paths = <String>{...fromGraph.paths, ...?disk?.paths}.toList()..sort();
  final warnings = <String>[];
  for (final entry in entries) {
    final key = posixAssetKey(entry.path);
    final found = paths.any((path) => path == key || path.startsWith('$key/'));
    if (!found) {
      warnings.add('找不到资源 `${entry.path}`，已跳过');
    }
  }
  return AssetExpandResult(
    paths: List.unmodifiable(paths),
    warnings: List.unmodifiable(warnings),
  );
}
