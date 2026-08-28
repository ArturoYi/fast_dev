---
title: CLI
outline: [2, 3]
---

# CLI

入口是 `bin/fast_dev.dart`，逻辑在 `FastDevCommandRunner`。建议在项目根跑。

```sh
dart run fast_dev
dart run fast_dev help
dart run fast_dev help gen
dart run fast_dev config --help
dart run fast_dev config
dart run fast_dev gen
dart run fast_dev -c path/to/custom.yaml gen
```

不带子命令、或 `-h` / `--help` / `help`，都打印用法，退出码 `0`。

## `help`

| 写法 | 作用 |
| --- | --- |
| `dart run fast_dev` | 总览 |
| `dart run fast_dev help` | 同上 |
| `dart run fast_dev -h` / `--help` | 同上 |
| `dart run fast_dev help gen` | 某个命令 |
| `dart run fast_dev gen --help` | 同上 |

未知命令退出码 `64`。

## 退出码

| 码 | 含义 |
| --- | --- |
| `0` | 成功（包括只打印了用法） |
| `1` | 配置或生成失败 |
| `64` | 用法不对 |

## 全局选项

| 选项 | 说明 |
| --- | --- |
| `-c`, `--config <path>` | 指定配置文件。文件得存在，不会退回默认值。 |

不写 `-c` 时，从当前目录往上找 `pubspec.yaml`，再读旁边的 `fast_dev_config.yaml`。没有配置就用默认值，并告警。

建议自己建 `fast_dev_config.yaml`，少用 `-c` 指来指去。`-c` 适合临时试一份配置。

## `config`

打印解析结果：包根、读到的文件、告警、合并后的值。不写文件。

```sh
dart run fast_dev config
```

改完 YAML 先跑这条，确认 `class_name`、`style`、变体是不是你想的那样，再 `gen`。

## `gen`

按配置生成 `assets.gen.dart`。

```sh
dart run fast_dev gen
```

会打印已生成 / 已跳过 / 警告。输出目录看 `generate.output`，默认 `lib/gen/fast_dev/`。

`flutter.assets` 为空、或 `assets.enabled: false` 时，会跳过并说明原因。
