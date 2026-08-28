import 'package:fast_dev/fast_dev.dart';
import 'package:fast_dev/src/builder/discover.dart';
import 'package:test/test.dart';

void main() {
  const entries = [
    FlutterAssetEntry(path: 'assets/'),
    FlutterAssetEntry(path: 'assets/missing.png'),
  ];

  test('并集磁盘与 graph，缺文件告警', () {
    final result = mergeDiscoveredAssets(
      entries: entries,
      exclude: const ['assets/data/skip.yaml'],
      graphPaths: const [
        'assets/images/logo.svg',
        'assets/images/2.0x/logo.svg',
        'assets/data/skip.yaml',
      ],
      disk: const AssetExpandResult(
        paths: ['assets/images/logo.svg'],
        warnings: [],
      ),
    );
    expect(result.paths, ['assets/images/logo.svg']);
    expect(result.warnings.single, contains('assets/missing.png'));
  });

  test('只有 graph 时也能生成路径', () {
    final result = mergeDiscoveredAssets(
      entries: const [FlutterAssetEntry(path: 'assets/')],
      exclude: const [],
      graphPaths: const ['assets/data/hello.json'],
    );
    expect(result.paths, ['assets/data/hello.json']);
    expect(result.warnings, isEmpty);
  });
}
