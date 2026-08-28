import 'package:fast_dev/fast_dev.dart';
import 'package:test/test.dart';

void main() {
  const paths = ['assets/data/hello.json', 'assets/images/logo.svg'];

  test('nested 摊平 assets/ 并生成 AssetPath', () {
    final source = generateAssetsSource(
      config: AssetsGenerateConfig.defaults,
      lineLength: 80,
      assetPaths: paths,
    )!;

    expect(source, contains('extension type const AssetPath(String path)'));
    expect(source, contains('abstract final class Assets'));
    expect(source, contains('static const \$AssetsImages images'));
    expect(
      source,
      contains(
        "AssetPath get logo => const AssetPath('assets/images/logo.svg')",
      ),
    );
    expect(
      source,
      contains(
        "AssetPath get hello => const AssetPath('assets/data/hello.json')",
      ),
    );
    expect(source, isNot(contains('Assets.assets')));
  });

  test('camel 与 snake 挂在根类上', () {
    final camel = generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'Assets',
        style: AssetStyle.camel,
      ),
      lineLength: 80,
      assetPaths: paths,
    )!;
    expect(camel, contains('static const AssetPath imagesLogo'));
    expect(camel, contains('static const AssetPath dataHello'));

    final snake = generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'Assets',
        style: AssetStyle.snake,
      ),
      lineLength: 80,
      assetPaths: paths,
    )!;
    expect(snake, contains('static const AssetPath images_logo'));
    expect(snake, contains('static const AssetPath data_hello'));
  });

  test('空列表不生成', () {
    expect(
      generateAssetsSource(
        config: AssetsGenerateConfig.defaults,
        lineLength: 80,
        assetPaths: const [],
      ),
      isNull,
    );
  });

  test('自定义 class_name', () {
    final source = generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'ExampleAssets',
        style: AssetStyle.nested,
      ),
      lineLength: 100,
      assetPaths: paths,
    )!;
    expect(source, contains('abstract final class ExampleAssets'));
    expect(source, contains(r'$ExampleAssetsImages'));
    expect(source, contains('// dart format width=100'));
  });

  test('variants 关闭时 dark 仍是嵌套目录', () {
    final source = generateAssetsSource(
      config: AssetsGenerateConfig.defaults,
      lineLength: 80,
      assetPaths: const [
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
      ],
    )!;
    expect(source, contains(r'$AssetsImagesDark'));
    expect(source, isNot(contains('class AdaptiveAsset')));
    expect(source, isNot(contains("import 'package:flutter/material.dart'")));
  });

  test('只开 theme 且存在变体时生成 AdaptiveAsset，不再生成 dark 目录类', () {
    final source = generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'Assets',
        style: AssetStyle.nested,
        variants: AssetsVariantsConfig(
          theme: ThemeVariantsConfig(
            enabled: true,
            lightFolders: ['light'],
            darkFolders: ['dark'],
          ),
          locale: LocaleVariantsConfig.defaults,
        ),
      ),
      lineLength: 80,
      assetPaths: const [
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
      ],
    )!;
    expect(source, contains("import 'package:flutter/material.dart'"));
    expect(source, contains('class AdaptiveAsset'));
    expect(source, contains('class AssetResolveScope'));
    expect(source, contains('AdaptiveAsset get logo'));
    expect(source, contains("dark: AssetPath('assets/images/dark/logo.svg')"));
    expect(source, contains('Theme.of(context).brightness'));
    expect(source, isNot(contains(r'$AssetsImagesDark')));
  });

  test('variants 已开但没有变体文件时不引入 Flutter', () {
    final source = generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'Assets',
        style: AssetStyle.nested,
        variants: AssetsVariantsConfig(
          theme: ThemeVariantsConfig(
            enabled: true,
            lightFolders: ['light'],
            darkFolders: ['dark'],
          ),
          locale: LocaleVariantsConfig.defaults,
        ),
      ),
      lineLength: 80,
      assetPaths: paths,
    )!;
    expect(source, isNot(contains("import 'package:flutter/material.dart'")));
    expect(source, isNot(contains('class AdaptiveAsset')));
    expect(
      source,
      contains(
        "AssetPath get logo => const AssetPath('assets/images/logo.svg')",
      ),
    );
  });

  test('theme+locale 生成 locales 映射，json 仍是 AssetPath', () {
    const variants = AssetsVariantsConfig(
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
    final warnings = <String>[];
    final source = generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'Assets',
        style: AssetStyle.nested,
        variants: variants,
      ),
      lineLength: 80,
      assetPaths: const [
        'assets/data/hello.json',
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
        'assets/images/zh/logo.svg',
      ],
      warnings: warnings,
    )!;
    expect(warnings, isEmpty);
    expect(source, contains("AssetPath get hello"));
    expect(source, contains('AdaptiveAsset get logo'));
    expect(source, contains("'zh': AdaptiveAsset("));
    expect(source, contains("static const String? localeFallback = 'en'"));
    expect(source, contains("replaceAll('-', '_')"));
    expect(source, contains('locales.isEmpty || locale == null'));
  });

  test('class_name 与辅助类型冲突时加 Fd 前缀', () {
    final source = generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'AdaptiveAsset',
        style: AssetStyle.nested,
        variants: AssetsVariantsConfig(
          theme: ThemeVariantsConfig(
            enabled: true,
            lightFolders: ['light'],
            darkFolders: ['dark'],
          ),
          locale: LocaleVariantsConfig.defaults,
        ),
      ),
      lineLength: 80,
      assetPaths: const [
        'assets/images/logo.svg',
        'assets/images/dark/logo.svg',
      ],
    )!;
    expect(source, contains('abstract final class AdaptiveAsset'));
    expect(source, contains('class FdAdaptiveAsset'));
    expect(source, contains('FdAdaptiveAsset get logo'));
  });

  test('重复变体写入 warnings', () {
    final warnings = <String>[];
    generateAssetsSource(
      config: const AssetsGenerateConfig(
        enabled: true,
        className: 'Assets',
        style: AssetStyle.nested,
        variants: AssetsVariantsConfig(
          theme: ThemeVariantsConfig(
            enabled: true,
            lightFolders: ['light'],
            darkFolders: ['dark', 'night'],
          ),
          locale: LocaleVariantsConfig.defaults,
        ),
      ),
      lineLength: 80,
      assetPaths: const [
        'assets/images/dark/logo.svg',
        'assets/images/night/logo.svg',
      ],
      warnings: warnings,
    );
    expect(warnings, isNotEmpty);
    expect(warnings.single, contains('已保留前者'));
  });
}
