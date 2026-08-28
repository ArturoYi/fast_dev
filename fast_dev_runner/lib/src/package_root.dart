import 'dart:io';
import 'dart:isolate';

import 'package:build/build.dart';
import 'package:fast_dev/fast_dev.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// 解析当前 [BuildStep] 对应包的文件系统根目录。
///
/// `build_runner` 可能在 workspace 根目录启动，不能假定 [Directory.current]
/// 就是正在构建的包。
Future<String?> resolvePackageRoot(BuildStep buildStep) async {
  final packageName = buildStep.inputId.package;

  final fromBuildStep = _filePath(
    (await buildStep.packageConfig)[packageName]?.root,
  );
  if (fromBuildStep != null) {
    return p.normalize(fromBuildStep);
  }

  final runtimeConfig = await _loadRuntimePackageConfig();
  final fromRuntime = _filePath(runtimeConfig?[packageName]?.root);
  if (fromRuntime != null) {
    return p.normalize(fromRuntime);
  }

  return _findPackageRootFromCwd(packageName);
}

String? _filePath(Uri? uri) {
  if (uri == null || uri.scheme != 'file') {
    return null;
  }
  try {
    return uri.toFilePath();
  } on UnsupportedError {
    return null;
  }
}

Future<PackageConfig?> _loadRuntimePackageConfig() async {
  final uri = Isolate.packageConfigSync;
  if (uri == null) {
    return null;
  }
  try {
    return loadPackageConfigUri(uri);
  } on Object {
    return null;
  }
}

Future<String?> _findPackageRootFromCwd(String packageName) async {
  var dir = Directory.current.absolute;
  while (true) {
    final packageConfigFile = File(
      p.join(dir.path, '.dart_tool', 'package_config.json'),
    );
    if (packageConfigFile.existsSync()) {
      try {
        final config = await loadPackageConfigUri(packageConfigFile.uri);
        final root = _filePath(config[packageName]?.root);
        if (root != null) {
          return p.normalize(root);
        }
      } on Object {
        // 继续往上找。
      }
    }

    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      try {
        final parsed = parseFlutterManifest(pubspec.readAsStringSync());
        if (parsed.manifest.packageName == packageName) {
          return p.normalize(dir.path);
        }
      } on Object {
        // 不是合法 pubspec 时忽略。
      }
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}
