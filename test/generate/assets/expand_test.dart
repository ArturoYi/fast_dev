import 'dart:io';

import 'package:fast_dev/src/generate/assets/expand.dart';
import 'package:fast_dev/src/pubspec/manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('fast_dev_expand_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('只写 assets/ 时递归子目录', () {
    _write(temp, 'assets/images/logo.svg', '<svg />');
    _write(temp, 'assets/images/icons/nested.svg', '<svg />');
    _write(temp, 'assets/data/hello.json', '{}');

    final result = expandFlutterAssets(
      packageRoot: temp.path,
      entries: const [FlutterAssetEntry(path: 'assets/')],
    );

    expect(result.paths, [
      'assets/data/hello.json',
      'assets/images/icons/nested.svg',
      'assets/images/logo.svg',
    ]);
    expect(result.warnings, isEmpty);
  });

  test('列出子目录时同样递归', () {
    _write(temp, 'assets/images/logo.svg', '<svg />');
    _write(temp, 'assets/images/icons/nested.svg', '<svg />');
    _write(temp, 'assets/data/hello.json', '{}');

    final result = expandFlutterAssets(
      packageRoot: temp.path,
      entries: const [
        FlutterAssetEntry(path: 'assets/images/'),
        FlutterAssetEntry(path: 'assets/data/hello.json'),
      ],
    );

    expect(result.paths, [
      'assets/data/hello.json',
      'assets/images/icons/nested.svg',
      'assets/images/logo.svg',
    ]);
  });

  test('忽略点文件、排除名单和缺失条目告警', () {
    _write(temp, 'assets/images/logo.svg', '<svg />');
    _write(temp, 'assets/images/.DS_Store', 'junk');
    _write(temp, 'assets/data/skip.yaml', 'x: 1');

    final result = expandFlutterAssets(
      packageRoot: temp.path,
      entries: const [
        FlutterAssetEntry(path: 'assets/'),
        FlutterAssetEntry(path: 'assets/missing.png'),
      ],
      exclude: const ['assets/data/skip.yaml'],
    );

    expect(result.paths, ['assets/images/logo.svg']);
    expect(result.warnings.single, contains('assets/missing.png'));
  });

  test('normalizeDiscoveredAssetPaths 与磁盘展开规则一致', () {
    final result = normalizeDiscoveredAssetPaths(
      posixPaths: const [
        'assets/images/logo.svg',
        'assets/images/.DS_Store',
        'assets/data/skip.yaml',
      ],
      exclude: const ['assets/data/skip.yaml'],
    );
    expect(result.paths, ['assets/images/logo.svg']);
    expect(result.warnings, isEmpty);
  });
}

void _write(Directory root, String relative, String contents) {
  File(p.join(root.path, relative))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(contents);
}
