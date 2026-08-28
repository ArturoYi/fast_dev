---
title: About
outline: [2, 3]
---

# About

Fast Dev (`fast_dev`) is a dev-time tool. It goes in `dev_dependencies`.

It reads `flutter.assets` from `pubspec.yaml` and writes typed Dart paths. Generated files are committed. The tool is not.

## Fast Package

[Fast Package](https://github.com/ArturoYi/fast_package) is a runtime package. It goes in `dependencies`.

This one runs on your machine and in CI.

| | Fast Package | Fast Dev |
| --- | --- | --- |
| Where | `dependencies` | `dev_dependencies` |
| When | App runtime | Dev machine / CI |
| What | Utils, extensions, UI | Typed asset paths |
| Ships with the app | Yes | No |

You can use both.

## Split

What gets packed is still `flutter.assets` in `pubspec.yaml`. That is also what Flutter puts in the APK / IPA.

How the tool runs (output dir, class name, style, variant folders) lives in `fast_dev_config.yaml` at the package root. Create that file so the project has one obvious convention.

If the two lists drift, you notice at runtime. A path missing from `pubspec.yaml` will not show up in the generated file.
