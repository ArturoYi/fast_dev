import 'dart:io';

import 'package:fast_dev/fast_dev.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('fast_dev_gen_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('写出 lib/gen/fast_dev/assets.gen.dart', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: demo
flutter:
  assets:
    - assets/
''');
    File(p.join(temp.path, kConfigFileName)).writeAsStringSync('''
generate:
  assets:
    class_name: DemoAssets
''');
    File(p.join(temp.path, 'assets/images/logo.svg'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('<svg />');
    File(p.join(temp.path, 'assets/data/hello.json'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{}');

    final loaded = loadFastDevConfig(fromDirectory: temp.path);
    final result = runGenerate(loaded);

    expect(result.written, ['lib/gen/fast_dev/assets.gen.dart']);
    expect(result.skipped.single, contains('fonts'));

    final generated = File(
      p.join(temp.path, 'lib/gen/fast_dev/assets.gen.dart'),
    ).readAsStringSync();
    expect(generated, contains('abstract final class DemoAssets'));
    expect(generated, contains('assets/images/logo.svg'));
    expect(generated, contains('assets/data/hello.json'));
  });

  test('开启 variants 后写出 AdaptiveAsset', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: demo
flutter:
  assets:
    - assets/
''');
    File(p.join(temp.path, kConfigFileName)).writeAsStringSync('''
generate:
  assets:
    class_name: DemoAssets
    variants:
      theme:
        enabled: true
      locale:
        enabled: true
        folders: [zh, en]
''');
    File(p.join(temp.path, 'assets/images/logo.svg'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('<svg />');
    File(p.join(temp.path, 'assets/images/dark/logo.svg'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('<svg dark />');
    File(p.join(temp.path, 'assets/images/zh/logo.svg'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('<svg zh />');

    final result = runGenerate(loadFastDevConfig(fromDirectory: temp.path));
    expect(result.written, ['lib/gen/fast_dev/assets.gen.dart']);
    expect(result.skipped.single, contains('fonts'));

    final generated = File(
      p.join(temp.path, 'lib/gen/fast_dev/assets.gen.dart'),
    ).readAsStringSync();
    expect(generated, contains('class AdaptiveAsset'));
    expect(generated, contains('AdaptiveAsset get logo'));
    expect(generated, contains("'zh': AdaptiveAsset("));
    expect(generated, isNot(contains(r'$DemoAssetsImagesDark')));
  });

  test('enabled: false 不写文件', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: demo
flutter:
  assets:
    - assets/a.png
''');
    File(p.join(temp.path, kConfigFileName)).writeAsStringSync('''
generate:
  assets:
    enabled: false
''');
    File(p.join(temp.path, 'assets/a.png'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('x');

    final result = runGenerate(loadFastDevConfig(fromDirectory: temp.path));
    expect(result.written, isEmpty);
    expect(result.skipped, contains(contains('assets')));
    expect(result.skipped, contains(contains('fonts')));
    expect(
      File(p.join(temp.path, 'lib/gen/fast_dev/assets.gen.dart')).existsSync(),
      isFalse,
    );
  });

  test('写出 lib/gen/fast_dev/fonts.gen.dart', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: demo
flutter:
  fonts:
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Regular.ttf
    - family: RobotoMono
      fonts:
        - asset: fonts/RobotoMono-Regular.ttf
''');
    File(p.join(temp.path, kConfigFileName)).writeAsStringSync('''
generate:
  fonts:
    class_name: DemoFonts
''');

    final result = runGenerate(loadFastDevConfig(fromDirectory: temp.path));

    expect(result.written, ['lib/gen/fast_dev/fonts.gen.dart']);
    expect(result.skipped.single, contains('assets'));

    final generated = File(
      p.join(temp.path, 'lib/gen/fast_dev/fonts.gen.dart'),
    ).readAsStringSync();
    expect(generated, contains('abstract final class DemoFonts'));
    expect(generated, contains("raleway = 'Raleway'"));
    expect(generated, contains("robotoMono = 'RobotoMono'"));
  });
}
