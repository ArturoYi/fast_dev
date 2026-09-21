---
title: build_runner
outline: [2, 3]
---

# build_runner

`fast_dev` 自带 Builder。结果和 `dart run fast_dev gen` 一样。目录还是看 `fast_dev_config.yaml` 的 `generate.output`。

只用 CLI 时不必装 `build_runner`。已经在用 `build_runner` 时，加 `fast_dev` 就会一起跑。

## 安装

```yaml
dev_dependencies:
  fast_dev: ^0.0.1-beta.1
  build_runner: ^2.7.2
```

项目里已经在用 `build_runner` 时，把 `fast_dev` 加进现有的 `dev_dependencies` 就行，不要另开一套。

## 命令

一条命令会跑这个包里**所有**已启用的 Builder。资源生成和其它代码生成一起出，不用分别 watch。

```sh
# 生成一次
dart run build_runner build

# 盯着改动，改 dart、资源或配置都会重跑
dart run build_runner watch
```

只想生成资源、不走 `build_runner`：

```sh
dart run fast_dev gen
```

只想重跑某一种输出（少用，日常 watch 不必加）：

```sh
# 只重跑 lib 下的生成
dart run build_runner build --build-filter="lib/**"

# watch 同样可以加 filter，但会漏掉 assets/ 和配置，一般不要这样盯资源
dart run build_runner watch --build-filter="lib/**"
```

同时开两个 `watch` 没必要，也容易抢文件。一个终端里一条 `watch` 就够。

项目里已有其它 Builder、又不想跑 Fast Dev 时，在应用的 `build.yaml` 里关掉：

```yaml
targets:
  $default:
    builders:
      fast_dev:fast_dev:
        enabled: false
```

## 和其它生成器一起

和项目里其它走 `build_runner` 的包一样：并列写在 `dev_dependencies`，共用这一条命令。

```sh
dart run build_runner watch
```

改 `lib/` 里的源码，该出的生成文件会出。加图片、改 `flutter.fonts` 或改 `fast_dev_config.yaml`，会出 `assets.gen.dart` / `fonts.gen.dart`。不用为 Fast Dev 再开一个进程。

## watch 要看见资源和配置

默认源集合有 `lib/**`，其它生成器盯的 `.dart` 本来就在里面。`assets/` 和 `fast_dev_config.yaml` 不在默认集合里。字体族写在 `pubspec.yaml`，改它才会重出 `fonts.gen.dart`。想在加图、改字体清单或改配置时自动重跑，在应用的 `build.yaml` 里把它们加进 `sources.include`，**保留** `lib/**`：

```yaml
targets:
  $default:
    sources:
      include:
        - $package$
        - lib/**
        - test/**
        - pubspec.yaml
        - fast_dev_config.yaml
        - assets/**
```

`lib/**` 不要拿掉，否则其它生成器的 watch 会停。

## 覆盖输出目录

一般改配置文件里的 `generate.output` 就够。要只在 `build_runner` 里换目录：

```yaml
targets:
  $default:
    builders:
      fast_dev:fast_dev:
        options:
          output: lib/generated/
```

## 怎么落盘

Builder 先写 cache 清单 `.fast_dev.manifest.json`，再由 post-process 落到源码树。`.gen.dart` 的路径来自配置，没法提前写进 `build_extensions`。

上一轮写过、这一轮没有的文件，会按 `.dart_tool/fast_dev/owned_outputs.json` 删掉。包外路径会拒绝。
