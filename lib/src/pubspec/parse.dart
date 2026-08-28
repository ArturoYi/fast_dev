import 'package:yaml/yaml.dart';

import '../generate/exception.dart';
import 'manifest.dart';

export 'manifest.dart';

/// 从 `pubspec.yaml` 文本解析 Flutter 资源清单，不访问文件系统。
///
/// 只关心 `name` 和 `flutter.assets`。其它段留给后续生成器。
FlutterManifestParseResult parseFlutterManifest(
  String contents, {
  Uri? sourceUrl,
}) {
  final warnings = <String>[];
  if (contents.trim().isEmpty) {
    return FlutterManifestParseResult(
      manifest: const FlutterManifest(packageName: '', assetEntries: []),
      warnings: const ['pubspec.yaml 为空'],
    );
  }

  final YamlNode root;
  try {
    root = loadYamlNode(contents, sourceUrl: sourceUrl);
  } on YamlException catch (e) {
    throw GenerateException('pubspec.yaml 解析失败：${e.message}');
  }

  if (root is YamlScalar && root.value == null) {
    return FlutterManifestParseResult(
      manifest: const FlutterManifest(packageName: '', assetEntries: []),
      warnings: const ['pubspec.yaml 为空'],
    );
  }

  if (root is! YamlMap) {
    throw const GenerateException('pubspec.yaml 根节点必须是键值对 (Map)');
  }

  final packageName = _readName(root);
  final assetEntries = _readAssets(root, warnings);

  return FlutterManifestParseResult(
    manifest: FlutterManifest(
      packageName: packageName,
      assetEntries: List.unmodifiable(assetEntries),
    ),
    warnings: List.unmodifiable(warnings),
  );
}

String _readName(YamlMap root) {
  final value = root['name'];
  if (value is String) {
    return value;
  }
  return '';
}

List<FlutterAssetEntry> _readAssets(YamlMap root, List<String> warnings) {
  final flutter = root['flutter'];
  if (flutter == null) {
    return const [];
  }
  if (flutter is! YamlMap) {
    throw const GenerateException('pubspec.yaml 的 flutter: 必须是键值对 (Map)');
  }

  final assets = flutter['assets'];
  if (assets == null) {
    return const [];
  }
  if (assets is! YamlList) {
    throw const GenerateException('pubspec.yaml 的 flutter.assets 必须是列表');
  }

  final seen = <String>{};
  final result = <FlutterAssetEntry>[];
  for (var i = 0; i < assets.length; i++) {
    final item = assets.nodes[i];
    final entry = _readAssetEntry(item, index: i, warnings: warnings);
    if (entry == null) {
      continue;
    }
    if (!seen.add(entry.path)) {
      continue;
    }
    result.add(entry);
  }
  return result;
}

FlutterAssetEntry? _readAssetEntry(
  YamlNode item, {
  required int index,
  required List<String> warnings,
}) {
  final value = item.value;
  if (value is String) {
    final path = value.trim();
    if (path.isEmpty) {
      warnings.add('flutter.assets[$index] 是空字符串，已跳过');
      return null;
    }
    return FlutterAssetEntry(path: path.replaceAll('\\', '/'));
  }

  if (item is YamlMap) {
    final pathValue = item['path'];
    if (pathValue is! String || pathValue.trim().isEmpty) {
      throw GenerateException('flutter.assets[$index] 使用了 Map 形式，但缺少非空的 path');
    }
    final path = pathValue.trim().replaceAll('\\', '/');
    final flavors = _readStringList(item['flavors']);
    if (flavors.isNotEmpty) {
      warnings.add('资源 `$path` 声明了 flavors，v1 尚未支持 flavor，已按普通资源处理');
    }
    if (item['transformers'] != null) {
      warnings.add('资源 `$path` 声明了 transformers，v1 已忽略');
    }
    return FlutterAssetEntry(path: path, flavors: flavors);
  }

  throw GenerateException('flutter.assets[$index] 必须是路径字符串或带 path 的键值对');
}

List<String> _readStringList(Object? value) {
  if (value is! YamlList) {
    return const [];
  }
  final result = <String>[];
  for (final item in value) {
    if (item is String) {
      result.add(item);
    }
  }
  return result;
}
