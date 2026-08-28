// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=100

// coverage:ignore-file
// ignore_for_file: type=lint, unused_element, deprecated_member_use

import 'package:flutter/material.dart';

extension type const AssetPath(String path) implements String {}

/// 覆盖子树里 [AdaptiveAsset.of] 用的主题和语言。
///
/// `brightness` / `locale` 为 null 时，继续读 Theme 和 Localizations。
class AssetResolveScope extends InheritedWidget {
  const AssetResolveScope({super.key, this.brightness, this.locale, required super.child});

  /// 强制使用的亮度；null 表示不覆盖。
  final Brightness? brightness;

  /// 强制使用的语言；null 表示不覆盖。
  final Locale? locale;

  /// 最近的覆盖；没有则返回 null。
  static AssetResolveScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AssetResolveScope>();
  }

  @override
  bool updateShouldNotify(AssetResolveScope oldWidget) {
    return brightness != oldWidget.brightness || locale != oldWidget.locale;
  }
}

/// 同一逻辑资源的主题 / 语言变体。
///
/// 解析顺序：语言+主题 → 仅语言 → 仅主题 → [fallback]。
///
/// ```dart
/// Image.asset(assets.logo.of(context));
/// assets.logo.resolve(brightness: Brightness.dark, locale: Locale('zh'));
/// ```
class AdaptiveAsset {
  const AdaptiveAsset({required this.fallback, this.light, this.dark, this.locales = const {}});

  /// 配置 `locale.fallback` 指向的语言码；为 `file` 时是 `null`。
  static const String? localeFallback = null;

  /// 无主题、无语言时的路径。
  final AssetPath fallback;

  /// 亮色变体。
  final AssetPath? light;

  /// 暗色变体。
  final AssetPath? dark;

  /// 语言码到该语言下的主题变体。
  final Map<String, AdaptiveAsset> locales;

  /// 无 [BuildContext] 时显式传入主题和语言。
  ///
  /// 省略 [locale] 只按主题解析根节点，不会套用 [localeFallback]。
  AssetPath resolve({Brightness? brightness, Locale? locale}) {
    return _nodeFor(locale)._select(brightness);
  }

  /// 从 [Theme]、[Localizations] 读取；可被 [AssetResolveScope] 覆盖。
  AssetPath of(BuildContext context) {
    final scope = AssetResolveScope.maybeOf(context);
    return resolve(
      brightness: scope?.brightness ?? Theme.of(context).brightness,
      locale: scope?.locale ?? Localizations.maybeLocaleOf(context),
    );
  }

  AdaptiveAsset _nodeFor(Locale? locale) {
    if (locales.isEmpty || locale == null) {
      return this;
    }
    final country = locale.countryCode;
    if (country != null && country.isNotEmpty) {
      final matched =
          _localeMatch('${locale.languageCode}_$country') ??
          _localeMatch('${locale.languageCode}-$country');
      if (matched != null) {
        return matched;
      }
    }
    final script = locale.scriptCode;
    if (script != null && script.isNotEmpty) {
      final matched = _localeMatch('${locale.languageCode}_$script');
      if (matched != null) {
        return matched;
      }
    }
    final byLanguage = _localeMatch(locale.languageCode);
    if (byLanguage != null) {
      return byLanguage;
    }
    return this;
  }

  AdaptiveAsset? _localeMatch(String key) {
    final exact = locales[key];
    if (exact != null) {
      return exact;
    }
    final normalized = key.toLowerCase().replaceAll('-', '_');
    for (final entry in locales.entries) {
      if (entry.key.toLowerCase().replaceAll('-', '_') == normalized) {
        return entry.value;
      }
    }
    return null;
  }

  AssetPath _select(Brightness? brightness) {
    if (brightness == Brightness.dark) {
      return dark ?? fallback;
    }
    if (brightness == Brightness.light) {
      return light ?? fallback;
    }
    return fallback;
  }

  @override
  String toString() => fallback;
}

class $ExampleAssetsData {
  const $ExampleAssetsData();

  /// File path: assets/data/hello.json
  AssetPath get hello => const AssetPath('assets/data/hello.json');
}

class $ExampleAssetsImages {
  const $ExampleAssetsImages();

  /// File path: assets/images/logo.svg
  AdaptiveAsset get logo => const AdaptiveAsset(
    fallback: AssetPath('assets/images/logo.svg'),
    dark: AssetPath('assets/images/dark/logo.svg'),
    locales: {
      'en': AdaptiveAsset(fallback: AssetPath('assets/images/en/logo.svg')),
      'zh': AdaptiveAsset(fallback: AssetPath('assets/images/zh/logo.svg')),
    },
  );
}

abstract final class ExampleAssets {
  /// Directory path: assets/data
  static const $ExampleAssetsData data = $ExampleAssetsData();

  /// Directory path: assets/images
  static const $ExampleAssetsImages images = $ExampleAssetsImages();
}
