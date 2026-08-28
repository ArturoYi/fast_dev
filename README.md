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
  <a href="https://arturoyi.github.io/fast_dev/">文档</a>
  ·
  <a href="https://arturoyi.github.io/fast_dev/en/">English</a>
  ·
  <a href="https://github.com/ArturoYi/fast_dev/issues">Issues</a>
</p>

---

## 是什么

根据 `flutter.assets` 生成类型安全的资源路径。生成文件进仓库，工具留在开发机和 CI。

[Fast Package](https://github.com/ArturoYi/fast_package) 是运行时的包。这边是开发期。

| | Fast Package | Fast Dev |
| --- | --- | --- |
| 放哪 | `dependencies` | `dev_dependencies` |
| 什么时候 | 应用跑起来之后 | 开发机 / CI |
| 做什么 | 工具方法、扩展、UI | 资源路径代码生成 |
| 进不进用户包 | 进 | 不进 |

---

## 用法

```yaml
dev_dependencies:
  fast_dev: ^0.0.1
  fast_dev_runner: ^0.0.1
  build_runner: ^2.4.0

flutter:
  assets:
    - assets/
```

建议在项目根自己建一份 `fast_dev_config.yaml`，和 `pubspec.yaml` 同级。没有也能跑，有的话类名、风格、输出目录都在仓库里。

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  line_length: 80
  assets:
    class_name: Assets
    style: nested # nested | camel | snake
```

每个字段的说明见 [配置](https://arturoyi.github.io/fast_dev/guide/configuration.html)。

```sh
dart run fast_dev help
dart run fast_dev help gen
dart run fast_dev config
dart run fast_dev gen
```

```dart
Image.asset(Assets.images.logo);
Image.asset(Assets.images.logo.of(context)); // 开了 theme / locale 之后
```

例子在 [`example/`](example/)。

---

## 贡献

Issue 和 PR 都可以。报问题用 [这个说明](https://arturoyi.github.io/fast_dev/community/bugs.html)。

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [MIT](LICENSE)

喜欢的话，点个 Star 就好。
