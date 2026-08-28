import '../../config/config.dart';
import 'group.dart';
import 'tree.dart';

/// 把资源树发射成 Dart 源码（尚未 dart_style）。
String emitAssets({
  required AssetGroup root,
  required int lineLength,
  required AssetsVariantsConfig variants,
}) {
  final pathType = _uniqueHelperName(root.className, 'AssetPath');
  final adaptiveType = _uniqueHelperName(root.className, 'AdaptiveAsset');
  final scopeType = _uniqueHelperName(root.className, 'AssetResolveScope');
  final needsAdaptive = root.hasAdaptiveLeaves;

  final buf = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// dart format width=$lineLength')
    ..writeln()
    ..writeln('// coverage:ignore-file')
    ..writeln(
      '// ignore_for_file: type=lint, unused_element, deprecated_member_use',
    )
    ..writeln();

  if (needsAdaptive) {
    buf
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln();
  }

  buf
    ..writeln(
      'extension type const $pathType(String path) implements String {}',
    )
    ..writeln();

  if (needsAdaptive) {
    _writeResolveScope(buf, scopeType: scopeType, adaptiveType: adaptiveType);
    buf.writeln();
    _writeAdaptiveAsset(
      buf: buf,
      adaptiveType: adaptiveType,
      pathType: pathType,
      scopeType: scopeType,
      localeFallback:
          variants.locale.enabled &&
              variants.locale.fallback != kLocaleFallbackFile
          ? variants.locale.fallback
          : null,
    );
    buf.writeln();
  }

  final nested = <AssetGroup>[];
  _collectNested(root, nested);
  for (final group in nested) {
    _writeNestedClass(buf, group, pathType, adaptiveType);
    buf.writeln();
  }
  _writeRootClass(buf, root, pathType, adaptiveType);
  return buf.toString();
}

String _uniqueHelperName(String className, String helper) {
  if (className == helper) {
    return 'Fd$helper';
  }
  return helper;
}

void _collectNested(AssetGroup group, List<AssetGroup> out) {
  for (final child in group.groups) {
    out.add(child);
    _collectNested(child, out);
  }
}

void _writeRootClass(
  StringBuffer buf,
  AssetGroup root,
  String pathType,
  String adaptiveType,
) {
  buf.writeln('abstract final class ${root.className} {');
  for (final file in root.files) {
    buf
      ..writeln('  /// File path: ${file.variant.fallback}')
      ..writeln(
        '  static const ${_leafType(file, pathType, adaptiveType)} ${file.identifier} = ${_leafValue(file, pathType, adaptiveType)};',
      )
      ..writeln();
  }
  for (final group in root.groups) {
    buf
      ..writeln('  /// Directory path: ${group.posixPath}')
      ..writeln(
        '  static const ${group.className} ${group.identifier} = ${group.className}();',
      )
      ..writeln();
  }
  buf.writeln('}');
}

void _writeNestedClass(
  StringBuffer buf,
  AssetGroup group,
  String pathType,
  String adaptiveType,
) {
  buf
    ..writeln('class ${group.className} {')
    ..writeln('  const ${group.className}();')
    ..writeln();
  for (final file in group.files) {
    buf
      ..writeln('  /// File path: ${file.variant.fallback}')
      ..writeln(
        '  ${_leafType(file, pathType, adaptiveType)} get ${file.identifier} => const ${_leafValue(file, pathType, adaptiveType)};',
      )
      ..writeln();
  }
  for (final child in group.groups) {
    buf
      ..writeln('  /// Directory path: ${child.posixPath}')
      ..writeln(
        '  ${child.className} get ${child.identifier} => const ${child.className}();',
      )
      ..writeln();
  }
  buf.writeln('}');
}

String _leafType(AssetLeaf leaf, String pathType, String adaptiveType) {
  return leaf.variant.isPlain ? pathType : adaptiveType;
}

String _leafValue(AssetLeaf leaf, String pathType, String adaptiveType) {
  if (leaf.variant.isPlain) {
    return '$pathType(${_quote(leaf.variant.fallback)})';
  }
  return _adaptiveLiteral(leaf.variant, pathType, adaptiveType);
}

