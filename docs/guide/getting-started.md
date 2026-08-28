---
title: 开始
outline: [2, 3]
---

# 开始

## 环境

- Dart SDK 3.12+
- 普通 Flutter / Dart 包（根目录有 `pubspec.yaml`）

## 安装

只写在 `dev_dependencies`。没有运行时 API。

```yaml
dev_dependencies:
  fast_dev: ^0.0.1
  fast_dev_runner: ^0.0.1
  build_runner: ^2.4.0
```

资源清单还是写在 `pubspec.yaml`。目录会递归展开，一般写一层就够：

```yaml
flutter:
  assets:
    - assets/
```

单文件也可以：

```yaml
flutter:
  assets:
    - assets/images/logo.svg
    - assets/data/hello.json
```

## 建配置文件

建议在项目根（和 `pubspec.yaml` 同级）自己建一份 `fast_dev_config.yaml`。

没有这份文件也能跑，会用内置默认值，CLI 会提一句。自己写一份更清楚：类名、风格、输出目录都在仓库里，别人不用猜。

最小可以先这样：

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  line_length: 80
  assets:
    class_name: Assets
    style: nested
```

有 light / dark 或语言目录时，把变体打开。目录结构和 `example/` 类似的话：

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  line_length: 80
  assets:
    class_name: Assets
    style: nested
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

每个字段的含义、默认值和限制见 [配置](./configuration.md)。建完可以用下面这条核对解析结果：

```sh
dart run fast_dev config
```

## 生成

```sh
dart run fast_dev gen
```

默认写出 `lib/gen/fast_dev/assets.gen.dart`。

已经在用 `build_runner` 时，一条 watch 就够，和其它生成器一起跑：

```sh
dart run build_runner watch --delete-conflicting-outputs
```

怎么并列、`build.yaml` 怎么写，见 [build_runner](./build-runner.md)。

## 用

```dart
import 'package:your_app/gen/fast_dev/assets.gen.dart';

Image.asset(Assets.images.logo);
rootBundle.loadString(Assets.data.hello);

// 开了 theme / locale 之后
Image.asset(Assets.images.logo.of(context));
```

`AssetPath` 本身是 `String`，`Image.asset`、`rootBundle`、自己拼的 API 都能直接接。

可跑的例子在 [`example/`](https://github.com/ArturoYi/fast_dev/tree/main/example)。生成 API 的细节见 [Assets](/features/assets)。
