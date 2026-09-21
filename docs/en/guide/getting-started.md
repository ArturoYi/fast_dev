---
title: Start
outline: [2, 3]
---

# Start

## Setup

- Dart SDK 3.12+
- A normal Flutter / Dart package (`pubspec.yaml` at the root)

## Install

`dev_dependencies` only. No runtime API.

```sh
dart pub add --dev fast_dev
dart pub add --dev build_runner   # skip if CLI-only
```

Or by hand:

```yaml
dev_dependencies:
  fast_dev: ^0.0.1-beta.1
  build_runner: ^2.7.2
```

Skip `build_runner` if you only run `dart run fast_dev gen`. If the project already uses `build_runner`, adding `fast_dev` is enough.

Assets still go in `pubspec.yaml`. Directories are expanded recursively, so one line is usually enough.

::: danger 2.0x / 3.0x are not supported
Asset generation **does not** support Flutter density folders (`2.0x` / `3.0x`) and will not collapse them to a base path. Do not lay out multi-resolution folders. Details: [Assets](/en/features/assets).
:::

```yaml
flutter:
  assets:
    - assets/
```

Or list files:

```yaml
flutter:
  assets:
    - assets/images/logo.svg
    - assets/data/hello.json
```

## Create a config file

Put `fast_dev_config.yaml` next to `pubspec.yaml`.

The tool can run without it and will use defaults (the CLI mentions that). A file in the repo is clearer: class name, style, and output are visible to everyone.

A small start:

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  line_length: 80
  assets:
    class_name: Assets
    style: nested
```

If you have light / dark or locale folders, turn variants on. Something like `example/`:

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

How to create and load the file: [Configuration](./configuration.md). Field details: [Assets](/en/features/assets#config), [Fonts](/en/features/fonts#config). After you write the file:

```sh
dart run fast_dev config
```

## Generate

```sh
dart run fast_dev gen
```

Default output is `lib/gen/fast_dev/assets.gen.dart`. If `pubspec.yaml` lists `flutter.fonts`, it also writes `fonts.gen.dart`.

If the project already uses `build_runner`, one watch is enough. It runs with the other builders:

```sh
dart run build_runner watch
```

How to sit next to them, and `build.yaml`: [build_runner](./build-runner.md).

## Use

```dart
import 'package:your_app/gen/fast_dev/assets.gen.dart';
import 'package:your_app/gen/fast_dev/fonts.gen.dart';

Image.asset(Assets.images.logo);
rootBundle.loadString(Assets.data.hello);

// after theme / locale variants are on
Image.asset(Assets.images.logo.of(context));

Text('Hello', style: TextStyle(fontFamily: FontFamily.raleway));
```

`AssetPath` is a `String`. `Image.asset`, `rootBundle`, and your own APIs can take it as-is. `FontFamily.raleway` is a `String` for `TextStyle.fontFamily`.

A small app lives in [`example/`](https://github.com/ArturoYi/fast_dev/tree/main/example). API details: [Assets](/en/features/assets), [Fonts](/en/features/fonts).
