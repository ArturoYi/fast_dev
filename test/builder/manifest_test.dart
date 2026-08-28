import 'package:fast_dev/src/builder/manifest.dart';
import 'package:test/test.dart';

void main() {
  test('清单往返 JSON', () {
    const original = FastDevManifest(
      packageName: 'demo',
      packageRoot: '/tmp/demo',
      outputs: [
        ManifestOutput(
          path: 'lib/gen/fast_dev/assets.gen.dart',
          contents: 'class A {}',
        ),
      ],
    );
    final restored = FastDevManifest.fromJsonString(original.toJsonString());
    expect(restored.packageName, 'demo');
    expect(restored.packageRoot, '/tmp/demo');
    expect(restored.outputs.single.path, 'lib/gen/fast_dev/assets.gen.dart');
    expect(restored.outputs.single.contents, 'class A {}');
  });
}
