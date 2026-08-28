import 'dart:io';

import 'package:fast_dev/src/builder/manifest.dart';
import 'package:fast_dev/src/builder/post_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('fast_dev_builder_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('写出生成文件并删掉上一轮不再拥有的路径', () {
    final stale = File(p.join(temp.path, 'lib/old.gen.dart'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('stale');
    File(p.join(temp.path, '.dart_tool/fast_dev', kOwnedOutputsFileName))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{"paths":["lib/old.gen.dart"]}');

    materializeManifest(
      FastDevManifest(
        packageName: 'demo',
        packageRoot: temp.path,
        outputs: const [
          ManifestOutput(
            path: 'lib/gen/fast_dev/assets.gen.dart',
            contents: 'class DemoAssets {}',
          ),
        ],
      ),
    );

    expect(stale.existsSync(), isFalse);
    expect(
      File(
        p.join(temp.path, 'lib/gen/fast_dev/assets.gen.dart'),
      ).readAsStringSync(),
      'class DemoAssets {}',
    );
  });

  test('拒绝写出包外路径', () {
    materializeManifest(
      FastDevManifest(
        packageName: 'demo',
        packageRoot: temp.path,
        outputs: const [
          ManifestOutput(path: '../outside.dart', contents: 'bad'),
        ],
      ),
    );
    expect(File(p.join(temp.path, '../outside.dart')).existsSync(), isFalse);
  });
}
