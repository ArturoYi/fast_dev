import 'package:fast_dev/fast_dev.dart';
import 'package:test/test.dart';

void main() {
  group('parseFlutterManifest', () {
    test('读出 name 和字符串形式的 assets', () {
      const yaml = '''
name: demo
flutter:
  assets:
    - assets/images/
    - assets/data/hello.json
''';
      final result = parseFlutterManifest(yaml);
      expect(result.warnings, isEmpty);
      expect(result.manifest.packageName, 'demo');
      expect(result.manifest.assetEntries.map((e) => e.path), [
        'assets/images/',
        'assets/data/hello.json',
      ]);
    });

    test('没有 flutter 段则 assets 为空', () {
      final result = parseFlutterManifest('name: demo\n');
      expect(result.manifest.assetEntries, isEmpty);
    });

    test('重复路径只保留第一次', () {
      const yaml = '''
name: demo
flutter:
  assets:
    - assets/a.png
    - assets/a.png
''';
      final result = parseFlutterManifest(yaml);
      expect(result.manifest.assetEntries, hasLength(1));
    });

    test('Map 形式读 path，flavors 告警', () {
      const yaml = '''
name: demo
flutter:
  assets:
    - path: assets/logo.png
      flavors:
        - paid
''';
      final result = parseFlutterManifest(yaml);
      expect(result.manifest.assetEntries.single.path, 'assets/logo.png');
      expect(result.warnings.single, contains('flavors'));
    });

    test('非法 YAML 抛 GenerateException', () {
      expect(
        () => parseFlutterManifest('flutter: [\n'),
        throwsA(isA<GenerateException>()),
      );
    });

    test('读出 fonts family 并去重', () {
      const yaml = '''
name: demo
flutter:
  fonts:
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Regular.ttf
        - asset: fonts/Raleway-Italic.ttf
          style: italic
        - asset: fonts/Raleway-Regular.ttf
    - family: RobotoMono
      fonts:
        - asset: fonts/RobotoMono-Regular.ttf
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Bold.ttf
''';
      final result = parseFlutterManifest(yaml);
      expect(result.manifest.fontFamilies, hasLength(2));
      expect(result.manifest.fontFamilies[0].family, 'Raleway');
      expect(result.manifest.fontFamilies[0].assetPaths, [
        'fonts/Raleway-Regular.ttf',
        'fonts/Raleway-Italic.ttf',
      ]);
      expect(result.manifest.fontFamilies[1].family, 'RobotoMono');
      expect(result.warnings, contains(contains('重复的 family')));
    });

    test('fonts 缺少 family 则跳过并告警', () {
      const yaml = '''
name: demo
flutter:
  fonts:
    - fonts:
        - asset: fonts/Missing.ttf
''';
      final result = parseFlutterManifest(yaml);
      expect(result.manifest.fontFamilies, isEmpty);
      expect(result.warnings.single, contains('缺少非空的 family'));
    });

    test('fonts 条目不是 Map 则抛错', () {
      expect(
        () => parseFlutterManifest('''
name: demo
flutter:
  fonts:
    - Raleway
'''),
        throwsA(
          isA<GenerateException>().having(
            (e) => e.message,
            'message',
            contains('带 family 的键值对'),
          ),
        ),
      );
    });
  });
}
