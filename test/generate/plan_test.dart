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
    expect(plan.skipped, isEmpty);
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
    expect(plan.skipped.single, contains('assets'));
  });

  test('可注入自定义 Generator', () {
    final parsed = parseFlutterManifest('name: demo\n');
    final plan = planGenerate(
      config: FastDevConfig.defaults,
      parsed: parsed,
      generators: const [_StubGenerator()],
    );
    expect(
      plan.outputs.single.relativePath,
      'lib/gen/fast_dev/stub.gen.dart',
    );
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
