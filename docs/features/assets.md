---
title: Assets
outline: [2, 4]
---

# Assets

读 `pubspec.yaml` 的 `flutter.assets`，展开目录，写出 `assets.gen.dart`。

没有按主题或语言分目录时，按 [快速使用](#快速使用) 做就够。有 `light/` / `dark/` 或 `zh/` / `en/` 时，见 [主题和语言](#主题和语言)。

## 快速使用

`pubspec.yaml` 里写目录，一般一层就够：

```yaml
flutter:
  assets:
    - assets/
```

配置可以不写，会用默认值。要自己定类名和风格，在项目根放一份 `fast_dev_config.yaml`，**不要**开 `variants`：

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  assets:
    class_name: Assets
    style: nested
```

然后生成：

```sh
dart run fast_dev gen
# 或：dart run build_runner build
```

默认写出 `lib/gen/fast_dev/assets.gen.dart`。建议提交进仓库。

每个文件是一个 `AssetPath`。它是 `extension type`，本身是 `String`，可以直接交给 `Image.asset`、`rootBundle`：

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

想全部挂在根类上，把 `style` 改成 `camel` 或 `snake`：

```dart
Assets.imagesLogo
Assets.images_logo
```

根类是 `abstract final class`，成员是 `static const`。子目录在 `nested` 里是各自的小类。

字段含义见下面的 [配置](#配置)。文件怎么建、怎么加载见 [配置说明](/guide/configuration)。

## 清单从哪来

只认 `flutter.assets`。目录会递归子文件夹。`pubspec.yaml` 里写 `assets/`，就能扫到 `assets/images/logo.svg`、`assets/data/hello.json`。

单文件条目按文件处理。找不到的路径会告警并跳过。

Flutter 的分辨率目录（`2.0x`、`3.0x`）会合并到基准路径，生成结果里只有一份。以 `.` 开头的文件会跳过。

`flutter.assets` 里如果带了 flavors，会当普通路径，并告警。transformers 会忽略，也告警。这两项都不参与生成规则。

`generate.assets.enabled: false` 时不写文件。

## 配置

配置文件怎么建、怎么加载，见 [配置说明](/guide/configuration)。只写要改的字段即可，没写的用默认值。列表整份替换，不是追加。

主题和语言相关字段在 [主题和语言](#主题和语言)。

### `output`

`generate.output`。

| | |
| --- | --- |
| 类型 | 字符串 |
| 默认 | `lib/gen/fast_dev/` |
| 必填 | 否 |

生成文件的目录，相对项目根。只影响 `.gen.dart` 写到哪，不改变 Flutter 打哪些资源。

空字符串会失败。反斜杠会收成 `/`。没有尾斜杠会补上，`lib/gen/fast_dev` 和 `lib/gen/fast_dev/` 一样。

`build_runner` 还可以在应用的 `build.yaml` 里用 `options.output` 覆盖这里，见 [build_runner](/guide/build-runner)。

建议：保持默认，或改成你项目已经在用的 `lib/gen/` 之类。生成文件建议提交进仓库。

### `line_length`

`generate.line_length`。

| | |
| --- | --- |
| 类型 | 正整数 |
| 默认 | `80` |
| 必填 | 否 |

交给 `dart_style` 的行宽。必须大于 `0`。

建议和项目里 `dart format` / `analysis_options.yaml` 的行宽对齐，避免生成文件和手写代码各一行宽。

### `assets.enabled`

`generate.assets.enabled`。

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `true` |
| 必填 | 否 |

`false` 时跳过 assets 生成，不写文件。YAML 里必须是真正的布尔（`true` / `false`），`yes` 这类会失败。

### `assets.class_name`

`generate.assets.class_name`。

| | |
| --- | --- |
| 类型 | 字符串 |
| 默认 | `Assets` |
| 必填 | 否 |

生成文件里的根类名。必须是合法 Dart 标识符：字母或 `_` 开头，后面只能是字母、数字、`_`。`123Assets`、`My-Assets` 都会失败。

建议用大驼峰，比如 `Assets`、`AppAssets`。如果正好叫 `AdaptiveAsset` 或 `AssetPath`，辅助类型会加 `Fd` 前缀，避免撞名。

### `assets.style`

`generate.assets.style`。

| | |
| --- | --- |
| 类型 | `nested` / `camel` / `snake` |
| 默认 | `nested` |
| 必填 | 否 |

路径怎么变成成员名。其它值会失败。

假设文件是 `assets/images/logo.svg`、`assets/data/hello.json`：

| `style` | 用法 |
| --- | --- |
| `nested` | `Assets.images.logo`、`Assets.data.hello` |
| `camel` | `Assets.imagesLogo`、`Assets.dataHello` |
| `snake` | `Assets.images_logo`、`Assets.data_hello` |

`assets/` 这一层在 `nested` 里会摊平，不会出现 `Assets.assets.images`。

建议：目录不深、想按文件夹点进去，用 `nested`。想全部挂在根类上，用 `camel` 或 `snake`。

文件名会收成合法标识符。关键字（`if`、`switch` 等）会避开。同名冲突时会加后缀，保证能编过。

## 主题和语言

::: warning 谨慎使用
没有按主题或语言分目录，不要开。开了之后，配置里的目录名会从路径里剥掉；对不上的业务目录也会被当成变体。生成类型会从 `AssetPath`（`String`）变成 `AdaptiveAsset`，调用也要改成 `.of(context)`。
:::

默认全关。`light/`、`dark/`、`zh/` 都只是普通嵌套目录，生成出来是 `Assets.images.dark.logo` 这种普通路径。

磁盘可以这样放：

```
assets/images/logo.svg
assets/images/dark/logo.svg
assets/images/zh/logo.svg
assets/images/zh/dark/logo.svg
assets/images/en/logo.svg
```

配置里打开对应变体：

```yaml
generate:
  assets:
    variants:
      theme:
        enabled: true
      locale:
        enabled: true
        folders:
          - zh
          - en
        fallback: file
```

这些文件收成一份 `Assets.images.logo`，类型是 `AdaptiveAsset`：

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

下面两段可以只开一个，也可以一起开。一起开时，主题目录名和语言目录名不能重名（忽略大小写，语言还会把 `-` 当成 `_`）。否则 `dark/zh` 分不清谁是主题、谁是语言。

### `theme.enabled`

`generate.assets.variants.theme.enabled`。

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `false` |
| 必填 | 否 |

`true` 之后，`folders.light` / `folders.dark` 里的目录才当变体，不再出现在生成出来的路径成员里。

同一份图可以这样放：

```
assets/images/logo.svg
assets/images/dark/logo.svg
```

生成后是一份 `Assets.images.logo`。没开变体时，会变成 `Assets.images.logo` 和 `Assets.images.dark.logo`。

### `theme.folders`

`generate.assets.variants.theme.folders.light` / `dark`。

| | |
| --- | --- |
| 类型 | 字符串，或字符串列表 |
| 默认 | `light: [light]`，`dark: [dark]` |
| 必填 | 否 |

亮色、暗色目录名。可以写一个，也可以写多个别名：

```yaml
folders:
  light: day          # 和 [day] 一样
  dark: [night, dark]
```

限制：

- 必须是单层目录名，不能带 `/`、`\`，不能是 `.` / `..`
- 不能用密度目录名（`2.0x`、`3.0x`），那是 Flutter 自己的分辨率变体
- `light` 和 `dark` 两边不能出现同一个名字（忽略大小写）

列表是整份替换。只想改暗色目录时，亮色仍保持默认 `[light]`。

主题目录可以出现在路径任意一层，同一条路径里最多剥一次。

### `locale.enabled`

`generate.assets.variants.locale.enabled`。

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `false` |
| 必填 | 否 |

`true` 时必须同时列出 `folders`。空列表会失败，避免把任意两字母目录当成语言。

### `locale.folders`

`generate.assets.variants.locale.folders`。

| | |
| --- | --- |
| 类型 | 字符串，或字符串列表 |
| 默认 | `[]` |
| 必填 | `enabled: true` 时必填 |

要剥掉的语言目录，得自己列出来：

```yaml
folders:
  - zh
  - en
  - zh_CN
```

也可以写成 `folders: zh`。

比较时忽略大小写，`-` 和 `_` 当成一样。`zh-CN` 和 `zh_CN` 会去重，只留先出现的那个。

限制和主题目录一样：单层名，不能是密度目录。和已开启的主题目录也不能重名。

### `locale.fallback`

`generate.assets.variants.locale.fallback`。

| | |
| --- | --- |
| 类型 | 字符串 |
| 默认 | `file` |
| 必填 | 否 |

对不上当前语言时用哪份：

| 值 | 行为 |
| --- | --- |
| `file` | 用没有语言目录的那份文件。`File` 也会收成 `file` |
| 某个语言码 | 必须出现在 `folders` 里，比如 `en` |

空字符串会失败。语言码会按 `folders` 里的写法对齐（`ZH` → `zh`）。

`file` 表示：`assets/images/logo.svg` 是兜底，`assets/images/zh/logo.svg` 是中文。
写成 `en` 表示：没有无语言文件时，用 `en` 那份当兜底。

## 命名

文件名、目录名会收成合法标识符。空格和符号变成 `_`。不能以字母开头会加前缀。Dart 关键字会避开。

根类名撞上 `AssetPath` / `AdaptiveAsset` / `AssetResolveScope` 时，辅助类型加 `Fd` 前缀。

## 建议

- `pubspec.yaml` 写目录，不要把每个文件手列一遍，除非你只想生成其中一部分。
- 没有分主题、分语言，就别开 `variants`。
- 开了变体之后用 `.of(context)`；普通文件继续当 `String` 用。
- 生成文件和手写代码放一起提交，CI 里也可以再跑一遍 `fast_dev gen` 做核对。
