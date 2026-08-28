---
title: Contributing
outline: [2, 3]
---

# Contributing

Issues, PRs, and docs are welcome. A [Star](https://github.com/ArturoYi/fast_dev) is fine too.

## Start here

1. File bugs with the [bug notes](./bugs.md)
2. Open an Issue before changing behavior
3. Docs live in `docs/` (VitePress)
4. Tests, or fixes for confirmed issues

## Local

| Path | |
| --- | --- |
| `/` | CLI and core (`fast_dev`) |
| `fast_dev_runner/` | `build_runner` |
| `example/` | Small app |
| `docs/` | Docs |

```sh
dart pub get
dart test
dart analyze

cd fast_dev_runner && dart pub get && dart test && cd ..

cd docs && npm ci && npm run docs:dev
```

Don't skip hooks. Don't reformat the whole tree in a feature PR.

## Conventions

- CLI and warnings stay in Chinese
- Generated files go through `dart_style`
- User-visible changes update `CHANGELOG.md` and the matching docs page

## PRs

- One thing per PR
- Behavior changes need tests
- Say why, link the Issue

There is also a root [CONTRIBUTING.md](https://github.com/ArturoYi/fast_dev/blob/main/CONTRIBUTING.md).
