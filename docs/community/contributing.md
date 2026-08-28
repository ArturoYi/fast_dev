---
title: 贡献
outline: [2, 3]
---

# 贡献

Issue、PR、文档都可以。觉得有用的话，[点个 Star](https://github.com/ArturoYi/fast_dev) 也行。

## 可以从这开始

1. 按 [提 Bug](./bugs.md) 报问题
2. 先开 Issue 再改行为
3. 改文档（`docs/` 是 VitePress）
4. 补测试，或修已经确认的问题

## 本地

| 路径 | |
| --- | --- |
| `/` | CLI 和生成核心（`fast_dev`） |
| `fast_dev_runner/` | `build_runner` |
| `example/` | 小例子 |
| `docs/` | 文档 |

```sh
dart pub get
dart test
dart analyze

cd fast_dev_runner && dart pub get && dart test && cd ..

cd docs && npm ci && npm run docs:dev
```

别跳过 hooks。也别在一个功能 PR 里顺手格式化全仓库。

## 约定

- CLI 和告警保持中文
- 生成文件走 `dart_style`，行宽读 `generate.line_length`
- 用户能感觉到的变化，改 `CHANGELOG.md` 和对应文档

## PR

- 一件事一个 PR
- 行为有变就带测试
- 写一下为什么，挂上 Issue

根目录还有一份 [CONTRIBUTING.md](https://github.com/ArturoYi/fast_dev/blob/main/CONTRIBUTING.md)。
