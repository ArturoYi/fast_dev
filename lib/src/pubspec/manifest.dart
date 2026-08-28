/// 从用户项目 `pubspec.yaml` 里抽出、生成器真正用得到的那一小段。
///
/// 打包清单仍以 Flutter 为准；本类型只是方便后面展开目录。
/// 字体族等字段等对应生成器接入后再往这里加。
final class FlutterManifest {
  /// 见各字段说明。
  const FlutterManifest({
    required this.packageName,
    required this.assetEntries,
  });

  /// `name:`，没有则空字符串。
  final String packageName;

  /// `flutter.assets` 的原始条目（尚未展开成文件）。
  final List<FlutterAssetEntry> assetEntries;
}

/// `flutter.assets` 里的一条：普通字符串路径，或带 `path` 的 Map。
final class FlutterAssetEntry {
  /// 见各字段说明。
  const FlutterAssetEntry({required this.path, this.flavors = const []});

  /// 相对项目根。目录常以 `/` 结尾，是否真是目录要看磁盘。
  final String path;

  /// Flutter flavor。v1 不按 flavor 拆文件，只用来告警。
  final List<String> flavors;
}

/// [parseFlutterManifest] 的返回值。
final class FlutterManifestParseResult {
  /// 见 [manifest]、[warnings]。
  const FlutterManifestParseResult({
    required this.manifest,
    required this.warnings,
  });

  /// 解析结果。没有 `flutter:` 时 [FlutterManifest.assetEntries] 为空。
  final FlutterManifest manifest;

  /// 非致命问题，例如用了 v1 还不支持的 flavors。
  final List<String> warnings;
}
