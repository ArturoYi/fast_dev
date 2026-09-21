import 'package:yaml/yaml.dart';

import '../generate/exception.dart';
import 'manifest.dart';

export 'manifest.dart';

/// 从 `pubspec.yaml` 文本解析 Flutter 资源清单，不访问文件系统。
///
/// 关心 `name`、`flutter.assets` 和 `flutter.fonts`。
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
  final flutter = _readFlutter(root);
  final assetEntries = _readAssets(flutter, warnings);
  final fontFamilies = _readFonts(flutter, warnings);

  return FlutterManifestParseResult(
    manifest: FlutterManifest(
      packageName: packageName,
      assetEntries: List.unmodifiable(assetEntries),
      fontFamilies: List.unmodifiable(fontFamilies),
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

YamlMap? _readFlutter(YamlMap root) {
  final flutter = root['flutter'];
  if (flutter == null) {
    return null;
  }
  if (flutter is! YamlMap) {
    throw const GenerateException('pubspec.yaml 的 flutter: 必须是键值对 (Map)');
  }
  return flutter;
}

List<FlutterAssetEntry> _readAssets(YamlMap? flutter, List<String> warnings) {
  if (flutter == null) {
    return const [];
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

List<FlutterFontFamily> _readFonts(YamlMap? flutter, List<String> warnings) {
  if (flutter == null) {
    return const [];
  }

  final fonts = flutter['fonts'];
  if (fonts == null) {
    return const [];
  }
  if (fonts is! YamlList) {
    throw const GenerateException('pubspec.yaml 的 flutter.fonts 必须是列表');
  }

  final seen = <String>{};
  final result = <FlutterFontFamily>[];
  for (var i = 0; i < fonts.length; i++) {
    final item = fonts.nodes[i];
    final family = _readFontFamily(item, index: i, warnings: warnings);
    if (family == null) {
      continue;
    }
    if (!seen.add(family.family)) {
      warnings.add('flutter.fonts 重复的 family: `${family.family}`，已保留前者');
      continue;
    }
    result.add(family);
  }
  return result;
}

FlutterFontFamily? _readFontFamily(
  YamlNode item, {
  required int index,
  required List<String> warnings,
}) {
  if (item is! YamlMap) {
    throw GenerateException('flutter.fonts[$index] 必须是带 family 的键值对');
  }

  final familyValue = item['family'];
  if (familyValue is! String || familyValue.trim().isEmpty) {
    warnings.add('flutter.fonts[$index] 缺少非空的 family，已跳过');
    return null;
  }

  return FlutterFontFamily(
    family: familyValue.trim(),
    assetPaths: _readFontAssetPaths(
      item['fonts'],
      index: index,
      warnings: warnings,
    ),
  );
}

List<String> _readFontAssetPaths(
  Object? value, {
  required int index,
  required List<String> warnings,
}) {
  if (value == null) {
    return const [];
  }
  if (value is! YamlList) {
    warnings.add('flutter.fonts[$index].fonts 必须是列表，已忽略');
    return const [];
  }

  final seen = <String>{};
  final result = <String>[];
  for (var i = 0; i < value.length; i++) {
    final node = value.nodes[i];
    if (node is! YamlMap) {
      warnings.add('flutter.fonts[$index].fonts[$i] 必须是带 asset 的键值对，已跳过');
      continue;
    }
    final asset = node['asset'];
    if (asset is! String || asset.trim().isEmpty) {
      warnings.add('flutter.fonts[$index].fonts[$i] 缺少非空的 asset，已跳过');
      continue;
    }
    final path = asset.trim().replaceAll('\\', '/');
    if (!seen.add(path)) {
      continue;
    }
    result.add(path);
  }
  return List<String>.unmodifiable(result);
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