String _adaptiveLiteral(
  AssetVariantSet variant,
  String pathType,
  String adaptiveType,
) {
  final args = <String>['fallback: $pathType(${_quote(variant.fallback)})'];
  if (variant.light != null) {
    args.add('light: $pathType(${_quote(variant.light!)})');
  }
  if (variant.dark != null) {
    args.add('dark: $pathType(${_quote(variant.dark!)})');
  }
  if (variant.locales.isNotEmpty) {
    final entries = variant.locales.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final map = StringBuffer('{');
    for (final entry in entries) {
      map.write(
        '${_quote(entry.key)}: ${_adaptiveLiteral(entry.value, pathType, adaptiveType)}, ',
      );
    }
    map.write('}');
    args.add('locales: $map');
  }
  return '$adaptiveType(${args.join(', ')})';
}

void _writeResolveScope(
  StringBuffer buf, {
  required String scopeType,
  required String adaptiveType,
}) {
  buf.write('''
/// 覆盖子树里 [$adaptiveType.of] 用的主题和语言。
///
/// `brightness` / `locale` 为 null 时，继续读 Theme 和 Localizations。
class $scopeType extends InheritedWidget {
  const $scopeType({
    super.key,
    this.brightness,
    this.locale,
    required super.child,
  });

  /// 强制使用的亮度；null 表示不覆盖。
  final Brightness? brightness;

  /// 强制使用的语言；null 表示不覆盖。
  final Locale? locale;

  /// 最近的覆盖；没有则返回 null。
  static $scopeType? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<$scopeType>();
  }

  @override
  bool updateShouldNotify($scopeType oldWidget) {
    return brightness != oldWidget.brightness || locale != oldWidget.locale;
  }
}
''');
}

void _writeAdaptiveAsset({
  required StringBuffer buf,
  required String adaptiveType,
  required String pathType,
  required String scopeType,
  required String? localeFallback,
}) {
  final fallbackLiteral = localeFallback == null
      ? 'null'
      : _quote(localeFallback);
  buf.write('''
/// 同一逻辑资源的主题 / 语言变体。
///
/// 解析顺序：语言+主题 → 仅语言 → 仅主题 → [fallback]。
///
/// ```dart
/// Image.asset(assets.logo.of(context));
/// assets.logo.resolve(brightness: Brightness.dark, locale: Locale('zh'));
/// ```
class $adaptiveType {
  const $adaptiveType({
    required this.fallback,
    this.light,
    this.dark,
    this.locales = const {},
  });

  /// 配置 `locale.fallback` 指向的语言码；为 `file` 时是 `null`。
  static const String? localeFallback = $fallbackLiteral;

  /// 无主题、无语言时的路径。
  final $pathType fallback;

  /// 亮色变体。
  final $pathType? light;

  /// 暗色变体。
  final $pathType? dark;

  /// 语言码到该语言下的主题变体。
  final Map<String, $adaptiveType> locales;

  /// 无 [BuildContext] 时显式传入主题和语言。
  ///
  /// 省略 [locale] 只按主题解析根节点，不会套用 [localeFallback]。
  $pathType resolve({Brightness? brightness, Locale? locale}) {
    return _nodeFor(locale)._select(brightness);
  }

  /// 从 [Theme]、[Localizations] 读取；可被 [$scopeType] 覆盖。
  $pathType of(BuildContext context) {
    final scope = $scopeType.maybeOf(context);
    return resolve(
      brightness: scope?.brightness ?? Theme.of(context).brightness,
      locale: scope?.locale ?? Localizations.maybeLocaleOf(context),
    );
  }

  $adaptiveType _nodeFor(Locale? locale) {
    if (locales.isEmpty || locale == null) {
      return this;
    }
    final country = locale.countryCode;
    if (country != null && country.isNotEmpty) {
      final matched =
          _localeMatch('\${locale.languageCode}_\$country') ??
          _localeMatch('\${locale.languageCode}-\$country');
      if (matched != null) {
        return matched;
      }
    }
    final script = locale.scriptCode;
    if (script != null && script.isNotEmpty) {
      final matched = _localeMatch('\${locale.languageCode}_\$script');
      if (matched != null) {
        return matched;
      }
    }
    final byLanguage = _localeMatch(locale.languageCode);
    if (byLanguage != null) {
      return byLanguage;
    }
''');
  buf.write(_localeFallbackBlock(localeFallback));
  buf.write('''
    return this;
  }

  $adaptiveType? _localeMatch(String key) {
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

  $pathType _select(Brightness? brightness) {
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
''');
}

String _localeFallbackBlock(String? localeFallback) {
  if (localeFallback == null) {
    return '';
  }
  return '''
    final fallbackLocale = _localeMatch(localeFallback!);
    if (fallbackLocale != null) {
      return fallbackLocale;
    }
''';
}

String _quote(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
  return "'$escaped'";
}
