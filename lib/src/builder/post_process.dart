import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'assets_builder.dart';
import 'manifest.dart';

/// 上一轮 post-process 写出过的相对路径，用来删掉过期文件。
const kOwnedOutputsFileName = 'owned_outputs.json';

/// 把清单里的生成文件写进包的源码树。
///
/// 输出路径随配置变化，不能作为普通 Builder 的声明输出，所以在 post-process
/// 里用 `dart:io` 落盘；这也避免和 CLI 已经写出的同名文件打架。
final class FastDevPostProcessBuilder extends PostProcessBuilder {
  @override
  Iterable<String> get inputExtensions => const [kFastDevManifestPath];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    final manifest = FastDevManifest.fromJsonString(
      await buildStep.readInputAsString(),
    );
    if (manifest.packageRoot.isEmpty) {
      log.warning('fast_dev：无法解析包根目录，跳过写出生成文件。');
      return;
    }
    materializeManifest(manifest);
  }
}

/// 按清单写出文件，并删除本工具上一轮拥有、这一轮不再生成的路径。
void materializeManifest(FastDevManifest manifest) {
  final root = Directory(manifest.packageRoot).absolute.path;
  final ownerFile = File(
    p.join(root, '.dart_tool', 'fast_dev', kOwnedOutputsFileName),
  );
  final previous = _readOwnedPaths(ownerFile);
  final next = {
    for (final output in manifest.outputs)
      if (output.path.isNotEmpty) p.posix.joinAll(p.split(output.path)),
  };

  for (final stale in previous.difference(next)) {
    final absolute = p.normalize(p.join(root, stale));
    if (!_isWithinPackage(root, absolute)) {
      continue;
    }
    final file = File(absolute);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  for (final output in manifest.outputs) {
    if (output.path.isEmpty) {
      continue;
    }
    final absolute = p.normalize(p.join(root, output.path));
    if (!_isWithinPackage(root, absolute)) {
      log.warning('fast_dev：拒绝写出包外路径 `${output.path}`');
      continue;
    }
    final file = File(absolute);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(output.contents);
  }

  ownerFile.parent.createSync(recursive: true);
  final ordered = next.toList()..sort();
  ownerFile.writeAsStringSync(jsonEncode({'paths': ordered}));
}

Set<String> _readOwnedPaths(File ownerFile) {
  if (!ownerFile.existsSync()) {
    return {};
  }
  try {
    final decoded = jsonDecode(ownerFile.readAsStringSync());
    if (decoded is! Map) {
      return {};
    }
    final paths = decoded['paths'];
    if (paths is! List) {
      return {};
    }
    return {
      for (final path in paths)
        if (path is String && path.isNotEmpty) path,
    };
  } on Object {
    return {};
  }
}

bool _isWithinPackage(String packageRoot, String candidate) {
  final root = p.normalize(packageRoot);
  final path = p.normalize(candidate);
  return path == root || p.isWithin(root, path);
}
