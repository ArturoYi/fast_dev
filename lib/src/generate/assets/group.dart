import '../../config/config.dart';

/// 一条逻辑资源：剥掉主题/语言目录后的键，以及各变体的真实路径。
final class AssetVariantSet {
  /// 见各字段说明。
  const AssetVariantSet({
    required this.keyPath,
    required this.fallback,
    this.light,
    this.dark,
    this.locales = const {},
  });

  /// 用于建树和命名的路径（已去掉 light/dark/zh 等保留段）。
  final String keyPath;

  /// 无主题、无语言时的路径。若磁盘上只有 dark，则回退到 dark。
  final String fallback;

  /// 亮色变体；没有则为 `null`。
  final String? light;

  /// 暗色变体；没有则为 `null`。
  final String? dark;

  /// 语言码 → 该语言下的主题变体（不再嵌套语言）。
  final Map<String, AssetVariantSet> locales;

  /// 没有任何主题/语言变体，生成 AssetPath 即可。
  bool get isPlain => light == null && dark == null && locales.isEmpty;
}

/// [groupAssetVariants] 的返回值。
final class AssetVariantGroupResult {
  /// 见 [assets]、[warnings]。
  const AssetVariantGroupResult({required this.assets, required this.warnings});

  /// 按 [AssetVariantSet.keyPath] 排序。
  final List<AssetVariantSet> assets;

  /// 重复变体等非致命问题。
  final List<String> warnings;
}

/// 按配置把展开后的文件路径合成逻辑资源。
///
/// 保留目录可出现在路径任意一层；同一路径里主题与语言各最多一次。
/// `zh-CN` 与 `zh_CN` 视为同一语言。查找优先级在生成的
/// `AdaptiveAsset.resolve` 里实现：语言+主题 → 语言 → 主题 → 回退。
AssetVariantGroupResult groupAssetVariants({
  required List<String> posixPaths,
  required AssetsVariantsConfig variants,
}) {
  final paths = [...posixPaths]..sort();
  if (!variants.anyEnabled) {
    return AssetVariantGroupResult(
      assets: [
        for (final path in paths)
          AssetVariantSet(keyPath: path, fallback: path),
      ],
      warnings: const [],
    );
  }

  final light = _nameSet(
    variants.theme.enabled ? variants.theme.lightFolders : [],
  );
  final dark = _nameSet(
    variants.theme.enabled ? variants.theme.darkFolders : [],
  );
  final locales = _localeCanonical(
    variants.locale.enabled ? variants.locale.folders : [],
  );
  final warnings = <String>[];

  /// keyPath → locale? → theme? → file path. theme: null / light / dark.
  final buckets = <String, Map<String?, Map<String?, String>>>{};

  for (final path in paths) {
    final parsed = _stripReserved(
      path,
      light: light,
      dark: dark,
      locales: locales,
    );
    if (parsed.warnings.isNotEmpty) {
      warnings.addAll(parsed.warnings);
    }
    if (parsed.keyPath.isEmpty) {
      warnings.add('资源 `$path` 剥掉变体目录后为空，已跳过');
      continue;
    }
    final byLocale = buckets.putIfAbsent(parsed.keyPath, () => {});
    final byTheme = byLocale.putIfAbsent(parsed.locale, () => {});
    final themeKey = parsed.theme;
    final existing = byTheme[themeKey];
    if (existing != null && existing != path) {
      warnings.add(
        '资源 `${parsed.keyPath}` 的变体 (${parsed.locale ?? '-'}, ${themeKey ?? '-'}) '
        '同时存在 `$existing` 和 `$path`，已保留前者',
      );
      continue;
    }
    byTheme[themeKey] = path;
  }

  final assets = <AssetVariantSet>[];
  for (final entry in buckets.entries) {
    assets.add(
      _buildSet(
        keyPath: entry.key,
        byLocale: entry.value,
        localeConfig: variants.locale,
      ),
    );
  }
  assets.sort((a, b) => a.keyPath.compareTo(b.keyPath));
  return AssetVariantGroupResult(
    assets: assets,
    warnings: List.unmodifiable(warnings),
  );
}

Set<String> _nameSet(List<String> names) => {
  for (final name in names) name.toLowerCase(),
};

