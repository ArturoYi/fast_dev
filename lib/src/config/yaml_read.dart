import 'package:yaml/yaml.dart';

import 'exception.dart';

/// 从 [YamlMap] 取出名为 [key] 的节点；没有这个键则返回 `null`。
///
/// [YamlMap.nodes] 的键是 [YamlNode]，不能直接用字符串去 `[]` 取带 span
/// 的节点，所以要按 `key.value` 扫一遍。
YamlNode? yamlNodeOrNull(YamlMap map, String key) {
  for (final entry in map.nodes.entries) {
    final name = _scalarName(entry.key);
    if (name == key) {
      return entry.value;
    }
  }
  return null;
}

/// 把本层里不认识的键记进 [warnings]，不中断解析。
///
/// 策略：未知字段 **告警后忽略**，方便以后加键；旧工具遇到新文件不会
/// 直接炸，只是用不到新功能。和 [version] 不认识就失败是反过来的——
/// 版本是破坏性变更的闸门，字段是扩展点。
///
/// [reserved] 里的键同样忽略，但文案标明「已预留、尚未实现」，
/// 以免用户把计划中的段当成拼写错误。
void yamlWarnUnknownKeys({
  required YamlMap map,
  required Set<String> known,
  Set<String> reserved = const {},
  required String prefix,
  required List<String> warnings,
}) {
  for (final entry in map.nodes.entries) {
    final name = _scalarName(entry.key);
    if (name == null || known.contains(name)) {
      continue;
    }
    final path = prefix.isEmpty ? name : '$prefix.$name';
    if (reserved.contains(name)) {
      warnings.add('配置项 `$path` 已预留，当前版本尚未实现，已忽略');
      continue;
    }
    warnings.add('未识别的配置项 `$path`，已忽略');
  }
}

/// 读布尔值；键不存在时返回 [defaultValue]。
bool yamlReadBool(
  YamlMap map,
  String key, {
  required bool defaultValue,
  required String path,
}) {
  final node = yamlNodeOrNull(map, key);
  if (node == null || _isNullScalar(node)) {
    return defaultValue;
  }
  final value = node.value;
  if (value is! bool) {
    throw ConfigException.wrongType(
      path: path,
      expected: '布尔值',
      actual: value ?? 'null',
      line: _line(node),
      column: _column(node),
    );
  }
  return value;
}

/// 读整数；键不存在时返回 [defaultValue]。
///
/// YAML 里 `80.0` 是浮点，这里故意不接受，避免行宽被悄悄截断。
int yamlReadInt(
  YamlMap map,
  String key, {
  required int defaultValue,
  required String path,
}) {
  final node = yamlNodeOrNull(map, key);
  if (node == null || _isNullScalar(node)) {
    return defaultValue;
  }
  final value = node.value;
  if (value is! int) {
    throw ConfigException.wrongType(
      path: path,
      expected: '整数',
      actual: value ?? 'null',
      line: _line(node),
      column: _column(node),
    );
  }
  return value;
}

/// 读字符串；键不存在时返回 [defaultValue]。
String yamlReadString(
  YamlMap map,
  String key, {
  required String defaultValue,
  required String path,
}) {
  final node = yamlNodeOrNull(map, key);
  if (node == null || _isNullScalar(node)) {
    return defaultValue;
  }
  final value = node.value;
  if (value is! String) {
    throw ConfigException.wrongType(
      path: path,
      expected: '字符串',
      actual: value ?? 'null',
      line: _line(node),
      column: _column(node),
    );
  }
  return value;
}

/// 读字符串列表；键不存在时返回 [defaultValue]（默认列表原样引用即可）。
///
/// 一旦 YAML 里写了这个键，即使是 `[]`，也视为用户要覆盖默认值，
/// **不会**再和默认列表合并。
List<String> yamlReadStringList(
  YamlMap map,
  String key, {
  required List<String> defaultValue,
  required String path,
}) {
  final node = yamlNodeOrNull(map, key);
  if (node == null || _isNullScalar(node)) {
    return defaultValue;
  }
  if (node is! YamlList) {
    throw ConfigException.wrongType(
      path: path,
      expected: '字符串列表',
      actual: node.value ?? 'null',
      line: _line(node),
      column: _column(node),
    );
  }
  final result = <String>[];
  for (var i = 0; i < node.nodes.length; i++) {
    final item = node.nodes[i];
    final value = item.value;
    if (value is! String) {
      throw ConfigException.wrongType(
        path: '$path[$i]',
        expected: '字符串',
        actual: value as Object? ?? 'null',
        line: _line(item),
        column: _column(item),
      );
    }
    result.add(value);
  }
  return List<String>.unmodifiable(result);
}

/// 读字符串或字符串列表。`light: light` 和 `light: [light]` 都接受。
List<String> yamlReadStringOrStringList(
  YamlMap map,
  String key, {
  required List<String> defaultValue,
  required String path,
}) {
  final node = yamlNodeOrNull(map, key);
  if (node == null || _isNullScalar(node)) {
    return defaultValue;
  }
  final value = node.value;
  if (value is String) {
    return List<String>.unmodifiable([value]);
  }
  if (node is YamlList) {
    return yamlReadStringList(map, key, defaultValue: defaultValue, path: path);
  }
  throw ConfigException.wrongType(
    path: path,
    expected: '字符串或字符串列表',
    actual: value ?? 'null',
    line: _line(node),
    column: _column(node),
  );
}

/// 读嵌套 Map；键不存在或值为 null 时返回 `null`（调用方接着用默认子配置）。
YamlMap? yamlReadMap(YamlMap map, String key, {required String path}) {
  final node = yamlNodeOrNull(map, key);
  if (node == null || _isNullScalar(node)) {
    return null;
  }
  if (node is! YamlMap) {
    throw ConfigException.wrongType(
      path: path,
      expected: '键值对 (Map)',
      actual: node.value ?? 'null',
      line: _line(node),
      column: _column(node),
    );
  }
  return node;
}

String? _scalarName(YamlNode key) {
  if (key is YamlScalar) {
    return key.value?.toString();
  }
  return key.toString();
}

bool _isNullScalar(YamlNode node) => node is YamlScalar && node.value == null;

int? _line(YamlNode node) {
  final line = node.span.start.line;
  return line < 0 ? null : line + 1;
}

int? _column(YamlNode node) {
  final column = node.span.start.column;
  return column < 0 ? null : column + 1;
}
