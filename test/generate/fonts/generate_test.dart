import 'package:fast_dev/fast_dev.dart';
import 'package:test/test.dart';

void main() {
  const families = [
    FlutterFontFamily(
      family: 'Raleway',
      assetPaths: ['fonts/Raleway-Regular.ttf'],
    ),
    FlutterFontFamily(
      family: 'RobotoMono',
      assetPaths: ['fonts/RobotoMono-Regular.ttf'],
    ),
  ];

  test('生成 FontFamily 常量', () {
    final source = generateFontsSource(
      config: FontsGenerateConfig.defaults,
      lineLength: 80,
      families: families,
    )!;

    expect(source, contains('abstract final class FontFamily'));
    expect(source, contains("static const String raleway = 'Raleway';"));
    expect(source, contains("static const String robotoMono = 'RobotoMono';"));
    expect(source, contains('/// Font family: Raleway'));
    expect(source, isNot(contains('static const String package')));
    expect(source, isNot(contains('static const List<String> fallbacks')));
    expect(source, contains('// dart format width=80'));
  });

  test('写出 FontFamily.fallbacks', () {
    final source = generateFontsSource(
      config: const FontsGenerateConfig(
        enabled: true,
        className: 'FontFamily',
        fallbacks: ['NotoSansSC', 'NotoNaskh'],
      ),
      lineLength: 80,
      families: const [
        FlutterFontFamily(family: 'Raleway'),
        FlutterFontFamily(family: 'NotoSansSC'),
        FlutterFontFamily(family: 'NotoNaskh'),
      ],
    )!;
    expect(source, contains("static const String raleway = 'Raleway';"));
    expect(source, contains("static const String notoSansSC = 'NotoSansSC';"));
    expect(source, contains("static const String notoNaskh = 'NotoNaskh';"));
    expect(
      source,
      contains(
        'static const List<String> fallbacks = [notoSansSC, notoNaskh];',
      ),
    );
  });

  test('fallbacks 引用不存在的 family 则失败', () {
    expect(
      () => generateFontsSource(
        config: const FontsGenerateConfig(
          enabled: true,
          className: 'FontFamily',
          fallbacks: ['Missing'],
        ),
        lineLength: 80,
        families: const [FlutterFontFamily(family: 'Raleway')],
      ),
      throwsA(
        isA<GenerateException>().having(
          (e) => e.message,
          'message',
          contains('Missing'),
        ),
      ),
    );
  });

  test('配置了 fallbacks 时 family 名为 fallbacks 会避开冲突', () {
    final source = generateFontsSource(
      config: const FontsGenerateConfig(
        enabled: true,
        className: 'FontFamily',
        fallbacks: ['fallbacks'],
      ),
      lineLength: 80,
      families: const [FlutterFontFamily(family: 'fallbacks')],
    )!;
    expect(source, contains("static const String fallbacks_ = 'fallbacks';"));
    expect(
      source,
      contains('static const List<String> fallbacks = [fallbacks_];'),
    );
  });

  test('自定义 class_name', () {
    final source = generateFontsSource(
      config: const FontsGenerateConfig(enabled: true, className: 'AppFonts'),
      lineLength: 100,
      families: families,
    )!;
    expect(source, contains('abstract final class AppFonts'));
    expect(source, contains('// dart format width=100'));
  });

  test('空列表不生成', () {
    expect(
      generateFontsSource(
        config: FontsGenerateConfig.defaults,
        lineLength: 80,
        families: const [],
      ),
      isNull,
    );
  });

  test('重复 family 去重并告警', () {
    final warnings = <String>[];
    final source = generateFontsSource(
      config: FontsGenerateConfig.defaults,
      lineLength: 80,
      families: const [
        FlutterFontFamily(family: 'Raleway'),
        FlutterFontFamily(family: 'Raleway'),
        FlutterFontFamily(family: 'RobotoMono'),
      ],
      warnings: warnings,
    )!;
    expect(warnings.single, contains('已保留前者'));
    expect(source, contains("raleway = 'Raleway'"));
    expect(source, contains("robotoMono = 'RobotoMono'"));
    expect('Raleway'.allMatches(source).length, 2);
  });

  test('库模式写出 package 与 packages/\$package/Family', () {
    final source = generateFontsSource(
      config: const FontsGenerateConfig(
        enabled: true,
        className: 'FontFamily',
        package: true,
      ),
      lineLength: 80,
      families: families,
      packageName: 'design_system',
    )!;
    expect(source, contains("static const String package = 'design_system';"));
    expect(
      source,
      contains(r"static const String raleway = 'packages/$package/Raleway';"),
    );
    expect(
      source,
      contains(
        r"static const String robotoMono = 'packages/$package/RobotoMono';",
      ),
    );
  });

  test('库模式但没有 package name 时回退并告警', () {
    final warnings = <String>[];
    final source = generateFontsSource(
      config: const FontsGenerateConfig(
        enabled: true,
        className: 'FontFamily',
        package: true,
      ),
      lineLength: 80,
      families: const [FlutterFontFamily(family: 'Raleway')],
      warnings: warnings,
    )!;
    expect(warnings.single, contains('没有 name'));
    expect(source, contains("raleway = 'Raleway'"));
    expect(source, isNot(contains('packages/')));
  });

  test('库模式时 family 名为 package 会避开冲突', () {
    final source = generateFontsSource(
      config: const FontsGenerateConfig(
        enabled: true,
        className: 'FontFamily',
        package: true,
      ),
      lineLength: 80,
      families: const [FlutterFontFamily(family: 'package')],
      packageName: 'demo',
    )!;
    expect(source, contains("static const String package = 'demo';"));
    expect(source, contains(r"package_ = 'packages/$package/package';"));
  });

  test('关键字 family 加后缀', () {
    final source = generateFontsSource(
      config: FontsGenerateConfig.defaults,
      lineLength: 80,
      families: const [FlutterFontFamily(family: 'class')],
    )!;
    expect(source, contains("static const String class_ = 'class';"));
  });
}
