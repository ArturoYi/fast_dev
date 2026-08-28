# 计划

开发期工具，现在只做 assets。后面按阶段加。预留键可以先写，这版会告警，不会当成已经实现。

文档站：[计划](https://arturoyi.github.io/fast_dev/guide/roadmap.html)。

## 阶段

| 阶段 | 状态 | 内容 |
| --- | --- | --- |
| **v0.0.x** | 进行中 | assets 生成；CLI（`config` / `gen`）；`build_runner`（同一个 `fast_dev` 包）；文档站 |
| **v0.1** | 计划 | 稳定现有 API；补测试与示例 |
| **v0.2** | 计划 | fonts 生成器 |
| **v0.3** | 计划 | colors 生成器 |
| **v0.4** | 计划 | `fast_dev imports` |
| **更后面** | 想想 | flavors、transformers |

## 怎么加生成器

别在 `planGenerate` 里堆 `if`：

1. 实现 `Generator`（`id` + `generate(GeneratorContext)`）。
2. 把实例加进 `builtInGenerators`（`lib/src/generate/plan.dart`）。
3. 把配置键从预留集合挪到 known 集合，并补上解析：
   - 根级：`kReservedRootConfigKeys` → `kKnownRootConfigKeys`
   - `generate` 段：`kReservedGenerateConfigKeys` → `kKnownGenerateConfigKeys`
4. 要读盘的话，在 `runGenerate` / `composeGenerate`（`lib/src/builder/compose.dart`）里准备好，放进 `GeneratorContext`。
5. 新 CLI 加在 `FastDevCommandRunner.addCommand` 旁边。

预留键先写也行，只会告警。

## 计划中的生成器

### fonts（v0.2）

- 读 `pubspec.yaml` 的 `flutter.fonts`。
- 生成 `fonts.gen.dart`（字体族名字常量）。
- 配置段：`generate.fonts`（`enabled`、`class_name`）。
- 接入时把 `fonts` 从 `kReservedGenerateConfigKeys` 移走。

### colors（v0.3）

- 从 YAML（或后续 JSON）读色值，生成 `colors.gen.dart`。
- 配置段：`generate.colors`（`enabled`、`class_name`、`inputs`）。
- 颜色文件不在 `flutter.assets` 的语义里，但用户常把 YAML 放在 `assets/` 下。接入后应把 `inputs` 传给资源展开的 `exclude`，避免清单文件出现在 `Assets` 里。

### imports（v0.4）

- 整理 Dart import：dart SDK / Flutter SDK / 第三方 package / relative。
- 独立 CLI 命令：`fast_dev imports`。
- 配置根键：`imports`（`enabled`、`comments`、`group_flutter`、`flutter_packages`、`include`、`exclude`）。
- 默认在分组之间写注释，避免 `dart format` 把空行挤掉后 Flutter 组与第三方组粘在一起。

## 其它

- `flutter.assets` 的 **flavors**：v1 当普通资源并告警；后续可按 flavor 拆生成文件。
- **transformers**：目前忽略并告警。
- 生成器之间的输入协调（例如 colors 排除名单）优先做成 `Generator` 上的可选钩子，而不是让 assets 生成器认识其它生成器。
- 不在表里的想法先开 Issue。如果希望一些业务相关的能力，可以用 [Fast Package](https://github.com/ArturoYi/fast_package)。
