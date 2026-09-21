---
title: 配置
outline: [2, 3]
---

# 配置

建议在项目根自己建一份 `fast_dev_config.yaml`，和 `pubspec.yaml` 同级。

没有这份文件也能跑，会用下面的默认值。自己写一份的好处是：类名、风格、输出目录、变体规则都在仓库里，生成结果可预期。

哪些资源会打进应用，只看 `pubspec.yaml` 的 `flutter.assets` / `flutter.fonts`。`fast_dev_config.yaml` 不参与打包，只决定代码怎么生成（输出目录、类名、风格、变体）。

各个模块读哪些字段、限制是什么，见对应页面：[Assets](/features/assets#配置)、[Fonts](/features/fonts#配置)。主题和语言见 [主题和语言](/features/assets#主题和语言)。

## 怎么加载

1. `dart run fast_dev -c path/to.yaml gen`：就读你指定的文件。文件必须存在，不会退回默认值。
2. 不写 `-c`：从当前目录往上找 `pubspec.yaml`，再读旁边的 `fast_dev_config.yaml`。
3. 找到包根但没有配置文件：用默认值，并告警。

相对路径的 `-c` 相对你执行命令时的目录。建议在项目根跑 CLI，少用 `-c` 指来指去。`-c` 适合临时试一份配置。

## 合并规则

以默认值为底，YAML 里出现过的字段覆盖。只写一部分就行。

列表是整份替换，不是追加。比如默认 `theme.folders.light` 是 `[light]`，你写成 `light: [day]`，结果就是 `[day]`，不会变成 `[light, day]`。

不认识的键会告警，然后忽略，不会让这次生成失败。预留键也一样：`imports`、`generate.colors` 现在写了只会告警，不会当成已经实现。

建议写上 `version: 1`。现在只认 `1`，不写就当 `1`，写成其它整数会直接失败。

## 核对解析结果

改完 YAML 先跑这条（不写文件）：

```sh
dart run fast_dev config
```

会打印包根、实际读到的文件、告警、合并后的完整值。确认没问题再 `dart run fast_dev gen`。

`build_runner` 还可以在应用的 `build.yaml` 里用 `options.output` 覆盖输出目录，见 [build_runner](./build-runner.md)。

## 默认配置

当前会解析的字段都在这里，值就是内置默认值。按自己的项目改，用不到的可以删。

每个字段怎么用，见对应模块。[Assets](/features/assets#配置)、[Fonts](/features/fonts#配置)。主题和语言字段见 [主题和语言](/features/assets#主题和语言)。

```yaml
# schema。现在只认 1。不写就当 1。其它整数会直接失败。
version: 1

# 代码生成。现在下面有 assets 和 fonts。
# 预留键 colors 写了会告警，不会当成已经实现。
generate:
  # 生成文件目录，相对项目根。只决定 .gen.dart 写到哪，
  # 不改变 Flutter 打哪些资源。空字符串会失败。
  # 反斜杠收成 /。没有尾斜杠会补上。
  output: lib/gen/fast_dev/

  # 交给 dart_style 的行宽。必须大于 0。
  # 建议和项目里 dart format / analysis_options.yaml 对齐。
  line_length: 80

  # 资源路径生成。关掉就不会写 assets.gen.dart。
  # 字段说明见 Assets。
  assets:
    # false 时跳过。YAML 里必须是真正的布尔（true / false）。
    enabled: true

    # 生成文件里的根类名。必须是合法 Dart 标识符，建议大驼峰。
    class_name: Assets

    # 路径怎么变成成员名：nested | camel | snake
    style: nested

    # 主题目录和语言目录。默认全关：light/、dark/、zh/ 都只是普通嵌套目录。
    # 只有磁盘上真的按主题或语言分了文件，才打开。详见 Assets。
    variants:
      theme:
        # true 之后，folders.light / folders.dark 里的目录才当变体。
        enabled: false
        folders:
          # 亮色、暗色目录名。可以写一个字符串，也可以写列表。
          # 列表整份替换，不是追加。
          light: [light]
          dark: [dark]
      locale:
        # true 时必须同时列出 folders。空列表会失败。
        enabled: false
        # 要剥掉的语言目录，得自己列出来。也可以写成 folders: zh。
        folders: []
        # 对不上当前语言时用哪份：
        # file = 没有语言目录的那份文件；或某个 folders 里的语言码。
        fallback: file

  # 字体族生成。关掉就不会写 fonts.gen.dart。
  # 字段说明见 Fonts。
  fonts:
    # false 时跳过。YAML 里必须是真正的布尔（true / false）。
    enabled: true

    # 生成文件里的根类名。必须是合法 Dart 标识符，建议大驼峰。
    class_name: FontFamily

    # true 时按库模式生成 packages/$package/Family。
    # 应用自己用字体保持 false。
    package: false

    # 生成 FontFamily.fallbacks，交给 TextStyle.fontFamilyFallback。
    # 必须是 flutter.fonts 里的 family。空列表不生成该成员。
    fallbacks: []
```

## 建议怎么写

1. 先建文件。只写要改的字段即可。
2. 没有主题 / 语言分目录，就不要开 `variants`。
3. 有 `dark/` 或 `light/`，再开 `theme`。目录不叫这两个名字，改 `folders`。
4. 有 `zh/`、`en/`，再开 `locale`，并且把目录名写进 `folders`。
5. 改完跑 `dart run fast_dev config`，看合并结果和告警。
6. 再跑 `dart run fast_dev gen`。
