import 'package:yaml/yaml.dart';

import 'config.dart';
import 'exception.dart';
import 'yaml_read.dart';

/// 从 YAML 文本解析配置，不访问文件系统。
///
/// CLI 走 `loadFastDevConfig`（读盘 + 找项目根）；之后的
/// `build_runner` Builder 应直接调用本函数，把构建步骤读到的
/// 字符串传进来，这样解析层不依赖 `dart:io` 也不依赖 `package:build`。
///
/// 合并规则：以 [FastDevConfig.defaults] 为底，YAML 出现过的字段覆盖。
ParseResult parseFastDevConfig(String contents, {Uri? sourceUrl}) {
  final warnings = <String>[];
  if (contents.trim().isEmpty) {
    warnings.add('配置文件为空，已使用全部默认值');
    return ParseResult(
      config: FastDevConfig.defaults,
      warnings: List.unmodifiable(warnings),
    );
  }

  final YamlNode root;
  try {
    root = loadYamlNode(contents, sourceUrl: sourceUrl);
  } on YamlException catch (e) {
    throw ConfigException('YAML 解析失败：${e.message}');
  }

  // `---` 空文档、或只有注释时，根节点是值为 null 的 scalar。
  if (root is YamlScalar && root.value == null) {
    warnings.add('配置文件为空，已使用全部默认值');
    return ParseResult(
      config: FastDevConfig.defaults,
      warnings: List.unmodifiable(warnings),
    );
  }

  if (root is! YamlMap) {
    throw ConfigException('配置根节点必须是 YAML 键值对 (Map)，请检查 $kConfigFileName');
  }

  yamlWarnUnknownKeys(
    map: root,
    known: kKnownRootConfigKeys,
    reserved: kReservedRootConfigKeys,
    prefix: '',
    warnings: warnings,
  );

  final version = _readVersion(root);
  final generate = _parseGenerate(
    yamlReadMap(root, 'generate', path: 'generate'),
    warnings,
  );

  return ParseResult(
    config: FastDevConfig(version: version, generate: generate),
    warnings: List.unmodifiable(warnings),
  );
}

/// [parseFastDevConfig] 的返回值：完整配置 + 非致命告警。
final class ParseResult {
  /// 见 [config]、[warnings]。
  const ParseResult({required this.config, required this.warnings});

  /// 已与默认值合并。
  final FastDevConfig config;

  /// 例如未识别的键。不含会导致失败的问题（那些会抛 [ConfigException]）。
  final List<String> warnings;
}

int _readVersion(YamlMap root) {
  final node = yamlNodeOrNull(root, 'version');
  if (node == null || (node is YamlScalar && node.value == null)) {
    return kCurrentConfigVersion;
  }
  final value = node.value;
  if (value is! int) {
    throw ConfigException.wrongType(
      path: 'version',
      expected: '整数',
      actual: value ?? 'null',
      line: node.span.start.line + 1,
      column: node.span.start.column + 1,
    );
  }
  if (value != kCurrentConfigVersion) {
    throw ConfigException(
      '不支持的配置版本 $value（当前工具只支持 version: $kCurrentConfigVersion）。'
      '请升级 fast_dev，或把 $kConfigFileName 里的 version 改回 $kCurrentConfigVersion。',
    );
  }
  return value;
}

GenerateConfig _parseGenerate(YamlMap? map, List<String> warnings) {
  const d = GenerateConfig.defaults;
  if (map == null) {
    return d;
  }
  yamlWarnUnknownKeys(
    map: map,
    known: kKnownGenerateConfigKeys,
    reserved: kReservedGenerateConfigKeys,
    prefix: 'generate',
    warnings: warnings,
  );

  final output = _normalizeOutput(
    yamlReadString(
      map,
      'output',
      defaultValue: d.output,
      path: 'generate.output',
    ),
  );
  final lineLength = yamlReadInt(
    map,
    'line_length',
    defaultValue: d.lineLength,
    path: 'generate.line_length',
  );
  if (lineLength <= 0) {
    throw const ConfigException('generate.line_length 必须是正整数');
  }

  return GenerateConfig(
    output: output,
    lineLength: lineLength,
    assets: _parseAssets(
      yamlReadMap(map, 'assets', path: 'generate.assets'),
      warnings,
    ),
  );
}

