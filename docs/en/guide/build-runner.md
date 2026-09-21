---
title: build_runner
outline: [2, 3]
---

# build_runner

`fast_dev` includes the builder. Same output as `dart run fast_dev gen`. Directory still comes from `generate.output`.

CLI-only projects can skip `build_runner`. If the project already uses `build_runner`, adding `fast_dev` is enough.

## Install

```yaml
dev_dependencies:
  fast_dev: ^0.0.1-beta.1
  build_runner: ^2.7.2
```

If the project already uses `build_runner`, add `fast_dev` next to the existing `dev_dependencies`. Do not add a second `build_runner`.

## Commands

One command runs **every** enabled builder in the package. Asset codegen and other codegen come out together. You do not watch them separately.

```sh
# once
dart run build_runner build

# keep running — dart, assets, or config changes rebuild
dart run build_runner watch
```

Assets only, no `build_runner`:

```sh
dart run fast_dev gen
```

Rebuild one kind of output (unusual; daily watch does not need this):

```sh
# only rebuild outputs under lib/
dart run build_runner build --build-filter="lib/**"

# the same filter on watch skips assets/ and the config file
dart run build_runner watch --build-filter="lib/**"
```

Do not start two `watch` processes. One terminal, one command.

To keep other builders and skip Fast Dev:

```yaml
targets:
  $default:
    builders:
      fast_dev:fast_dev:
        enabled: false
```

## With other builders

Same as any other `build_runner` package: list it in `dev_dependencies`, share this command.

```sh
dart run build_runner watch
```

Edits under `lib/` rebuild those generators. New images, a change to `flutter.fonts`, or a change to `fast_dev_config.yaml` rebuild `assets.gen.dart` / `fonts.gen.dart`. No extra process for Fast Dev.

## Watch and assets

The default source set already includes `lib/**`, so other builders' `.dart` files are watched. `assets/` and `fast_dev_config.yaml` are not. Font families live in `pubspec.yaml`; changing it rebuilds `fonts.gen.dart`. To rebuild when those change, add them in the app `build.yaml` and **keep** `lib/**`:

```yaml
targets:
  $default:
    sources:
      include:
        - $package$
        - lib/**
        - test/**
        - pubspec.yaml
        - fast_dev_config.yaml
        - assets/**
```

Do not drop `lib/**`, or other builders stop watching.

## Override output

Prefer `generate.output` in the config file. To change it only for `build_runner`:

```yaml
targets:
  $default:
    builders:
      fast_dev:fast_dev:
        options:
          output: lib/generated/
```

## How files land

The builder writes a cache manifest (`.fast_dev.manifest.json`). Post-process writes the sources. Stale files are removed via `.dart_tool/fast_dev/owned_outputs.json`. Paths outside the package are rejected.
