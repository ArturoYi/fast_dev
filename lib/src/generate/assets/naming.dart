import 'package:path/path.dart' as p;

/// 不能当变量名的关键字（Dart 保留字 + await/yield）。
const invalidIdentifiers = <String>{
  'assert',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

/// 是否是合法且非保留字的变量名。
bool isValidVariableIdentifier(String identifier) =>
    !invalidIdentifiers.contains(identifier) && isValidIdentifier(identifier);

/// 是否像 Dart 标识符（字母或 `_` 开头）。
bool isValidIdentifier(String identifier) =>
    RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(identifier);

/// 把任意字符串收成合法标识符原料：非法字符变 `_`，不能以字母开头则加 [prefix]。
String convertToIdentifier(String raw, {String prefix = 'a'}) {
  var identifier = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  if (identifier.isEmpty) {
    identifier = prefix;
  }
  if (!identifier.startsWith(RegExp(r'[A-Za-z]'))) {
    identifier = '$prefix$identifier';
  }
  return identifier;
}

/// `foo_bar` / `foo/bar` → `fooBar`。
String camelCase(String input) {
  final words = _intoWords(input);
  if (words.isEmpty) {
    return 'a';
  }
  final buf = StringBuffer(words[0].toLowerCase());
  for (var i = 1; i < words.length; i++) {
    final word = words[i];
    buf
      ..write(word.substring(0, 1).toUpperCase())
      ..write(word.substring(1).toLowerCase());
  }
  return buf.toString();
}

/// `foo/bar` → `foo_bar`。
String snakeCase(String input) {
  final words = _intoWords(input);
  if (words.isEmpty) {
    return 'a';
  }
  return words.map((w) => w.toLowerCase()).join('_');
}

/// 首字母大写，其余不动（已经是 camelCase 时用来拼类名）。
String capitalize(String input) {
  if (input.isEmpty) {
    return input;
  }
  return '${input[0].toUpperCase()}${input.substring(1)}';
}

/// 参与重名消解的一项：文件用路径或文件名，目录只用段名。
final class AssetNameInput {
  /// 见 [source]、[isFile]。
  const AssetNameInput({required this.source, required this.isFile});

  /// 用来生成标识符的原始串（嵌套风格是 basename，扁平风格是去掉 assets/ 的路径）。
  final String source;

  /// 文件才允许「加上扩展名再试一次」。
  final bool isFile;
}

/// 给一组兄弟节点分配互不冲突的标识符。
///
/// 策略与 flutter_gen 相同：先裸名，再带扩展名，再追加 `_`。
List<String> uniqueDartIdentifiers(
  List<AssetNameInput> inputs, {
  required String Function(String) style,
}) {
  if (inputs.isEmpty) {
    return const [];
  }

  final needExtension = List<bool>.filled(inputs.length, false);
  final suffix = List<String>.filled(inputs.length, '');

  String nameAt(int i) {
    var source = inputs[i].source;
    if (inputs[i].isFile && !needExtension[i]) {
      source = p.posix.withoutExtension(source);
    }
    return style(convertToIdentifier(source)) + suffix[i];
  }

  for (var attempt = 0; attempt < 64; attempt++) {
    final names = [for (var i = 0; i < inputs.length; i++) nameAt(i)];
    final groups = <String, List<int>>{};
    for (var i = 0; i < names.length; i++) {
      groups.putIfAbsent(names[i], () => []).add(i);
    }

    var addedExtension = false;
    for (final entry in groups.entries) {
      final valid = isValidVariableIdentifier(entry.key);
      if (entry.value.length == 1 && valid) {
        continue;
      }
      for (final i in entry.value) {
        if (inputs[i].isFile && !needExtension[i]) {
          needExtension[i] = true;
          addedExtension = true;
        }
      }
    }
    if (addedExtension) {
      continue;
    }

    var addedSuffix = false;
    for (final entry in groups.entries) {
      final valid = isValidVariableIdentifier(entry.key);
      if (entry.value.length == 1 && valid) {
        continue;
      }
      var extra = '';
      for (var k = 0; k < entry.value.length; k++) {
        final i = entry.value[k];
        if (k == 0 && valid) {
          continue;
        }
        extra = '${extra}_';
        suffix[i] += extra;
        addedSuffix = true;
      }
    }
    if (!addedSuffix) {
      return names;
    }
  }

  return [for (var i = 0; i < inputs.length; i++) nameAt(i)];
}

List<String> _intoWords(String path) {
  const symbols = {' ', '.', '/', '_', r'\', '-', '@'};
  final upper = RegExp(r'[A-Z]');
  final lower = RegExp(r'[a-z]');
  final buf = StringBuffer();
  final words = <String>[];
  final hasLower = path.contains(lower);

  for (var i = 0; i < path.length; i++) {
    final char = path[i];
    final next = i + 1 == path.length ? null : path[i + 1];
    if (symbols.contains(char)) {
      continue;
    }
    buf.write(char);
    final end =
        next == null ||
        (hasLower && upper.hasMatch(next)) ||
        symbols.contains(next);
    if (end) {
      words.add(buf.toString());
      buf.clear();
    }
  }
  return words;
}
