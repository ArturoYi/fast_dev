import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';
import 'exception.dart';
import 'parse.dart';

/// 从磁盘加载配置：先定位 Dart/Flutter 包根，再读旁边的
/// [kConfigFileName]。
///
/// 这是 **CLI** 入口。解析规则全在 [parseFastDevConfig]；本文件
/// 只负责找文件、读成字符串。之后接 `build_runner` 时不要走这里，
/// 用 Builder 提供的字节调用 [parseFastDevConfig]，以免配置层
/// 绑死 `dart:io`。
///
/// 查找顺序：
/// 1. [configPath]（对应 `--config`）若给出：该文件必须存在，失败即抛错，
///    不会回退到默认值——用户明确指定了路径， silently 用默认值会掩盖拼写错误。
/// 2. 否则从 [fromDirectory]（默认当前目录）向上找 `pubspec.yaml`，
///    在同一目录找 [kConfigFileName]；没有配置文件则用内置默认值并告警。
ConfigLoadResult loadFastDevConfig({
  String? fromDirectory,
  String? configPath,
}) {
  final start = Directory(fromDirectory ?? Directory.current.path).absolute;

  File? file;
  Directory? packageRoot;

  if (configPath != null) {
    file = _resolvePath(configPath, start);
    if (!file.existsSync()) {
      throw ConfigException(
        '找不到配置文件：${file.path}\n'
        '已经指定 --config，因此不会回退到内置默认值（避免路径写错却看起来成功）。\n'
        '若要使用默认值，去掉 -c / --config 后再运行。',
      );
    }
    // 优先从配置文件所在目录往上找包根，这样在子目录里 `--config ../x.yaml`
    // 仍能对上正确的项目。
    packageRoot = findPackageRoot(file.parent) ?? findPackageRoot(start);
  } else {
    packageRoot = findPackageRoot(start);
    if (packageRoot == null) {
      throw ConfigException(
        '从 ${start.path} 向上未找到 pubspec.yaml。'
        '请在 Dart/Flutter 项目内运行，或使用 --config 指定 $kConfigFileName。',
      );
    }
    final candidate = File(p.join(packageRoot.path, kConfigFileName));
    if (candidate.existsSync()) {
      file = candidate;
    }
  }

  if (file == null) {
    return ConfigLoadResult(
      config: FastDevConfig.defaults,
      warnings: List.unmodifiable(['未找到 $kConfigFileName，已使用内置默认值']),
      packageRoot: packageRoot,
      configFile: null,
    );
  }

  final parsed = parseFastDevConfig(
    file.readAsStringSync(),
    sourceUrl: file.uri,
  );
  return ConfigLoadResult(
    config: parsed.config,
    warnings: parsed.warnings,
    packageRoot: packageRoot,
    configFile: file,
  );
}

/// 从 [start] 开始沿父目录查找，直到出现 `pubspec.yaml`。
///
/// 到文件系统根仍没有则返回 `null`，由调用方决定是报错还是仅告警。
Directory? findPackageRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    final pubspec = File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      return current;
    }
    final parent = current.parent;
    // Directory.parent 在根目录（`/` 或 `C:\`）时路径与自身相同。
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}

/// 一次加载的定位信息 + 解析结果，方便 CLI 打印「从哪读的」。
final class ConfigLoadResult {
  /// 见各字段说明。
  const ConfigLoadResult({
    required this.config,
    required this.warnings,
    required this.packageRoot,
    required this.configFile,
  });

  /// 已与默认值合并的配置。
  final FastDevConfig config;

  /// 解析期告警（未知字段、空文件等）。
  final List<String> warnings;

  /// 含 `pubspec.yaml` 的目录；仅 `--config` 且附近没有 pubspec 时可能为 `null`。
  final Directory? packageRoot;

  /// 实际读到的配置文件；用了内置默认值时为 `null`。
  final File? configFile;

  /// 是否没有读到任何配置文件。
  bool get usedDefaults => configFile == null;

  /// 给 `fast_dev config` 用的可读摘要。
  String format() {
    final buf = StringBuffer()
      ..writeln('package_root: ${packageRoot?.path ?? '(未找到)'}')
      ..writeln('config_file: ${configFile?.path ?? '(无，使用内置默认值)'}')
      ..writeln('warnings:');
    if (warnings.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final warning in warnings) {
        buf.writeln('  - $warning');
      }
    }
    buf
      ..writeln()
      ..writeln('resolved:')
      ..write(_indent(config.toPrettyString(), '  '));
    return buf.toString().trimRight();
  }
}

File _resolvePath(String configPath, Directory start) {
  if (p.isAbsolute(configPath)) {
    return File(configPath);
  }
  return File(p.join(start.path, configPath));
}

String _indent(String text, String indent) {
  final buf = StringBuffer();
  for (final line in text.split('\n')) {
    buf.writeln('$indent$line');
  }
  return buf.toString();
}
