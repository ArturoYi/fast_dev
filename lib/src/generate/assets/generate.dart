import '../../config/config.dart';
import '../format.dart';
import 'emit.dart';
import 'group.dart';
import 'tree.dart';

/// 生成文件名，写在 [GenerateConfig.output] 下面。
const kAssetsGeneratedFileName = 'assets.gen.dart';

/// 把已展开的资源路径生成 `assets.gen.dart` 源码。
///
/// [assetPaths] 为空时返回 `null`，调用方不应写文件。
/// 分组告警写入 [warnings]（若提供）。
String? generateAssetsSource({
  required AssetsGenerateConfig config,
  required int lineLength,
  required List<String> assetPaths,
  List<String>? warnings,
}) {
  if (assetPaths.isEmpty) {
    return null;
  }
  final grouped = groupAssetVariants(
    posixPaths: assetPaths,
    variants: config.variants,
  );
  warnings?.addAll(grouped.warnings);
  if (grouped.assets.isEmpty) {
    return null;
  }
  final tree = buildAssetTree(
    assets: grouped.assets,
    style: config.style,
    className: config.className,
  );
  final raw = emitAssets(
    root: tree,
    lineLength: lineLength,
    variants: config.variants,
  );
  return formatGeneratedDart(raw, lineLength: lineLength);
}
