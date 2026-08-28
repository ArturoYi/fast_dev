---
title: Assets
outline: [2, 4]
---

# Assets

读 `pubspec.yaml` 的 `flutter.assets`，展开目录，写出 `assets.gen.dart`。

## 清单从哪来

只认 `flutter.assets`。目录会递归子文件夹。`pubspec.yaml` 里写 `assets/`，就能扫到 `assets/images/logo.svg`、`assets/data/hello.json`。

单文件条目按文件处理。找不到的路径会告警并跳过。

Flutter 的分辨率目录（`2.0x`、`3.0x`）会合并到基准路径，生成结果里只有一份。以 `.` 开头的文件会跳过。

`flutter.assets` 里如果带了 flavors，会当普通路径，并告警。transformers 会忽略，也告警。这两项都不参与生成规则。

`generate.assets.enabled: false` 时不写文件。

## 生成到哪

`{generate.output}/assets.gen.dart`，默认 `lib/gen/fast_dev/assets.gen.dart`。

建议把生成文件提交进仓库。改资源或配置后重新跑：

```sh
dart run fast_dev gen
```

## 普通路径

没开变体时，每个文件是一个 `AssetPath`。它是 `extension type`，本身是 `String`：

```dart
import 'package:your_app/gen/fast_dev/assets.gen.dart';

Image.asset(Assets.images.logo);
await rootBundle.loadString(Assets.data.hello);
debugPrint(Assets.images.logo); // assets/images/logo.svg
```

`nested`（默认）按目录点进去，并且摊平顶层的 `assets/`：

```dart
Assets.images.logo
Assets.data.hello
```

`camel` / `snake` 挂在根类上：

```dart
Assets.imagesLogo
Assets.images_logo
```

根类是 `abstract final class`，成员是 `static const`。子目录在 `nested` 里是各自的小类。

## 主题和语言

磁盘可以这样放：

```
assets/images/logo.svg
assets/images/dark/logo.svg
assets/images/zh/logo.svg
assets/images/zh/dark/logo.svg
assets/images/en/logo.svg
```

配置里打开对应变体之后，这些文件收成一份 `Assets.images.logo`，类型是 `AdaptiveAsset`。

```dart
Image.asset(Assets.images.logo.of(context));

Assets.images.logo.resolve(
  brightness: Brightness.dark,
  locale: const Locale('zh'),
);
```

解析顺序：

1. 语言 + 主题
2. 只有语言
3. 只有主题
4. `fallback`（默认用没有语言目录的文件）

`of(context)` 读 `Theme` 的亮度和 `Localizations` 的语言。子树里想盖掉，包一层 `AssetResolveScope`：

```dart
AssetResolveScope(
  brightness: Brightness.dark,
  locale: const Locale('zh'),
  child: Image.asset(Assets.images.logo.of(context)),
)
```

`resolve` 不需要 `BuildContext`。省略 `locale` 时只按主题看根节点，不会自动套 `locale.fallback` 里的语言码。

只有变体文件、没有无语言文件时，根上的 `fallback` 会按配置回退（`file` 或某个语言）。只有 dark、没有 light 时，无主题会回退到 dark。

`zh-CN` 和 `zh_CN` 当成同一语言。`Locale` 匹配时国家优先于语言。

没有变体文件时，即使配置里开了 `variants`，生成结果仍是普通 `AssetPath`，也不会多引 Flutter。

## 命名

文件名、目录名会收成合法标识符。空格和符号变成 `_`。不能以字母开头会加前缀。Dart 关键字会避开。

根类名撞上 `AssetPath` / `AdaptiveAsset` / `AssetResolveScope` 时，辅助类型加 `Fd` 前缀。

## 建议

- `pubspec.yaml` 写目录，不要把每个文件手列一遍，除非你只想生成其中一部分。
- 没有分主题、分语言，就别开 `variants`。
- 开了变体之后用 `.of(context)`；普通文件继续当 `String` 用。
- 生成文件和手写代码放一起提交，CI 里也可以再跑一遍 `fast_dev gen` 做核对。
