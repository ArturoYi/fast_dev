import '../../config/config.dart';
import 'group.dart';
import 'naming.dart';

/// 生成树里的一个文件叶子。
final class AssetLeaf {
  /// 见各字段说明。
  const AssetLeaf({
    required this.posixPath,
    required this.identifier,
    required this.variant,
  });

  /// 逻辑路径（已去掉主题/语言保留段），用于命名和建树。
  final String posixPath;

  /// 在父级上的成员名。
  final String identifier;

  /// 真实文件路径与变体。
  final AssetVariantSet variant;
}

/// 一个目录对应的生成类（根类或 `$ClassNameImages` 这类分组类）。
final class AssetGroup {
  /// 见各字段说明。
  const AssetGroup({
    required this.posixPath,
    required this.identifier,
    required this.className,
    required this.files,
    required this.groups,
  });

  /// 目录的 posix 路径；根为 `''`。
  final String posixPath;

  /// 挂在父级上的成员名；根为空。
  final String identifier;

  /// 生成出来的类名。根是配置里的 `class_name`。
  final String className;

  /// 本层文件。
  final List<AssetLeaf> files;

  /// 本层子目录。
  final List<AssetGroup> groups;

  /// 树里是否出现需要 AdaptiveAsset 的叶子。
  bool get hasAdaptiveLeaves {
    for (final file in files) {
      if (!file.variant.isPlain) {
        return true;
      }
    }
    for (final group in groups) {
      if (group.hasAdaptiveLeaves) {
        return true;
      }
    }
    return false;
  }
}

/// 把已分组的逻辑资源编成生成用的树。
AssetGroup buildAssetTree({
  required List<AssetVariantSet> assets,
  required AssetStyle style,
  required String className,
}) {
  final items = [...assets]..sort((a, b) => a.keyPath.compareTo(b.keyPath));
  if (style == AssetStyle.nested) {
    return _buildNested(items, className);
  }
  final styleFn = style == AssetStyle.snake ? snakeCase : camelCase;
  return _buildFlat(items, className, styleFn);
}

AssetGroup _buildFlat(
  List<AssetVariantSet> assets,
  String className,
  String Function(String) style,
) {
  final inputs = [
    for (final asset in assets)
      AssetNameInput(
        source: _stripDefaultAssetPrefix(asset.keyPath),
        isFile: true,
      ),
  ];
  final names = uniqueDartIdentifiers(inputs, style: style);
  final files = <AssetLeaf>[
    for (var i = 0; i < assets.length; i++)
      AssetLeaf(
        posixPath: assets[i].keyPath,
        identifier: names[i],
        variant: assets[i],
      ),
  ]..sort((a, b) => a.identifier.compareTo(b.identifier));
  return AssetGroup(
    posixPath: '',
    identifier: '',
    className: className,
    files: files,
    groups: const [],
  );
}

AssetGroup _buildNested(List<AssetVariantSet> assets, String className) {
  final root = _Dir('');
  for (final asset in assets) {
    _insert(root, asset);
  }
  final flattened = _flattenDefaultAssetDirs(root);
  final usedClassNames = <String>{className};
  return _toGroup(
    flattened,
    memberName: '',
    className: className,
    rootClassName: className,
    usedClassNames: usedClassNames,
  );
}

void _insert(_Dir root, AssetVariantSet asset) {
  final parts = asset.keyPath.split('/')..removeWhere((part) => part.isEmpty);
  var current = root;
  for (var i = 0; i < parts.length; i++) {
    final segment = parts[i];
    if (i == parts.length - 1) {
      current.files[segment] = asset;
    } else {
      final nextPath = parts.sublist(0, i + 1).join('/');
      current = current.dirs.putIfAbsent(segment, () => _Dir(nextPath));
    }
  }
}

_Dir _flattenDefaultAssetDirs(_Dir root) {
  final flat = _Dir('');
  flat.files.addAll(root.files);
  for (final entry in root.dirs.entries) {
    if (entry.key == 'assets' || entry.key == 'asset') {
      _mergeDir(flat, entry.value);
    } else {
      if (flat.dirs.containsKey(entry.key)) {
        _mergeDir(flat.dirs[entry.key]!, entry.value);
      } else {
        flat.dirs[entry.key] = entry.value;
      }
    }
  }
  return flat;
}

void _mergeDir(_Dir target, _Dir extra) {
  target.files.addAll(extra.files);
  for (final entry in extra.dirs.entries) {
    if (target.dirs.containsKey(entry.key)) {
      _mergeDir(target.dirs[entry.key]!, entry.value);
    } else {
      target.dirs[entry.key] = entry.value;
    }
  }
}

AssetGroup _toGroup(
  _Dir dir, {
  required String memberName,
  required String className,
  required String rootClassName,
  required Set<String> usedClassNames,
}) {
  final children = <_Child>[
    for (final entry in dir.files.entries)
      _Child(source: entry.key, isFile: true, variant: entry.value),
    for (final entry in dir.dirs.entries)
      _Child(
        source: entry.key,
        isFile: false,
        posixPath: entry.value.posixPath,
        dir: entry.value,
      ),
  ];
  final names = uniqueDartIdentifiers([
    for (final child in children)
      AssetNameInput(source: child.source, isFile: child.isFile),
  ], style: camelCase);
  for (var i = 0; i < children.length; i++) {
    children[i].identifier = names[i];
  }
  children.sort((a, b) => a.identifier.compareTo(b.identifier));

  final files = <AssetLeaf>[];
  final groups = <AssetGroup>[];
  for (final child in children) {
    if (child.isFile) {
      final variant = child.variant!;
      files.add(
        AssetLeaf(
          posixPath: variant.keyPath,
          identifier: child.identifier,
          variant: variant,
        ),
      );
    } else {
      groups.add(
        _toGroup(
          child.dir!,
          memberName: child.identifier,
          className: _allocateClassName(
            rootClassName: rootClassName,
            dirPosix: child.posixPath,
            used: usedClassNames,
          ),
          rootClassName: rootClassName,
          usedClassNames: usedClassNames,
        ),
      );
    }
  }

  return AssetGroup(
    posixPath: dir.posixPath,
    identifier: memberName,
    className: className,
    files: files,
    groups: groups,
  );
}

String _allocateClassName({
  required String rootClassName,
  required String dirPosix,
  required Set<String> used,
}) {
  final stripped = _stripDefaultAssetPrefix(dirPosix);
  final suffix = capitalize(camelCase(convertToIdentifier(stripped)));
  var candidate = suffix.isEmpty
      ? '\$${rootClassName}Dir'
      : '\$$rootClassName$suffix';
  final base = candidate;
  var i = 2;
  while (used.contains(candidate)) {
    candidate = '$base$i';
    i++;
  }
  used.add(candidate);
  return candidate;
}

String _stripDefaultAssetPrefix(String posixPath) {
  return posixPath.replaceFirst(RegExp(r'^asset(s)?/'), '');
}

final class _Dir {
  _Dir(this.posixPath);

  final String posixPath;
  final Map<String, _Dir> dirs = {};
  final Map<String, AssetVariantSet> files = {};
}

final class _Child {
  _Child({
    required this.source,
    required this.isFile,
    this.posixPath = '',
    this.variant,
    this.dir,
  });

  final String source;
  final bool isFile;
  final String posixPath;
  final AssetVariantSet? variant;
  final _Dir? dir;
  String identifier = '';
}
