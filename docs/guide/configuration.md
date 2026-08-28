---
title: 配置
outline: [2, 4]
---

# 配置

建议在项目根自己建一份 `fast_dev_config.yaml`，和 `pubspec.yaml` 同级。

没有这份文件也能跑，会用下面的默认值。自己写一份的好处是：类名、风格、输出目录、变体规则都在仓库里，生成结果可预期。

工具不会往 `pubspec.yaml` 里写东西。打进包的清单只认 `flutter.assets`。这份 YAML 只说工具怎么跑。

## 怎么加载

1. `dart run fast_dev -c path/to.yaml gen`：就读你指定的文件。文件必须存在，不会退回默认值。
2. 不写 `-c`：从当前目录往上找 `pubspec.yaml`，再读旁边的 `fast_dev_config.yaml`。
3. 找到包根但没有配置文件：用默认值，并告警。

相对路径的 `-c` 相对你执行命令时的目录。建议在项目根跑 CLI。

看解析结果（不写文件）：

```sh
dart run fast_dev config
```

会打印包根、实际读到的文件、告警、合并后的完整值。

## 合并规则

以默认值为底，YAML 里出现过的字段覆盖。只写一部分就行。

列表是整份替换，不是追加。比如默认 `theme.folders.light` 是 `[light]`，你写成 `light: [day]`，结果就是 `[day]`，不会变成 `[light, day]`。

不认识的键会告警，然后忽略，不会让这次生成失败。

## 完整示例

当前会解析的字段都在这里。按自己的项目改，用不到的可以删，会回落到默认值。

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  line_length: 80
  assets:
    enabled: true
    class_name: Assets
    style: nested # nested | camel | snake
    variants:
      theme:
        enabled: false
        folders:
          light: [light]
          dark: [dark]
      locale:
        enabled: false
        folders: []
        fallback: file
```

## `version`

| | |
| --- | --- |
| 类型 | 整数 |
| 默认 | `1` |
| 必填 | 否 |

现在只认 `1`。不写就当 `1`。写成 `2` 或其它整数会直接失败，避免旧工具默默吃掉新文件。

建议写上 `version: 1`，以后文件打开就知道 schema。

## `generate`

代码生成这一段。现在下面只有 `assets`。

### `generate.output`

| | |
| --- | --- |
| 类型 | 字符串 |
| 默认 | `lib/gen/fast_dev/` |
| 必填 | 否 |

生成文件的目录，相对项目根。只影响 `.gen.dart` 写到哪，不改变 Flutter 打哪些资源。

空字符串会失败。反斜杠会收成 `/`。没有尾斜杠会补上，`lib/gen/fast_dev` 和 `lib/gen/fast_dev/` 一样。

`build_runner` 还可以在应用的 `build.yaml` 里用 `options.output` 覆盖这里，见 [build_runner](./build-runner.md)。

建议：保持默认，或改成你项目已经在用的 `lib/gen/` 之类。生成文件建议提交进仓库。

### `generate.line_length`

| | |
| --- | --- |
| 类型 | 正整数 |
| 默认 | `80` |
| 必填 | 否 |

交给 `dart_style` 的行宽。必须大于 `0`。

建议和项目里 `dart format` / `analysis_options.yaml` 的行宽对齐，避免生成文件和手写代码各一行宽。

### `generate.assets`

资源路径生成。关掉它，这次就不会写 `assets.gen.dart`。

#### `generate.assets.enabled`

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `true` |
| 必填 | 否 |

`false` 时跳过 assets 生成，不写文件。YAML 里必须是真正的布尔（`true` / `false`），`yes` 这类会失败。

#### `generate.assets.class_name`

| | |
| --- | --- |
| 类型 | 字符串 |
| 默认 | `Assets` |
| 必填 | 否 |

生成文件里的根类名。必须是合法 Dart 标识符：字母或 `_` 开头，后面只能是字母、数字、`_`。`123Assets`、`My-Assets` 都会失败。

建议用大驼峰，比如 `Assets`、`AppAssets`。如果正好叫 `AdaptiveAsset` 或 `AssetPath`，辅助类型会加 `Fd` 前缀，避免撞名。

#### `generate.assets.style`

| | |
| --- | --- |
| 类型 | `nested` / `camel` / `snake` |
| 默认 | `nested` |
| 必填 | 否 |

路径怎么变成成员名。其它值会失败。

假设文件是 `assets/images/logo.svg`、`assets/data/hello.json`：

| `style` | 用法 |
| --- | --- |
| `nested` | `Assets.images.logo`、`Assets.data.hello` |
| `camel` | `Assets.imagesLogo`、`Assets.dataHello` |
| `snake` | `Assets.images_logo`、`Assets.data_hello` |

`assets/` 这一层在 `nested` 里会摊平，不会出现 `Assets.assets.images`。

建议：目录不深、想按文件夹点进去，用 `nested`。想全部挂在根类上，用 `camel` 或 `snake`。

文件名会收成合法标识符。关键字（`if`、`switch` 等）会避开。同名冲突时会加后缀，保证能编过。

#### `generate.assets.variants`

主题目录和语言目录。默认全关：`light/`、`dark/`、`zh/` 都只是普通嵌套目录。

只有磁盘上真的按主题或语言分了文件，才打开。随便开的话，业务目录名可能被剥掉。

下面两段可以只开一个，也可以一起开。一起开时，主题目录名和语言目录名不能重名（忽略大小写，语言还会把 `-` 当成 `_`）。否则 `dark/zh` 分不清谁是主题、谁是语言。

##### `variants.theme.enabled`

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `false` |
| 必填 | 否 |

`true` 之后，`folders.light` / `folders.dark` 里的目录才当变体，不再出现在生成出来的路径成员里。

同一份图可以这样放：

```
assets/images/logo.svg
assets/images/dark/logo.svg
```

生成后是一份 `Assets.images.logo`。没开变体时，会变成 `Assets.images.logo` 和 `Assets.images.dark.logo`。

##### `variants.theme.folders.light` / `dark`

| | |
| --- | --- |
| 类型 | 字符串，或字符串列表 |
| 默认 | `light: [light]`，`dark: [dark]` |
| 必填 | 否 |

亮色、暗色目录名。可以写一个，也可以写多个别名：

```yaml
folders:
  light: day          # 和 [day] 一样
  dark: [night, dark]
