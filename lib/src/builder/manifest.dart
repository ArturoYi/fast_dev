import 'dart:convert';

/// Builder 写到 cache 的中间结果，供 post-process 落到源码树。
///
/// 真正的 `.gen.dart` 路径来自配置，无法事先写进 `build_extensions`，
/// 所以先固定写出这一份清单。
final class FastDevManifest {
  /// 见各字段说明。
  const FastDevManifest({
    required this.packageName,
    required this.packageRoot,
    required this.outputs,
  });

  /// 当前 schema。升级字段时再加版本分支。
  static const schemaVersion = 1;

  /// 从 JSON 还原。字段缺失或类型不对时当空清单。
  factory FastDevManifest.fromJson(Map<String, Object?> json) {
    final outputs = <ManifestOutput>[];
    final rawOutputs = json['outputs'];
    if (rawOutputs is List) {
      for (final item in rawOutputs) {
        if (item is Map<String, Object?>) {
          outputs.add(ManifestOutput.fromJson(item));
        } else if (item is Map) {
          outputs.add(ManifestOutput.fromJson(item.cast<String, Object?>()));
        }
      }
    }
    return FastDevManifest(
      packageName: json['package_name'] as String? ?? '',
      packageRoot: json['package_root'] as String? ?? '',
      outputs: List.unmodifiable(outputs),
    );
  }

  /// 从 JSON 文本还原。
  factory FastDevManifest.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      return const FastDevManifest(
        packageName: '',
        packageRoot: '',
        outputs: [],
      );
    }
    return FastDevManifest.fromJson(decoded.cast<String, Object?>());
  }

  /// 正在构建的包名。
  final String packageName;

  /// 包根目录的文件系统路径，post-process 用它写源码。
  final String packageRoot;

  /// 要落到磁盘的生成文件。
  final List<ManifestOutput> outputs;

  /// 编码为 JSON 文本。
  String toJsonString() => jsonEncode(toJson());

  /// JSON 对象。
  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'package_name': packageName,
    'package_root': packageRoot,
    'outputs': [for (final output in outputs) output.toJson()],
  };
}

/// 清单里的一份生成文件。
final class ManifestOutput {
  /// 见各字段说明。
  const ManifestOutput({required this.path, required this.contents});

  /// 从 JSON 还原。
  factory ManifestOutput.fromJson(Map<String, Object?> json) {
    return ManifestOutput(
      path: json['path'] as String? ?? '',
      contents: json['contents'] as String? ?? '',
    );
  }

  /// 相对 [FastDevManifest.packageRoot] 的 posix 路径。
  final String path;

  /// 文件全文。
  final String contents;

  /// JSON 对象。
  Map<String, Object?> toJson() => {'path': path, 'contents': contents};
}
