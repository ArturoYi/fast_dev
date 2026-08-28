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

```yaml
dev_dependencies:
  fast_dev: ^0.0.1
  fast_dev_runner: ^0.0.1
  build_runner: ^2.4.0
```

Assets still go in `pubspec.yaml`. Directories are expanded recursively, so one line is usually enough:

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

Every field is in [Configuration](./configuration.md). After you write the file:

```sh
dart run fast_dev config
```

## Generate

```sh
dart run fast_dev gen
```

Default output is `lib/gen/fast_dev/assets.gen.dart`.

If the project already uses `build_runner`, one watch is enough. It runs with the other builders:

```sh
dart run build_runner watch --delete-conflicting-outputs
```

How to sit next to them, and `build.yaml`: [build_runner](./build-runner.md).

## Use

```dart
import 'package:your_app/gen/fast_dev/assets.gen.dart';

Image.asset(Assets.images.logo);
rootBundle.loadString(Assets.data.hello);

// after theme / locale variants are on
Image.asset(Assets.images.logo.of(context));
```

`AssetPath` is a `String`. `Image.asset`, `rootBundle`, and your own APIs can take it as-is.

A small app lives in [`example/`](https://github.com/ArturoYi/fast_dev/tree/main/example). API details: [Assets](/en/features/assets).
