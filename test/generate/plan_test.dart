import 'package:fast_dev/fast_dev.dart';
import 'package:test/test.dart';

void main() {
  test('写出 assets.gen.dart', () {
    final parsed = parseFlutterManifest('''
name: demo
flutter:
  assets:
    - assets/logo.svg
''');
    final plan = planGenerate(
      config: FastDevConfig.defaults,
      parsed: parsed,
      expanded: const AssetExpandResult(
        paths: ['assets/logo.svg'],
        warnings: [],
      ),
    );

    expect(
      plan.outputs.single.relativePath,
      'lib/gen/fast_dev/assets.gen.dart',
    );
    expect(
      plan.outputs.single.contents,
      contains('abstract final class Assets'),
    );
    expect(plan.skipped.single, contains('fonts'));
  });

  test('outputOverride 改写出路径', () {
    final parsed = parseFlutterManifest('''
name: demo
flutter:
  assets:
    - assets/logo.svg
''');
    final plan = planGenerate(
      config: FastDevConfig.defaults,
      parsed: parsed,
      expanded: const AssetExpandResult(
        paths: ['assets/logo.svg'],
        warnings: [],
      ),
      outputOverride: 'lib/generated/',
    );
    expect(plan.outputs.single.relativePath, 'lib/generated/assets.gen.dart');
  });

  test('enabled: false 不产出文件', () {
    final parsed = parseFlutterManifest('''
name: demo
flutter:
  assets:
    - assets/logo.svg
''');
    const config = FastDevConfig(
      version: kCurrentConfigVersion,
      generate: GenerateConfig(
        output: kDefaultGenerateOutput,
        lineLength: 80,
        assets: AssetsGenerateConfig(
          enabled: false,
          className: 'Assets',
          style: AssetStyle.nested,
        ),
      ),
    );
    final plan = planGenerate(config: config, parsed: parsed);
    expect(plan.outputs, isEmpty);
    expect(plan.skipped, hasLength(2));
    expect(plan.skipped, contains(contains('assets')));
    expect(plan.skipped, contains(contains('fonts')));
  });

  test('写出 fonts.gen.dart', () {
    final parsed = parseFlutterManifest('''
name: demo
flutter:
  fonts:
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Regular.ttf
''');
    final plan = planGenerate(config: FastDevConfig.defaults, parsed: parsed);

    expect(plan.outputs.single.relativePath, 'lib/gen/fast_dev/fonts.gen.dart');
    expect(
      plan.outputs.single.contents,
      contains('abstract final class FontFamily'),
    );
    expect(plan.outputs.single.contents, contains("raleway = 'Raleway'"));
    expect(plan.skipped.single, contains('assets'));
  });

  test('fonts.package 按库模式写出', () {
    final parsed = parseFlutterManifest('''
name: design_system
flutter:
  fonts:
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Regular.ttf
''');
    const config = FastDevConfig(
      version: kCurrentConfigVersion,
      generate: GenerateConfig(
        output: kDefaultGenerateOutput,
        lineLength: 80,
        assets: AssetsGenerateConfig(
          enabled: false,
          className: 'Assets',
          style: AssetStyle.nested,
        ),
        fonts: FontsGenerateConfig(
          enabled: true,
          className: 'FontFamily',
          package: true,
        ),
      ),
    );
    final plan = planGenerate(config: config, parsed: parsed);
    expect(plan.outputs.single.contents, contains("package = 'design_system'"));
    expect(
      plan.outputs.single.contents,
      contains(r"raleway = 'packages/$package/Raleway'"),
    );
  });

  test('可注入自定义 Generator', () {
    final parsed = parseFlutterManifest('name: demo\n');
    final plan = planGenerate(
      config: FastDevConfig.defaults,
      parsed: parsed,
      generators: const [_StubGenerator()],
    );
    expect(plan.outputs.single.relativePath, 'lib/gen/fast_dev/stub.gen.dart');
    expect(plan.outputs.single.contents, 'class Stub {}');
    expect(plan.skipped, isEmpty);
  });
}

final class _StubGenerator implements Generator {
  const _StubGenerator();

  @override
  String get id => 'stub';

  @override
  GeneratorResult generate(GeneratorContext context) {
    return GeneratorResult(
      outputs: [
        PlannedOutput(
          relativePath: '${context.outputDirectory}stub.gen.dart',
          contents: 'class Stub {}',
        ),
      ],
    );
  }
}
