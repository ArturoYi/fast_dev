---
title: 定位
outline: [2, 3]
---

# 定位

Fast Dev（`fast_dev`）是开发期工具，写在 `dev_dependencies`。一个包，两套入口：`dart run fast_dev gen` 和 `build_runner`，结果一样。只用 CLI 不必装 `build_runner`。

它做一件事：读 `pubspec.yaml` 里的 `flutter.assets`，生成类型安全的 Dart 路径。生成文件进仓库，工具本身不进用户包。

如果希望一些业务相关的能力，可以用 [Fast Package](https://github.com/ArturoYi/fast_package)。

## 怎么划分

打包清单还是 `pubspec.yaml` 的 `flutter.assets`。Flutter 打进 APK / IPA 的，也是这份。

工具怎么跑（输出目录、类名、命名风格、变体目录）写在项目根的 `fast_dev_config.yaml`。建议自己建这份文件，项目里大家看到的是同一套约定。

两边对不上，要到运行时才会发现漏资源。`pubspec.yaml` 没写的路径，生成代码里也不会有。
