import 'package:fast_dev/src/builder/compose.dart';
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
    expect(result.skipped.single, contains('fonts'));
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
    expect(result.skipped, contains(contains('assets')));
    expect(result.skipped, contains(contains('fonts')));
  });

  test('从 pubspec fonts 写出 fonts 清单', () {
    final result = composeGenerate(
      packageName: 'demo',
      packageRoot: '/tmp/demo',
      pubspecContents: '''
name: demo
flutter:
  fonts:
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Regular.ttf
''',
      configContents: '''
generate:
  fonts:
    class_name: DemoFonts
''',
    );

    expect(
      result.manifest.outputs.single.path,
      'lib/gen/fast_dev/fonts.gen.dart',
    );
    expect(result.manifest.outputs.single.contents, contains('DemoFonts'));
    expect(
      result.manifest.outputs.single.contents,
      contains("raleway = 'Raleway'"),
    );
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
