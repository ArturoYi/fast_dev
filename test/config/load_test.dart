import 'dart:io';

import 'package:fast_dev/fast_dev.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('fast_dev_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('无配置文件时使用默认值', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');

    final result = loadFastDevConfig(fromDirectory: temp.path);

    expect(result.usedDefaults, isTrue);
    expect(result.configFile, isNull);
    expect(result.packageRoot!.path, Directory(temp.path).absolute.path);
    expect(result.config.generate.output, kDefaultGenerateOutput);
    expect(result.warnings.single, contains(kConfigFileName));
  });

  test('从子目录向上找到 pubspec 和配置文件', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');
    File(p.join(temp.path, kConfigFileName)).writeAsStringSync('''
version: 1
generate:
  output: lib/build
''');
    final nested = Directory(p.join(temp.path, 'lib', 'src'))
      ..createSync(recursive: true);

    final result = loadFastDevConfig(fromDirectory: nested.path);

    expect(result.usedDefaults, isFalse);
    expect(
      result.configFile!.path,
      p.join(temp.absolute.path, kConfigFileName),
    );
    expect(result.config.generate.output, 'lib/build/');
    expect(result.warnings, isEmpty);
  });

  test('--config 覆盖默认文件名，且文件必须存在', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');
    final custom = File(p.join(temp.path, 'custom.yaml'))
      ..writeAsStringSync('generate:\n  line_length: 100\n');

    final result = loadFastDevConfig(
      fromDirectory: temp.path,
      configPath: custom.path,
    );
    expect(result.config.generate.lineLength, 100);

    expect(
      () => loadFastDevConfig(
        fromDirectory: temp.path,
        configPath: p.join(temp.path, 'missing.yaml'),
      ),
      throwsA(isA<ConfigException>()),
    );
  });

  test('相对 --config 相对 fromDirectory 解析', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');
    File(p.join(temp.path, 'alt.yaml')).writeAsStringSync('''
generate:
  assets:
    class_name: AltAssets
''');

    final result = loadFastDevConfig(
      fromDirectory: temp.path,
      configPath: 'alt.yaml',
    );
    expect(result.config.generate.assets.className, 'AltAssets');
  });

  test('向上找不到 pubspec 时抛错', () {
    expect(
      () => loadFastDevConfig(fromDirectory: temp.path),
      throwsA(
        isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('未找到 pubspec.yaml'),
        ),
      ),
    );
  });
}
