<p align="center">
  <a href="https://arturoyi.github.io/fast_dev/en/">
    <img src="docs/public/logo.svg" alt="Fast Dev" width="160" />
  </a>
</p>

<h1 align="center">Fast Dev</h1>

<p align="center">
  Flutter tooling for development time<br />
  Lives in <code>dev_dependencies</code>
</p>

<p align="center">
  <a href="https://github.com/ArturoYi/fast_dev/stargazers">
    <img src="https://img.shields.io/github/stars/ArturoYi/fast_dev?style=flat&logo=github&label=stars" alt="GitHub stars" />
  </a>
  <a href="https://pub.dev/packages/fast_dev">
    <img src="https://img.shields.io/pub/v/fast_dev.svg?label=pub.dev&logo=dart" alt="pub.dev" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License" />
  </a>
</p>

<p align="center">
  English
  ·
  <a href="README.zh-CN.md">简体中文</a>
  ·
  <a href="https://arturoyi.github.io/fast_dev/en/">Docs</a>
  ·
  <a href="https://github.com/ArturoYi/fast_dev/issues">Issues</a>
</p>

---

## What it is

Typed asset paths from `flutter.assets`, and typed font families from `flutter.fonts`. One package, two entry points: CLI and `build_runner`, same output. Generated files are committed. The tool stays on the machine and in CI.

For business-related helpers, see [Fast Package](https://github.com/ArturoYi/fast_package).

---

## Usage

```sh
dart pub add --dev fast_dev
dart pub add --dev build_runner   # skip if CLI-only
```

Or by hand:

```yaml
dev_dependencies:
  fast_dev: ^0.0.1-beta.1
  build_runner: ^2.7.2

flutter:
  assets:
    - assets/
```

Skip `build_runner` if you only run the CLI. If the project already uses `build_runner`, adding `fast_dev` is enough.

Put a `fast_dev_config.yaml` next to `pubspec.yaml`. The tool can run without it. A file in the repo keeps class name, style, and output visible to everyone.

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  line_length: 80
  assets:
    class_name: Assets
    style: nested # nested | camel | snake
  fonts:
    class_name: FontFamily
    package: false # true for a fonts package
```

Field details: [Configuration](https://arturoyi.github.io/fast_dev/en/guide/configuration.html).

```sh
dart run fast_dev help
dart run fast_dev help gen
dart run fast_dev config
dart run fast_dev gen
dart run build_runner watch   # if you already use build_runner
```

```dart
Image.asset(Assets.images.logo);
Image.asset(Assets.images.logo.of(context)); // after theme / locale variants are on
Text('Hello', style: TextStyle(fontFamily: FontFamily.raleway));
```

A small app lives in [`example/`](example/).

---

## Contributing

Issues and PRs are welcome. How to report a problem: [Bugs](https://arturoyi.github.io/fast_dev/en/community/bugs.html).

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [MIT](LICENSE)

If this is useful, a star helps.
