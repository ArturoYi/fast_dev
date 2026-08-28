import '../../config/config.dart';
import 'group.dart';

/// 与生成代码 `AdaptiveAsset.resolve` 相同的路径选择。
///
/// [brightness] 只认 `light` / `dark`；其它或 `null` 用 [AssetVariantSet.fallback]。
/// [localeFallback] 为 `null` 表示配置 `file`：未匹配语言时留在根节点。
/// [locale] 为 `null` 时**不**套用 [localeFallback]，只在根节点上选主题。
String selectAdaptivePath(
  AssetVariantSet variant, {
  String? brightness,
  AssetLocaleQuery? locale,
  String? localeFallback,
}) {
  final node = pickAdaptiveNode(
    variant,
    locale: locale,
    localeFallback: localeFallback,
  );
  return selectAdaptiveTheme(node, brightness);
}

/// `Locale` 的纯 Dart 等价物，供生成器单测而不依赖 Flutter。
final class AssetLocaleQuery {
  /// 见各字段说明。
  const AssetLocaleQuery({
    required this.languageCode,
    this.countryCode,
    this.scriptCode,
  });

  /// 对应 Flutter `Locale.languageCode`。
  final String languageCode;

  /// 对应 Flutter `Locale.countryCode`。
  final String? countryCode;

  /// 对应 Flutter `Locale.scriptCode`。
  final String? scriptCode;
}

/// 选语言节点。`locale == null` 或没有语言变体时返回 [variant] 自身。
AssetVariantSet pickAdaptiveNode(
  AssetVariantSet variant, {
  AssetLocaleQuery? locale,
  String? localeFallback,
}) {
  if (variant.locales.isEmpty || locale == null) {
    return variant;
  }
  final country = locale.countryCode;
  if (country != null && country.isNotEmpty) {
    final matched =
        _localeMatch(variant, '${locale.languageCode}_$country') ??
        _localeMatch(variant, '${locale.languageCode}-$country');
    if (matched != null) {
      return matched;
    }
  }
  final script = locale.scriptCode;
  if (script != null && script.isNotEmpty) {
    final matched = _localeMatch(variant, '${locale.languageCode}_$script');
    if (matched != null) {
      return matched;
    }
  }
  final byLanguage = _localeMatch(variant, locale.languageCode);
  if (byLanguage != null) {
    return byLanguage;
  }
  if (localeFallback != null) {
    final fallbackLocale = _localeMatch(variant, localeFallback);
    if (fallbackLocale != null) {
      return fallbackLocale;
    }
  }
  return variant;
}

/// 在已选语言节点上按亮度取路径。
String selectAdaptiveTheme(AssetVariantSet variant, String? brightness) {
  if (brightness == 'dark') {
    return variant.dark ?? variant.fallback;
  }
  if (brightness == 'light') {
    return variant.light ?? variant.fallback;
  }
  return variant.fallback;
}

AssetVariantSet? _localeMatch(AssetVariantSet variant, String key) {
  final exact = variant.locales[key];
  if (exact != null) {
    return exact;
  }
  final normalized = normalizeLocaleFolderKey(key);
  for (final entry in variant.locales.entries) {
    if (normalizeLocaleFolderKey(entry.key) == normalized) {
      return entry.value;
    }
  }
  return null;
}