AssetsGenerateConfig _parseAssets(YamlMap? map, List<String> warnings) {
  const d = AssetsGenerateConfig.defaults;
  if (map == null) {
    return d;
  }
  yamlWarnUnknownKeys(
    map: map,
    known: const {'enabled', 'class_name', 'style', 'variants'},
    prefix: 'generate.assets',
    warnings: warnings,
  );
  return AssetsGenerateConfig(
    enabled: yamlReadBool(
      map,
      'enabled',
      defaultValue: d.enabled,
      path: 'generate.assets.enabled',
    ),
    className: _requireClassName(
      yamlReadString(
        map,
        'class_name',
        defaultValue: d.className,
        path: 'generate.assets.class_name',
      ),
      path: 'generate.assets.class_name',
    ),
    style: _parseStyle(
      yamlReadString(
        map,
        'style',
        defaultValue: d.style.name,
        path: 'generate.assets.style',
      ),
    ),
    variants: _parseVariants(
      yamlReadMap(map, 'variants', path: 'generate.assets.variants'),
      warnings,
    ),
  );
}

AssetsVariantsConfig _parseVariants(YamlMap? map, List<String> warnings) {
  const d = AssetsVariantsConfig.defaults;
  if (map == null) {
    return d;
  }
  yamlWarnUnknownKeys(
    map: map,
    known: const {'theme', 'locale'},
    prefix: 'generate.assets.variants',
    warnings: warnings,
  );
  final theme = _parseThemeVariants(
    yamlReadMap(map, 'theme', path: 'generate.assets.variants.theme'),
    warnings,
  );
  final locale = _parseLocaleVariants(
    yamlReadMap(map, 'locale', path: 'generate.assets.variants.locale'),
    warnings,
  );
  _rejectOverlappingVariantFolders(theme, locale);
  return AssetsVariantsConfig(theme: theme, locale: locale);
}

ThemeVariantsConfig _parseThemeVariants(YamlMap? map, List<String> warnings) {
  const d = ThemeVariantsConfig.defaults;
  if (map == null) {
    return d;
  }
  yamlWarnUnknownKeys(
    map: map,
    known: const {'enabled', 'folders'},
    prefix: 'generate.assets.variants.theme',
    warnings: warnings,
  );
  var light = d.lightFolders;
  var dark = d.darkFolders;
  final folders = yamlReadMap(
    map,
    'folders',
    path: 'generate.assets.variants.theme.folders',
  );
  if (folders != null) {
    yamlWarnUnknownKeys(
      map: folders,
      known: const {'light', 'dark'},
      prefix: 'generate.assets.variants.theme.folders',
      warnings: warnings,
    );
    light = _folderNames(
      yamlReadStringOrStringList(
        folders,
        'light',
        defaultValue: d.lightFolders,
        path: 'generate.assets.variants.theme.folders.light',
      ),
      path: 'generate.assets.variants.theme.folders.light',
    );
    dark = _folderNames(
      yamlReadStringOrStringList(
        folders,
        'dark',
        defaultValue: d.darkFolders,
        path: 'generate.assets.variants.theme.folders.dark',
      ),
      path: 'generate.assets.variants.theme.folders.dark',
    );
  }
  final lightSet = light.map((e) => e.toLowerCase()).toSet();
  final darkSet = dark.map((e) => e.toLowerCase()).toSet();
  final overlap = lightSet.intersection(darkSet);
  if (overlap.isNotEmpty) {
    throw ConfigException(
      'generate.assets.variants.theme 的 light 与 dark 不能使用相同目录名：${overlap.join('、')}',
    );
  }
  return ThemeVariantsConfig(
    enabled: yamlReadBool(
      map,
      'enabled',
      defaultValue: d.enabled,
      path: 'generate.assets.variants.theme.enabled',
    ),
    lightFolders: light,
    darkFolders: dark,
  );
}

