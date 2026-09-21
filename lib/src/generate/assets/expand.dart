import 'dart:io';

import 'package:path/path.dart' as p;

import '../../pubspec/manifest.dart';

/// [expandFlutterAssets] 的返回值。
final class AssetExpandResult {
  /// 见 [paths]、[warnings]。
  const AssetExpandResult({required this.paths, required this.warnings});

  /// 已去重、按路径排序的 posix 相对路径。
  final List<String> paths;

  /// 找不到文件、flavor 等非致命问题。
  final List<String> warnings;
}

/// 把 `flutter.assets` 条目展开成具体文件路径。
///
/// 目录会**递归**子文件夹，因此 pubspec 里只写 `assets/` 也能扫到
/// `assets/images/`、`assets/data/`。
/// [exclude] 里的路径不会进生成结果（给后续生成器排除自己的清单文件用）。
AssetExpandResult expandFlutterAssets({
  required String packageRoot,
  required List<FlutterAssetEntry> entries,
  Iterable<String> exclude = const [],
}) {
  final warnings = <String>[];
  final raw = <String>{};
  final root = Directory(packageRoot).absolute.path;
  final visited = <String>{};

  for (final entry in entries) {
    final absolute = p.normalize(p.join(root, entry.path));
    if (FileSystemEntity.isDirectorySync(absolute)) {
      _addDirectory(Directory(absolute), root, raw, visited);
    } else if (FileSystemEntity.isFileSync(absolute)) {
      raw.add(_posixRelative(absolute, root));
    } else {
      warnings.add('找不到资源 `${entry.path}`，已跳过');
    }
  }

  final normalized = normalizeDiscoveredAssetPaths(
    posixPaths: raw,
    exclude: exclude,
  );
  return AssetExpandResult(
    paths: normalized.paths,
    warnings: List.unmodifiable([...warnings, ...normalized.warnings]),
  );
}

/// 把已经列出来的文件路径做成和 [expandFlutterAssets] 相同的结果。
///
/// `build_runner` 通过 `BuildStep.findAssets` 拿到路径后走这里，这样
/// 规范化（点文件、排除名单）不必再绑 `dart:io`。
AssetExpandResult normalizeDiscoveredAssetPaths({
  required Iterable<String> posixPaths,
  Iterable<String> exclude = const [],
}) {
  final skipped = {for (final item in exclude) posixAssetKey(item)};
  final paths = <String>{};
  for (final raw in posixPaths) {
    final relative = posixAssetKey(raw);
    if (relative.isEmpty) {
      continue;
    }
    if (_isIgnored(p.basename(relative))) {
      continue;
    }
    if (skipped.contains(relative)) {
      continue;
    }
    paths.add(relative);
  }
  final sorted = paths.toList()..sort();
  return AssetExpandResult(paths: sorted, warnings: const []);
}

/// 统一成 posix、去掉首尾空白和末尾 `/`，便于当排除名单的键。
String posixAssetKey(String path) {
  var out = path.trim().replaceAll('\\', '/');
  while (out.endsWith('/')) {
    out = out.substring(0, out.length - 1);
  }
  return out;
}

void _addDirectory(
  Directory directory,
  String root,
  Set<String> paths,
  Set<String> visited,
) {
  final canonical = p.normalize(directory.absolute.path);
  if (!visited.add(canonical)) {
    return;
  }

  final entities = directory.listSync(followLinks: false);
  for (final entity in entities) {
    if (entity is File) {
      paths.add(_posixRelative(entity.path, root));
    } else if (entity is Directory) {
      _addDirectory(entity, root, paths, visited);
    }
  }
}

bool _isIgnored(String basename) {
  if (basename.startsWith('.')) {
    return true;
  }
  if (basename == 'Thumbs.db') {
    return true;
  }
  switch (p.extension(basename)) {
    case '.swp':
    case '.DS_Store':
      return true;
  }
  return false;
}

String _posixRelative(String filePath, String root) {
  final relative = p.relative(filePath, from: root);
  return p.posix.joinAll(p.split(relative));
}
