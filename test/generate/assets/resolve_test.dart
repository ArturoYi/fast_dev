import 'package:fast_dev/fast_dev.dart';
import 'package:fast_dev/src/generate/assets/group.dart';
import 'package:fast_dev/src/generate/assets/resolve.dart';
import 'package:test/test.dart';

void main() {
  const bothOn = AssetsVariantsConfig(
    theme: ThemeVariantsConfig(
      enabled: true,
      lightFolders: ['light'],
      darkFolders: ['dark'],
    ),
    locale: LocaleVariantsConfig(
      enabled: true,
      folders: ['zh', 'en'],
      fallback: 'en',
    ),
  );

  const fileFallback = AssetsVariantsConfig(
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

  AssetVariantSet grouped(
    List<String> paths, {
    AssetsVariantsConfig variants = bothOn,
  }) {
    return groupAssetVariants(
      posixPaths: paths,
      variants: variants,
    ).assets.single;
  }

  group('selectAdaptivePath', () {
    test('省略 locale 时只选根主题，不套用 fallback 语言', () {
      final logo = grouped(const [
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
        'assets/images/en/logo.svg',
        'assets/images/en/dark/logo.svg',
      ]);
      expect(
        selectAdaptivePath(logo, brightness: 'dark', localeFallback: 'en'),
        'assets/images/dark/logo.svg',
      );
    });

    test('未匹配语言且 fallback 为 en 时用 en 节点的主题', () {
      final logo = grouped(const [
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
        'assets/images/en/logo.svg',
        'assets/images/en/dark/logo.svg',
      ]);
      expect(
        selectAdaptivePath(
          logo,
          brightness: 'dark',
          locale: const AssetLocaleQuery(languageCode: 'ja'),
          localeFallback: 'en',
        ),
        'assets/images/en/dark/logo.svg',
      );
    });

    test('匹配 zh 后缺 dark 用该语言 fallback，不退回根 dark', () {
      final logo = grouped(const [
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
        'assets/images/zh/logo.svg',
      ]);
      expect(
        selectAdaptivePath(
          logo,
          brightness: 'dark',
          locale: const AssetLocaleQuery(languageCode: 'zh'),
          localeFallback: 'en',
        ),
        'assets/images/zh/logo.svg',
      );
    });

    test('没有无语言文件时，未传 locale 的暗色用合成根上的 dark', () {
      final logo = grouped(const [
        'assets/images/en/logo.svg',
        'assets/images/en/dark/logo.svg',
        'assets/images/zh/logo.svg',
        'assets/images/zh/dark/logo.svg',
      ], variants: fileFallback);
      expect(logo.dark, 'assets/images/en/dark/logo.svg');
      expect(
        selectAdaptivePath(logo, brightness: 'dark'),
        'assets/images/en/dark/logo.svg',
      );
      expect(
        selectAdaptivePath(
          logo,
          brightness: 'dark',
          locale: const AssetLocaleQuery(languageCode: 'ja'),
        ),
        'assets/images/en/dark/logo.svg',
      );
      expect(
        selectAdaptivePath(
          logo,
          brightness: 'dark',
          locale: const AssetLocaleQuery(languageCode: 'zh'),
        ),
        'assets/images/zh/dark/logo.svg',
      );
    });

    test('country 优先于 language', () {
      const variants = AssetsVariantsConfig(
        theme: ThemeVariantsConfig.defaults,
        locale: LocaleVariantsConfig(
          enabled: true,
          folders: ['zh', 'zh_CN'],
          fallback: kLocaleFallbackFile,
        ),
      );
      final logo = grouped(const [
        'assets/images/zh/logo.svg',
        'assets/images/zh_CN/logo.svg',
      ], variants: variants);
      expect(
        selectAdaptivePath(
          logo,
          locale: const AssetLocaleQuery(languageCode: 'zh', countryCode: 'CN'),
        ),
        'assets/images/zh_CN/logo.svg',
      );
    });
  });
}
