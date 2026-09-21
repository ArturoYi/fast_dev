import '../../config/config.dart';
import '../../pubspec/manifest.dart';
import '../assets/naming.dart';
import '../exception.dart';
import '../format.dart';

/// 生成文件名，写在 [GenerateConfig.output] 下面。
const kFontsGeneratedFileName = 'fonts.gen.dart';

/// 把 `flutter.fonts` 的族名生成 `fonts.gen.dart` 源码。
///
/// [families] 为空（或去重后为空）时返回 `null`，调用方不应写文件。
/// 重复族名写入 [warnings]（若提供）。
String? generateFontsSource({
  required FontsGenerateConfig config,
  required int lineLength,
  required List<FlutterFontFamily> families,
  String packageName = '',
  List<String>? warnings,
}) {
  final unique = <FlutterFontFamily>[];
  final seen = <String>{};
  for (final family in families) {
    final name = family.family.trim();
    if (name.isEmpty) {
      continue;
    }
    if (!seen.add(name)) {
      warnings?.add('flutter.fonts 重复的 family: `$name`，已保留前者');
      continue;
    }
    unique.add(family);
  }
  if (unique.isEmpty) {
    return null;
  }

  final packageEnabled = config.package && packageName.isNotEmpty;
  if (config.package && packageName.isEmpty) {
    warnings?.add(
      'generate.fonts.package 为 true，但 pubspec.yaml 没有 name，已按应用模式生成',
    );
  }

  final familyNames = [for (final item in unique) item.family];
  final identifiers = _fontIdentifiers(
    familyNames,
    reservePackage: packageEnabled,
    reserveFallbacks: config.fallbacks.isNotEmpty,
  );
  final fallbackIds = _fallbackIdentifiers(
    fallbacks: config.fallbacks,
    families: familyNames,
    identifiers: identifiers,
  );

  final buf = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// dart format width=$lineLength')
    ..writeln()
    ..writeln('// coverage:ignore-file')
    ..writeln(
      '// ignore_for_file: type=lint, unused_element, deprecated_member_use',
    )
    ..writeln()
    ..writeln('abstract final class ${config.className} {');

  if (packageEnabled) {
    buf
      ..writeln('  /// 声明这些字体的 package。消费方直接用成员，不要再传 package。')
      ..writeln('  static const String package = ${_quote(packageName)};')
      ..writeln();
  }

  for (var i = 0; i < unique.length; i++) {
    final family = unique[i].family;
    final value = packageEnabled
        ? "'packages/\$package/${_escape(family)}'"
        : _quote(family);
    buf
      ..writeln('  /// Font family: $family')
      ..writeln('  static const String ${identifiers[i]} = $value;')
      ..writeln();
  }

  if (fallbackIds.isNotEmpty) {
    buf
      ..writeln('  /// 交给 `TextStyle.fontFamilyFallback`。顺序与配置一致。')
      ..writeln('  static const List<String> fallbacks = [');
    for (final id in fallbackIds) {
      buf.writeln('    $id,');
    }
    buf
      ..writeln('  ];')
      ..writeln();
  }

  buf.writeln('}');
  return formatGeneratedDart(buf.toString(), lineLength: lineLength);
}

List<String> _fontIdentifiers(
  List<String> families, {
  required bool reservePackage,
  required bool reserveFallbacks,
}) {
  final inputs = [
    if (reservePackage) const AssetNameInput(source: 'package', isFile: false),
    if (reserveFallbacks)
      const AssetNameInput(source: 'fallbacks', isFile: false),
    for (final family in families)
      AssetNameInput(source: family, isFile: false),
  ];
  final names = uniqueDartIdentifiers(inputs, style: camelCase);
  var skip = 0;
  if (reservePackage) {
    skip++;
  }
  if (reserveFallbacks) {
    skip++;
  }
  return names.sublist(skip);
}

/// 把配置里的 family 名收成已生成成员的标识符；对不上就失败。
List<String> _fallbackIdentifiers({
  required List<String> fallbacks,
  required List<String> families,
  required List<String> identifiers,
}) {
  final byFamily = <String, String>{
    for (var i = 0; i < families.length; i++) families[i]: identifiers[i],
  };
  final result = <String>[];
  final seen = <String>{};
  for (final raw in fallbacks) {
    final name = raw.trim();
    if (name.isEmpty || !seen.add(name)) {
      continue;
    }
    final id = byFamily[name];
    if (id == null) {
      throw GenerateException(
        'generate.fonts.fallbacks 里的 `$name` 不在 flutter.fonts 的 family 中。',
      );
    }
    result.add(id);
  }
  return result;
}

String _quote(String value) => "'${_escape(value)}'";

String _escape(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
}
