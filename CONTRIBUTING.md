# Contributing

Issue、PR、文档都可以。

- 问题：[提 Bug](https://arturoyi.github.io/fast_dev/community/bugs.html)，用 [Issue 模板](https://github.com/ArturoYi/fast_dev/issues/new/choose)
- 文档：`docs/`，`npm ci` 之后 `npm run docs:dev`。见 [docs/README.md](docs/README.md)

```sh
dart pub get
dart test
dart analyze
```

## 发布到 pub.dev

只发一个包：仓库根目录的 `fast_dev`（CLI 和 `build_runner` Builder 都在里面）。

预发布用 Dart semver，例如 `0.0.1-beta.1`（不能写成 `bate`）。`^0.0.1` 不会选到预发布，文档和依赖里要写 `^0.0.1-beta.1`。`0.0.x` 下 `^0.0.1-beta.1` 是 `>=0.0.1-beta.1 <0.0.2`，稳定版 `0.0.1` 也在范围内。

**第一次**必须在本地发，pub.dev 上还没有这个包时没法打开 GitHub Actions 发布：

```sh
fvm dart pub publish
```

第一版已经发过就不要再打同一个 tag，否则 Actions 会重复发布失败。发完后，用发布时的 Google 账号打开 https://pub.dev/packages/fast_dev/admin 。

在 **Automated publishing** 里启用 GitHub Actions：

- Repository：`ArturoYi/fast_dev`
- Tag pattern：`v{{version}}`

之后改版本、写 CHANGELOG，合并到 `main`，打 tag 就会走 `.github/workflows/publish.yml`：

```sh
git tag v0.0.1-beta.2
git push origin v0.0.1-beta.2
```

tag 上的版本必须和 `pubspec.yaml` 的 `version` 一致（`v` + 版本号）。不要把 `PUB_CREDENTIALS` 放进仓库或 Actions secrets。
