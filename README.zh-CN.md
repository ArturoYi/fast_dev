<p align="center">
  <a href="https://arturoyi.github.io/fast_dev/">
    <img src="docs/public/logo.svg" alt="Fast Dev" width="160" />
  </a>
</p>

<h1 align="center">Fast Dev</h1>

<p align="center">
  开发期用的 Flutter 工具<br />
  写在 <code>dev_dependencies</code>
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
  <a href="README.md">English</a>
  ·
  简体中文
  ·
  <a href="https://arturoyi.github.io/fast_dev/">文档</a>
  ·
  <a href="https://github.com/ArturoYi/fast_dev/issues">Issues</a>
</p>

---

## 是什么

根据 `flutter.assets` 生成类型安全的资源路径，根据 `flutter.fonts` 生成 `FontFamily.raleway`。一个包，CLI 和 `build_runner` 都能跑。生成文件进仓库，工具留在开发机和 CI。

如果希望一些业务相关的能力，可以用 [Fast Package](https://github.com/ArturoYi/fast_package)。

---

## 用法

```sh
dart pub add --dev fast_dev
dart pub add --dev build_runner   # 只用 CLI 可以不加
```

或手写：

```yaml
dev_dependencies:
  fast_dev: ^0.0.1-beta.1
  build_runner: ^2.7.2

flutter:
  assets:
    - assets/
```

只用 CLI 时不必写 `build_runner`。已经在用 `build_runner` 时加上 `fast_dev` 就会一起生成。

建议在项目根自己建一份 `fast_dev_config.yaml`，和 `pubspec.yaml` 同级。没有也能跑，有的话类名、风格、输出目录都在仓库里。

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
    package: false # 字体在独立包装、给别人用时改 true
```

每个字段的说明见 [配置](https://arturoyi.github.io/fast_dev/guide/configuration.html)。

```sh
dart run fast_dev help
dart run fast_dev help gen
dart run fast_dev config
dart run fast_dev gen
dart run build_runner watch   # 已经在用 build_runner 时
```

```dart
Image.asset(Assets.images.logo);
Image.asset(Assets.images.logo.of(context)); // 开了 theme / locale 之后
Text('Hello', style: TextStyle(fontFamily: FontFamily.raleway));
```

例子在 [`example/`](example/)。

---

## 贡献

Issue 和 PR 都可以。报问题用 [这个说明](https://arturoyi.github.io/fast_dev/community/bugs.html)。

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [MIT](LICENSE)

喜欢的话，点个 Star 就好。
