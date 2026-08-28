import 'package:fast_dev/fast_dev.dart';
import 'package:test/test.dart';

void main() {
  group('parseFastDevConfig', () {
    test('空字符串使用全部默认值并告警', () {
      final result = parseFastDevConfig('');
      expect(result.config.version, kCurrentConfigVersion);
      expect(result.config.generate.output, kDefaultGenerateOutput);
      expect(result.config.generate.assets.style, AssetStyle.nested);
      expect(result.warnings, contains(contains('为空')));
    });

    test('只写部分字段时其余保持默认', () {
      const yaml = '''
version: 1
generate:
  output: lib/build
  line_length: 120
''';
      final result = parseFastDevConfig(yaml);
      expect(result.warnings, isEmpty);
      expect(result.config.generate.output, 'lib/build/');
      expect(result.config.generate.lineLength, 120);
      expect(result.config.generate.assets.className, 'Assets');
    });

    test('未知字段告警后忽略', () {
      const yaml = '''
version: 1
generate:
  extra: 1
''';
      final result = parseFastDevConfig(yaml);
      expect(result.warnings, contains('未识别的配置项 `generate.extra`，已忽略'));
    });

    test('预留的 imports / fonts / colors 告警后忽略', () {
      const yaml = '''
imports:
  comments: true
generate:
  fonts:
    enabled: true
  colors:
    inputs:
      - assets/colors/app.yaml
''';
      final result = parseFastDevConfig(yaml);
      expect(result.warnings, contains('配置项 `imports` 已预留，当前版本尚未实现，已忽略'));
      expect(
        result.warnings,
        contains('配置项 `generate.fonts` 已预留，当前版本尚未实现，已忽略'),
      );
      expect(
        result.warnings,
        contains('配置项 `generate.colors` 已预留，当前版本尚未实现，已忽略'),
      );
      expect(result.config.generate.assets.enabled, isTrue);
    });

    test('不支持的 version 抛错', () {
      expect(
        () => parseFastDevConfig('version: 2\n'),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('不支持的配置版本 2'),
          ),
        ),
      );
    });

    test('非法 style 抛错', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    style: dots
'''),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('nested、camel 或 snake'),
          ),
        ),
      );
    });

    test('非法 class_name 抛错', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    class_name: 123Assets
'''),
        throwsA(isA<ConfigException>()),
      );
    });

    test('根节点不是 Map 抛错', () {
      expect(
        () => parseFastDevConfig('- just\n- a\n- list\n'),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('键值对'),
          ),
        ),
      );
    });

    test('YAML 语法错误抛错', () {
      expect(
        () => parseFastDevConfig('generate: [\n'),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('YAML 解析失败'),
          ),
        ),
      );
    });

    test('布尔类型不对时带路径', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    enabled: yes-please
'''),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('generate.assets.enabled'),
          ),
        ),
      );
    });

    test('variants 默认关闭', () {
      final variants = parseFastDevConfig(
        '',
      ).config.generate.assets.variants;
      expect(variants.theme.enabled, isFalse);
      expect(variants.locale.enabled, isFalse);
      expect(variants.locale.folders, isEmpty);
      expect(variants.locale.fallback, kLocaleFallbackFile);
    });

    test('解析 theme 与 locale 变体', () {
      const yaml = '''
generate:
  assets:
    variants:
      theme:
        enabled: true
        folders:
          light: day
          dark: [night, dark]
      locale:
        enabled: true
        folders: [zh, en, zh_CN]
        fallback: en
''';
      final variants = parseFastDevConfig(
        yaml,
      ).config.generate.assets.variants;
      expect(variants.theme.enabled, isTrue);
      expect(variants.theme.lightFolders, ['day']);
      expect(variants.theme.darkFolders, ['night', 'dark']);
      expect(variants.locale.enabled, isTrue);
      expect(variants.locale.folders, ['zh', 'en', 'zh_CN']);
      expect(variants.locale.fallback, 'en');
    });

    test('locale.enabled 但 folders 为空则抛错', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
'''),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('必须列出 folders'),
          ),
        ),
      );
    });

    test('theme 与 locale 目录重名则抛错', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    variants:
      theme:
        enabled: true
      locale:
        enabled: true
        folders: [dark, zh]
'''),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('不能重名'),
          ),
        ),
      );
    });

    test('locale 未开时允许 folders 与主题目录重名', () {
      final variants = parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
        folders: [dark, zh]
''').config.generate.assets.variants;
      expect(variants.theme.enabled, isFalse);
      expect(variants.locale.folders, ['dark', 'zh']);
    });

    test('locale folders 接受单个字符串；zh-CN 与 zh_CN 去重', () {
      final locale = parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
        folders: zh
''').config.generate.assets.variants.locale;
      expect(locale.folders, ['zh']);

      final aliases = parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
        folders: [zh_CN, zh-CN]
''').config.generate.assets.variants.locale;
      expect(aliases.folders, ['zh_CN']);
    });

    test('fallback 为 File 时当成 file；语言码对齐 folders 写法', () {
      final fileFallback = parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
        folders: [zh, en]
        fallback: File
''').config.generate.assets.variants.locale;
      expect(fileFallback.fallback, kLocaleFallbackFile);

      final aligned = parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
        folders: [zh, en]
        fallback: ZH
''').config.generate.assets.variants.locale;
      expect(aligned.fallback, 'zh');
    });

    test('light 与 dark 目录重名则抛错', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    variants:
      theme:
        enabled: true
        folders:
          light: [day]
          dark: Day
'''),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('light 与 dark'),
          ),
        ),
      );
    });

    test('变体目录不能是密度名', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
        folders: [2.0x, zh]
'''),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('密度目录'),
          ),
        ),
      );
    });

    test('fallback 不在 folders 里则抛错', () {
      expect(
        () => parseFastDevConfig('''
generate:
  assets:
    variants:
      locale:
        enabled: true
        folders: [zh]
        fallback: en
'''),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('folders 里没有'),
          ),
        ),
      );
    });

    test('style camel 与 class_name 能解析', () {
      const yaml = '''
generate:
  assets:
    style: camel
    class_name: MyAssets
''';
      final config = parseFastDevConfig(yaml).config;
      expect(config.generate.assets.style, AssetStyle.camel);
      expect(config.generate.assets.className, 'MyAssets');
    });
  });
}
