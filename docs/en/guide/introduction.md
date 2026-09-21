---
title: About
outline: [2, 3]
---

# About

Fast Dev (`fast_dev`) is a dev-time tool. It goes in `dev_dependencies`. One package, two entry points: `dart run fast_dev gen` and `build_runner`, same output. CLI-only projects can skip `build_runner`.

It reads `flutter.assets` and `flutter.fonts` from `pubspec.yaml` and writes typed Dart references. Generated files are committed. The tool is not.

If you want business-related helpers, you can use [Fast Package](https://github.com/ArturoYi/fast_package).

## Split

What gets packed is still `flutter.assets` / `flutter.fonts` in `pubspec.yaml`. That is also what Flutter puts in the APK / IPA.

How the tool runs (output dir, class name, style, variant folders) lives in `fast_dev_config.yaml` at the package root. Create that file so the project has one obvious convention.

If the two lists drift, you notice at runtime. A path or font family missing from `pubspec.yaml` will not show up in the generated file.
