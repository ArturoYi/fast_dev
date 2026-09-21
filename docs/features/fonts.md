---
title: Fonts
outline: [2, 4]
---

# Fonts

读 `pubspec.yaml` 的 `flutter.fonts`，写出 `fonts.gen.dart`。

生成强类型常量 `FontFamily.raleway`，不要再写 `fontFamily: "Raleway"`。拼写错误会在编译期报错，IDE 能补全，重构也安全。

## 快速使用

字体清单只写在 `pubspec.yaml`，和 Flutter 自己用的是同一份：

```yaml
flutter:
  fonts:
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Regular.ttf
        - asset: fonts/Raleway-Italic.ttf
          style: italic
    - family: RobotoMono
      fonts:
        - asset: fonts/RobotoMono-Regular.ttf
        - asset: fonts/RobotoMono-Bold.ttf
          weight: 700
```

配置可以不写，会用默认值。要自己定类名，在项目根放一份 `fast_dev_config.yaml`：

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  fonts:
    class_name: FontFamily
```

然后生成：

```sh
dart run fast_dev gen
# 或：dart run build_runner build
# 盯着改动：dart run build_runner watch
```

默认写出 `lib/gen/fast_dev/fonts.gen.dart`。建议提交进仓库。

```dart
import 'package:your_app/gen/fast_dev/fonts.gen.dart';

Text(
  'Hello',
  style: TextStyle(fontFamily: FontFamily.raleway),
);

Text(
  'Hello 你好',
  style: TextStyle(
    fontFamily: FontFamily.raleway,
    fontFamilyFallback: FontFamily.fallbacks,
  ),
);
```

`fallbacks` 要在配置里列出，见 [`fonts.fallbacks`](#fontsfallbacks)。不写就不生成这个成员；也可以自己拼 `const [FontFamily.notoSansSC]`。

根类是 `abstract final class`，成员是 `static const String`。字段含义见下面的 [配置](#配置)。文件怎么建、怎么加载见 [配置说明](/guide/configuration)。

私有包、多模块要把字体导出给别的包用，见 [package 库模式](#package-库模式)。

## 清单从哪来

只认 `flutter.fonts`。每个条目必须是带 `family` 的键值对。同一 `family` 出现两次时保留第一次，并告警。同一族里重复的 `asset` 路径会去掉。

缺少 `family`、`fonts` 不是列表、某条没有 `asset`，会告警并跳过那一条。条目不是 Map 会失败。

`generate.fonts.enabled: false` 时不写文件。

生成只依赖族名，不扫字体文件内容。加新字体族必须改 `pubspec.yaml`（Flutter 本来也要求这样写）。

## 配置

配置文件怎么建、怎么加载，见 [配置说明](/guide/configuration)。只写要改的字段即可，没写的用默认值。

输出目录和行宽与 assets 共用 `generate.output` / `generate.line_length`。

### `fonts.enabled`

`generate.fonts.enabled`。

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `true` |
| 必填 | 否 |

`false` 时跳过 fonts 生成，不写文件。YAML 里必须是真正的布尔（`true` / `false`）。

### `fonts.class_name`

`generate.fonts.class_name`。

| | |
| --- | --- |
| 类型 | 字符串 |
| 默认 | `FontFamily` |
| 必填 | 否 |

生成文件里的根类名。必须是合法 Dart 标识符：字母或 `_` 开头，后面只能是字母、数字、`_`。`123Fonts`、`My-Fonts` 都会失败。

建议用大驼峰，比如 `FontFamily`、`AppFonts`。

### `fonts.package`

`generate.fonts.package`。

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `false` |
| 必填 | 否 |

`true` 时按 [package 库模式](#package-库模式) 生成。包名来自 `pubspec.yaml` 的 `name`。没有 `name` 时告警，并退回应用模式。

### `fonts.fallbacks`

`generate.fonts.fallbacks`。

| | |
| --- | --- |
| 类型 | 字符串，或字符串列表 |
| 默认 | `[]` |
| 必填 | 否 |

要放进 `FontFamily.fallbacks` 的族名，必须是 `flutter.fonts` 里已经声明的 `family`，顺序就是 fallback 顺序。空列表（默认）不生成这个成员。列表整份替换。也可以写成 `fallbacks: NotoSansSC`。

```yaml
generate:
  fonts:
    fallbacks:
      - NotoSansSC
      - NotoNaskh
```

```dart
static const List<String> fallbacks = [notoSansSC, notoNaskh];
```

```dart
TextStyle(
  fontFamily: FontFamily.raleway,
  fontFamilyFallback: FontFamily.fallbacks,
);
```

名字对不上 `flutter.fonts` 的 family 会失败。重复项只留第一次。空字符串会失败。

这只是一份 `List<String>`，给 `fontFamilyFallback` 用。不按语言换主字体。

## package 库模式

多模块或私有包装了字体、要给其它包用时打开。应用自己用字体，保持默认 `false`。

```yaml
generate:
  fonts:
    package: true
```

假设包名是 `design_system`，生成：

```dart
abstract final class FontFamily {
  static const String package = 'design_system';

  /// Font family: Raleway
  static const String raleway = 'packages/$package/Raleway';
}
```

消费方直接当 `fontFamily` 用，**不要**再传 `package:`，否则前缀会叠两次：

```dart
import 'package:design_system/gen/fast_dev/fonts.gen.dart';

TextStyle(fontFamily: FontFamily.raleway);
```

声明字体的包自己用，也是这一套常量。

## 命名

族名收成小驼峰成员：`Raleway` → `raleway`，`RobotoMono` → `robotoMono`，`Arial Black` → `arialBlack`。

空格和符号变成词边界。不能以字母开头会加前缀。Dart 关键字会加 `_`。同名冲突时加后缀，保证能编过。

库模式下会先占用 `package` 这个成员名。写了 `fallbacks` 时会占用 `fallbacks`。族名正好撞上这两个，会加后缀。

## 建议

- 字体清单只写在 `pubspec.yaml` 的 `flutter.fonts`。工具不另开一份清单。
- 应用用默认配置；只有字体在独立包装、给别人用时才开 `package: true`。
- 开了库模式之后，消费方不要再写 `package: FontFamily.package`。
- 生成文件和手写代码放一起提交。已经在用 `build_runner` 时，一条 `watch` 就够，改 `pubspec.yaml` 或配置会重跑。