/// 规范化语言键 → 配置里的目录写法。
Map<String, String> _localeCanonical(List<String> folders) {
  final map = <String, String>{};
  for (final folder in folders) {
    map.putIfAbsent(normalizeLocaleFolderKey(folder), () => folder);
  }
  return map;
}

final class _ParsedPath {
  const _ParsedPath({
    required this.keyPath,
    required this.locale,
    required this.theme,
    required this.warnings,
  });

  final String keyPath;
  final String? locale;
  final String? theme;
  final List<String> warnings;
}

_ParsedPath _stripReserved(
  String posixPath, {
  required Set<String> light,
  required Set<String> dark,
  required Map<String, String> locales,
}) {
  final parts = posixPath.split('/')..removeWhere((part) => part.isEmpty);
  if (parts.isEmpty) {
    return const _ParsedPath(
      keyPath: '',
      locale: null,
      theme: null,
      warnings: [],
    );
  }
  final file = parts.removeLast();
  String? locale;
  String? theme;
  final warnings = <String>[];
  final kept = <String>[];

  for (final part in parts) {
    final lower = part.toLowerCase();
    final localeKey = normalizeLocaleFolderKey(part);
    if (locales.containsKey(localeKey)) {
      final canonical = locales[localeKey]!;
      if (locale != null) {
        warnings.add('路径 `$posixPath` 含多个语言目录，已使用 `$locale`，忽略 `$part`');
        continue;
      }
      locale = canonical;
      continue;
    }
    if (light.contains(lower)) {
      if (theme != null) {
        warnings.add('路径 `$posixPath` 含多个主题目录，已使用 `$theme`，忽略 `$part`');
        continue;
      }
      theme = 'light';
      continue;
    }
    if (dark.contains(lower)) {
      if (theme != null) {
        warnings.add('路径 `$posixPath` 含多个主题目录，已使用 `$theme`，忽略 `$part`');
        continue;
      }
      theme = 'dark';
      continue;
    }
    kept.add(part);
  }

  return _ParsedPath(
    keyPath: [...kept, file].join('/'),
    locale: locale,
    theme: theme,
    warnings: warnings,
  );
}

AssetVariantSet _buildSet({
  required String keyPath,
  required Map<String?, Map<String?, String>> byLocale,
  required LocaleVariantsConfig localeConfig,
}) {
  final rootSlot = byLocale[null] ?? {};
  final locales = <String, AssetVariantSet>{};
  for (final entry in byLocale.entries) {
    final code = entry.key;
    if (code == null) {
      continue;
    }
    locales[code] = _setFromSlot(keyPath: keyPath, slot: entry.value);
  }

  final root = _setFromSlot(keyPath: keyPath, slot: rootSlot, locales: locales);
  if (root.fallback.isNotEmpty) {
    return root;
  }
  // 没有无语言文件时，用 fallback 语言（或按名字排序的第一个）当作根节点，
  // 连同它的 light/dark，这样未匹配语言 / 未传 locale 时主题选择仍然有效。
  if (locales.isNotEmpty) {
    final chosen = _pickLocaleFallback(locales, localeConfig);
    return AssetVariantSet(
      keyPath: keyPath,
      fallback: chosen.fallback,
      light: chosen.light,
      dark: chosen.dark,
      locales: locales,
    );
  }
  return root;
}

AssetVariantSet _pickLocaleFallback(
  Map<String, AssetVariantSet> locales,
  LocaleVariantsConfig config,
) {
  if (config.enabled && config.fallback != kLocaleFallbackFile) {
    final key = normalizeLocaleFolderKey(config.fallback);
    for (final entry in locales.entries) {
      if (normalizeLocaleFolderKey(entry.key) == key) {
        return entry.value;
      }
    }
  }
  final keys = locales.keys.toList()..sort();
  return locales[keys.first]!;
}

AssetVariantSet _setFromSlot({
  required String keyPath,
  required Map<String?, String> slot,
  Map<String, AssetVariantSet> locales = const {},
}) {
  final unthemed = slot[null];
  final light = slot['light'];
  final dark = slot['dark'];
  final fallback = unthemed ?? light ?? dark ?? '';
  return AssetVariantSet(
    keyPath: keyPath,
    fallback: fallback,
    light: light,
    dark: dark,
    locales: locales,
  );
}
