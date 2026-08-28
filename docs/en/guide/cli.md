---
title: CLI
outline: [2, 3]
---

# CLI

Entry is `bin/fast_dev.dart`. Run it from the package root.

```sh
dart run fast_dev
dart run fast_dev help
dart run fast_dev help gen
dart run fast_dev config --help
dart run fast_dev config
dart run fast_dev gen
dart run fast_dev -c path/to/custom.yaml gen
```

No subcommand, `-h` / `--help`, or `help` prints usage and exits `0`.

## `help`

| Form | Shows |
| --- | --- |
| `dart run fast_dev` | Overview |
| `dart run fast_dev help` | Same |
| `dart run fast_dev -h` / `--help` | Same |
| `dart run fast_dev help gen` | One command |
| `dart run fast_dev gen --help` | Same |

Unknown command → exit `64`.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Ok (including usage only) |
| `1` | Config or generation failed |
| `64` | Bad usage |

## Global options

| Option | Notes |
| --- | --- |
| `-c`, `--config <path>` | Explicit file. It has to exist. No fallback to defaults. |

Without `-c`, walk up to `pubspec.yaml`, then read `fast_dev_config.yaml` beside it. No file → defaults + a warning.

Create `fast_dev_config.yaml` and keep `-c` for one-off experiments.

## `config`

Print the resolved config. Writes nothing.

```sh
dart run fast_dev config
```

Run this after editing YAML, then `gen`.

## `gen`

Write `assets.gen.dart`.

```sh
dart run fast_dev gen
```

Prints written / skipped / warnings. Output dir is `generate.output`, default `lib/gen/fast_dev/`.

Empty `flutter.assets`, or `assets.enabled: false`, skips and says why.