LocaleVariantsConfig _parseLocaleVariants(YamlMap? map, List<String> warnings) {
  const d = LocaleVariantsConfig.defaults;
  if (map == null) {
    return d;
  }
  yamlWarnUnknownKeys(
    map: map,
    known: const {'enabled', 'folders', 'fallback'},
    prefix: 'generate.assets.variants.locale',
    warnings: warnings,
  );
  final enabled = yamlReadBool(
    map,
    'enabled',
    defaultValue: d.enabled,
    path: 'generate.assets.variants.locale.enabled',
  );
  final folders = _folderNames(
    yamlReadStringOrStringList(
      map,
      'folders',
      defaultValue: d.folders,
      path: 'generate.assets.variants.locale.folders',
    ),
    path: 'generate.assets.variants.locale.folders',
    localeAliases: true,
  );
  if (enabled && folders.isEmpty) {
    throw const ConfigException(
      'generate.assets.variants.locale.enabled 为 true 时必须列出 folders（例如 [zh, en]），'
      '避免把任意两字母目录当成语言。',
    );
  }
  final fallbackRaw = yamlReadString(
    map,
    'fallback',
    defaultValue: d.fallback,
    path: 'generate.assets.variants.locale.fallback',
  ).trim();
  if (fallbackRaw.isEmpty) {
    throw const ConfigException(
      'generate.assets.variants.locale.fallback 不能为空（用 file 或某个 folders 里的语言码）',
    );
  }
  final fallback = normalizeLocaleFolderKey(fallbackRaw) == kLocaleFallbackFile
      ? kLocaleFallbackFile
      : fallbackRaw;
  if (fallback != kLocaleFallbackFile && enabled) {
    final canonical = _canonicalLocaleFolder(fallback, folders);
    if (canonical == null) {
      throw ConfigException(
        'generate.assets.variants.locale.fallback 是 `$fallback`，但 folders 里没有这一项。'
        '改成 folders 中的语言码，或使用 file。',
      );
    }
    return LocaleVariantsConfig(
      enabled: enabled,
      folders: folders,
      fallback: canonical,
    );
  }
  return LocaleVariantsConfig(
    enabled: enabled,
    folders: folders,
    fallback: fallback,
  );
}

/// 在 [folders] 里找与 [name] 相同的语言目录（忽略大小写和 `-`/`_`）。
String? _canonicalLocaleFolder(String name, List<String> folders) {
  final key = normalizeLocaleFolderKey(name);
  for (final folder in folders) {
    if (normalizeLocaleFolderKey(folder) == key) {
      return folder;
    }
  }
  return null;
}

void _rejectOverlappingVariantFolders(
  ThemeVariantsConfig theme,
  LocaleVariantsConfig locale,
) {
  if (!theme.enabled || !locale.enabled) {
    return;
  }
  final overlap = <String>{};
  for (final themeName in [...theme.lightFolders, ...theme.darkFolders]) {
    for (final localeName in locale.folders) {
      if (themeName.toLowerCase() == localeName.toLowerCase() ||
          normalizeLocaleFolderKey(themeName) ==
              normalizeLocaleFolderKey(localeName)) {
        overlap.add(localeName);
      }
    }
  }
  if (overlap.isNotEmpty) {
    throw ConfigException(
      '主题目录与语言目录不能重名：${overlap.join('、')}。'
      '请改 folders，否则无法判断 dark/zh 是主题还是语言。',
    );
  }
}

final _densityFolder = RegExp(r'^\d+(\.\d+)?x$');

List<String> _folderNames(
  List<String> raw, {
  required String path,
  bool localeAliases = false,
}) {
  final result = <String>[];
  final seen = <String>{};
  for (final item in raw) {
    final name = item.trim();
    _validateFolderName(name, path: path);
    final key = localeAliases
        ? normalizeLocaleFolderKey(name)
        : name.toLowerCase();
    if (!seen.add(key)) {
      continue;
    }
    result.add(name);
  }
  return List<String>.unmodifiable(result);
}

void _validateFolderName(String name, {required String path}) {
  if (name.isEmpty ||
      name.contains('/') ||
      name.contains('\\') ||
      name == '.' ||
      name == '..') {
    throw ConfigException('$path 不是合法的单层目录名，收到 `$name`');
  }
  if (_densityFolder.hasMatch(name)) {
    throw ConfigException('$path 不能使用密度目录名 `$name`（与 2.0x 冲突）');
  }
}

/// 统一成 posix 分隔符，并保证以 `/` 结尾，后面拼文件名时不必再判断。
String _normalizeOutput(String raw) {
  var out = raw.trim().replaceAll('\\', '/');
  if (out.isEmpty) {
    throw const ConfigException('generate.output 不能为空');
  }
  if (!out.endsWith('/')) {
    out = '$out/';
  }
  return out;
}

AssetStyle _parseStyle(String raw) {
  return switch (raw) {
    'nested' => AssetStyle.nested,
    'camel' => AssetStyle.camel,
    'snake' => AssetStyle.snake,
    _ => throw ConfigException(
      'generate.assets.style 只能是 nested、camel 或 snake，收到 `$raw`',
    ),
  };
}

/// 生成代码里会把这个名字当 class，所以必须是合法标识符。
String _requireClassName(String name, {required String path}) {
  if (!_dartIdentifier.hasMatch(name)) {
    throw ConfigException('$path 必须是合法的 Dart 标识符，收到 `$name`');
  }
  return name;
}

final _dartIdentifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
