import 'package:fast_dev/fast_dev.dart';
import 'package:fast_dev/src/generate/assets/group.dart';
import 'package:test/test.dart';

void main() {
  group('groupAssetVariants', () {
    test('未开启时路径原样保留，dark 仍是普通目录', () {
      final result = groupAssetVariants(
        posixPaths: const [
          'assets/images/dark/logo.svg',
          'assets/images/logo.svg',
        ],
        variants: AssetsVariantsConfig.defaults,
      );
      expect(result.warnings, isEmpty);
      expect(result.assets.map((a) => a.keyPath).toList(), [
        'assets/images/dark/logo.svg',
        'assets/images/logo.svg',
      ]);
      expect(result.assets.every((a) => a.isPlain), isTrue);
    });

    test('只开 theme 时合并 light/dark，自定义目录名也认', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig(
          enabled: true,
          lightFolders: ['day', 'light'],
          darkFolders: ['night', 'dark'],
        ),
        locale: LocaleVariantsConfig.defaults,
      );
      final result = groupAssetVariants(
        posixPaths: const [
          'assets/images/logo.svg',
          'assets/images/dark/logo.svg',
          'assets/images/day/logo.svg',
        ],
        variants: variants,
      );
      expect(result.assets, hasLength(1));
      final logo = result.assets.single;
      expect(logo.keyPath, 'assets/images/logo.svg');
      expect(logo.isPlain, isFalse);
      expect(logo.fallback, 'assets/images/logo.svg');
      expect(logo.light, 'assets/images/day/logo.svg');
      expect(logo.dark, 'assets/images/dark/logo.svg');
      expect(logo.locales, isEmpty);
    });

    test('只有 dark 时 fallback 回退到 dark', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig(
          enabled: true,
          lightFolders: ['light'],
          darkFolders: ['dark'],
        ),
        locale: LocaleVariantsConfig.defaults,
      );
      final logo = groupAssetVariants(
        posixPaths: const ['assets/images/dark/logo.svg'],
        variants: variants,
      ).assets.single;
      expect(logo.fallback, 'assets/images/dark/logo.svg');
      expect(logo.dark, 'assets/images/dark/logo.svg');
      expect(logo.light, isNull);
    });

    test('只开 locale 时合并语言目录，dark 仍留在路径里', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig.defaults,
        locale: LocaleVariantsConfig(
          enabled: true,
          folders: ['zh', 'en'],
          fallback: kLocaleFallbackFile,
        ),
      );
      final result = groupAssetVariants(
        posixPaths: const [
          'assets/images/logo.svg',
          'assets/images/zh/logo.svg',
          'assets/images/dark/logo.svg',
        ],
        variants: variants,
      );
      expect(result.assets.map((a) => a.keyPath).toList(), [
        'assets/images/dark/logo.svg',
        'assets/images/logo.svg',
      ]);
      final logo = result.assets.firstWhere(
        (a) => a.keyPath == 'assets/images/logo.svg',
      );
      expect(logo.locales.keys.toList()..sort(), ['zh']);
      expect(logo.locales['zh']!.fallback, 'assets/images/zh/logo.svg');
      expect(
        result.assets.firstWhere((a) => a.keyPath.contains('dark')).isPlain,
        isTrue,
      );
    });

    test('theme+locale：zh/dark 与 dark/zh 都能剥成同一逻辑资源', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig(
          enabled: true,
          lightFolders: ['light'],
          darkFolders: ['dark'],
        ),
        locale: LocaleVariantsConfig(
          enabled: true,
          folders: ['zh', 'en'],
          fallback: kLocaleFallbackFile,
        ),
      );

      AssetVariantSet group(List<String> paths) {
        return groupAssetVariants(
          posixPaths: paths,
          variants: variants,
        ).assets.single;
      }

      final viaLocaleThenTheme = group(const [
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
        'assets/images/zh/logo.svg',
        'assets/images/zh/dark/logo.svg',
      ]);
      expect(
        viaLocaleThenTheme.locales['zh']!.dark,
        'assets/images/zh/dark/logo.svg',
      );

      final viaThemeThenLocale = group(const [
        'assets/images/dark/zh/logo.svg',
      ]);
      expect(viaThemeThenLocale.keyPath, 'assets/images/logo.svg');
      expect(
        viaThemeThenLocale.locales['zh']!.dark,
        'assets/images/dark/zh/logo.svg',
      );
    });

    test('zh-CN 与 zh_CN 视为同一语言并告警保留前者', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig.defaults,
        locale: LocaleVariantsConfig(
          enabled: true,
          folders: ['zh_CN'],
          fallback: kLocaleFallbackFile,
        ),
      );
      final result = groupAssetVariants(
        posixPaths: const ['assets/a/zh_CN/t.txt', 'assets/a/zh-CN/t.txt'],
        variants: variants,
      );
      expect(result.assets, hasLength(1));
      expect(result.assets.single.locales.keys, ['zh_CN']);
      expect(result.warnings.single, contains('已保留前者'));
    });

    test('只有语言文件且 fallback 为 file 时按名字排序取回退', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig.defaults,
        locale: LocaleVariantsConfig(
          enabled: true,
          folders: ['zh', 'en'],
          fallback: kLocaleFallbackFile,
        ),
      );
      final logo = groupAssetVariants(
        posixPaths: const [
          'assets/images/zh/logo.svg',
          'assets/images/en/logo.svg',
        ],
        variants: variants,
      ).assets.single;
      expect(logo.fallback, 'assets/images/en/logo.svg');
      expect(logo.locales.keys.toList()..sort(), ['en', 'zh']);
    });

    test('没有无语言文件时根节点带上所选语言的 dark', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig(
          enabled: true,
          lightFolders: ['light'],
          darkFolders: ['dark'],
        ),
        locale: LocaleVariantsConfig(
          enabled: true,
          folders: ['zh', 'en'],
          fallback: kLocaleFallbackFile,
        ),
      );
      final logo = groupAssetVariants(
        posixPaths: const [
          'assets/images/en/logo.svg',
          'assets/images/en/dark/logo.svg',
          'assets/images/zh/logo.svg',
        ],
        variants: variants,
      ).assets.single;
      expect(logo.fallback, 'assets/images/en/logo.svg');
      expect(logo.dark, 'assets/images/en/dark/logo.svg');
      expect(logo.locales['zh']!.fallback, 'assets/images/zh/logo.svg');
    });

    test('只有语言文件且 fallback 为 en 时用 en 做根回退', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig.defaults,
        locale: LocaleVariantsConfig(
          enabled: true,
          folders: ['zh', 'en'],
          fallback: 'en',
        ),
      );
      final logo = groupAssetVariants(
        posixPaths: const [
          'assets/images/zh/logo.svg',
          'assets/images/en/logo.svg',
        ],
        variants: variants,
      ).assets.single;
      expect(logo.fallback, 'assets/images/en/logo.svg');
    });

    test('同一路径多个主题目录时告警并保留先出现的', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig(
          enabled: true,
          lightFolders: ['light'],
          darkFolders: ['dark'],
        ),
        locale: LocaleVariantsConfig.defaults,
      );
      final result = groupAssetVariants(
        posixPaths: const ['assets/images/light/dark/logo.svg'],
        variants: variants,
      );
      expect(result.warnings.single, contains('多个主题目录'));
      expect(result.assets.single.light, 'assets/images/light/dark/logo.svg');
      expect(result.assets.single.dark, isNull);
    });
  });
}
