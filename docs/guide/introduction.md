---
title: 定位
outline: [2, 3]
---

# 定位

Fast Dev（`fast_dev`）是开发期工具，写在 `dev_dependencies`。

它做一件事：读 `pubspec.yaml` 里的 `flutter.assets`，生成类型安全的 Dart 路径。生成文件进仓库，工具本身不进用户包。

## 和 Fast Package

[Fast Package](https://github.com/ArturoYi/fast_package) 是运行时的包，进 `dependencies`。

这边只在开发机和 CI 上跑。

| | Fast Package | Fast Dev |
| --- | --- | --- |
| 放哪 | `dependencies` | `dev_dependencies` |
| 什么时候 | 应用跑起来之后 | 开发机 / CI |
| 做什么 | 工具方法、扩展、UI | 资源路径代码生成 |
| 进不进用户包 | 进 | 不进 |

可以一起用。

## 怎么划分

打包清单还是 `pubspec.yaml` 的 `flutter.assets`。Flutter 打进 APK / IPA 的，也是这份。

工具怎么跑（输出目录、类名、命名风格、变体目录）写在项目根的 `fast_dev_config.yaml`。建议自己建这份文件，项目里大家看到的是同一套约定。

两边对不上，要到运行时才会发现漏资源。`pubspec.yaml` 没写的路径，生成代码里也不会有。