```

限制：

- 必须是单层目录名，不能带 `/`、`\`，不能是 `.` / `..`
- 不能用密度目录名（`2.0x`、`3.0x`），那是 Flutter 自己的分辨率变体
- `light` 和 `dark` 两边不能出现同一个名字（忽略大小写）

列表是整份替换。只想改暗色目录时，亮色仍保持默认 `[light]`。

主题目录可以出现在路径任意一层，同一条路径里最多剥一次。

##### `variants.locale.enabled`

| | |
| --- | --- |
| 类型 | 布尔 |
| 默认 | `false` |
| 必填 | 否 |

`true` 时必须同时列出 `folders`。空列表会失败，避免把任意两字母目录当成语言。

##### `variants.locale.folders`

| | |
| --- | --- |
| 类型 | 字符串，或字符串列表 |
| 默认 | `[]` |
| 必填 | `enabled: true` 时必填 |

要剥掉的语言目录，得自己列出来：

```yaml
folders:
  - zh
  - en
  - zh_CN
```

也可以写成 `folders: zh`。

比较时忽略大小写，`-` 和 `_` 当成一样。`zh-CN` 和 `zh_CN` 会去重，只留先出现的那个。

限制和主题目录一样：单层名，不能是密度目录。和已开启的主题目录也不能重名。

##### `variants.locale.fallback`

| | |
| --- | --- |
| 类型 | 字符串 |
| 默认 | `file` |
| 必填 | 否 |

对不上当前语言时用哪份：

| 值 | 行为 |
| --- | --- |
| `file` | 用没有语言目录的那份文件。`File` 也会收成 `file` |
| 某个语言码 | 必须出现在 `folders` 里，比如 `en` |

空字符串会失败。语言码会按 `folders` 里的写法对齐（`ZH` → `zh`）。

`file` 表示：`assets/images/logo.svg` 是兜底，`assets/images/zh/logo.svg` 是中文。  
写成 `en` 表示：没有无语言文件时，用 `en` 那份当兜底。

## 建议怎么写

1. 先建文件，把 `output`、`class_name`、`style`、`line_length` 写上。
2. 没有主题 / 语言分目录，就不要开 `variants`。
3. 有 `dark/` 或 `light/`，再开 `theme`。目录不叫这两个名字，改 `folders`。
4. 有 `zh/`、`en/`，再开 `locale`，并且把目录名写进 `folders`。
5. 改完跑 `dart run fast_dev config`，看合并结果和告警。
6. 再跑 `dart run fast_dev gen`。
