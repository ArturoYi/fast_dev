import 'package:fast_dev_runner/src/compose.dart';
import 'package:test/test.dart';

void main() {
  const pubspec = '''
name: demo
flutter:
  assets:
    - assets/logo.svg
''';

  test('从 pubspec 和资源写出 assets 清单', () {
    final result = composeGenerate(
      packageName: 'demo',
      packageRoot: '/tmp/demo',
      pubspecContents: pubspec,
      configContents: '''
generate:
  assets:
    class_name: DemoAssets
''',
      graphPaths: const ['assets/logo.svg'],
    );

    expect(result.manifest.outputs, hasLength(1));
    expect(
      result.manifest.outputs.single.path,
      'lib/gen/fast_dev/assets.gen.dart',
    );
    expect(result.manifest.outputs.single.contents, contains('DemoAssets'));
    expect(
      result.manifest.outputs.single.contents,
      contains('assets/logo.svg'),
    );
    expect(result.skipped, isEmpty);
  });

  test('assets.enabled: false 时清单没有输出文件', () {
    final result = composeGenerate(
      packageName: 'demo',
      packageRoot: '/tmp/demo',
      pubspecContents: pubspec,
      configContents: '''
generate:
  assets:
    enabled: false
''',
      graphPaths: const ['assets/logo.svg'],
    );
    expect(result.manifest.outputs, isEmpty);
    expect(result.skipped.single, contains('assets'));
  });

  test('build.yaml options.output 覆盖写出路径', () {
    final result = composeGenerate(
      packageName: 'demo',
      packageRoot: '/tmp/demo',
      pubspecContents: pubspec,
      graphPaths: const ['assets/logo.svg'],
      outputOverride: outputDirFromBuilderConfig({'output': 'lib/generated'}),
    );
    expect(
      result.manifest.outputs.single.path,
      'lib/generated/assets.gen.dart',
    );
  });
}
