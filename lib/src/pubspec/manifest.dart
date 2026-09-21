/// 从用户项目 `pubspec.yaml` 里抽出、生成器真正用得到的那一小段。
///
/// 打包清单仍以 Flutter 为准；本类型只是方便后面展开目录、读字体族。
final class FlutterManifest {
  /// 见各字段说明。
  const FlutterManifest({
    required this.packageName,
    required this.assetEntries,
    this.fontFamilies = const [],
  });

  /// `name:`，没有则空字符串。
  final String packageName;

  /// `flutter.assets` 的原始条目（尚未展开成文件）。
  final List<FlutterAssetEntry> assetEntries;

  /// `flutter.fonts` 里已去重的字体族（按首次出现保留）。
  final List<FlutterFontFamily> fontFamilies;
}

/// `flutter.fonts` 里的一族：`family` 以及它声明的文件。
final class FlutterFontFamily {
  /// 见各字段说明。
  const FlutterFontFamily({required this.family, this.assetPaths = const []});

  /// `family:`，用于 `TextStyle.fontFamily`。
  final String family;

  /// 该族下的 `asset:` 路径，已去重。生成常量只需要 [family]。
  final List<String> assetPaths;
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
