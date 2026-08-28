---
title: Configuration
outline: [2, 4]
---

# Configuration

Create `fast_dev_config.yaml` next to `pubspec.yaml`.

The tool can run without it and will use the defaults below. A file in the repo is better: class name, style, output, and variants are visible.

Nothing is written back into `pubspec.yaml`. What gets packed is still `flutter.assets`. This file only says how the tool runs.

## How it loads

1. `dart run fast_dev -c path/to.yaml gen` — that file only. It has to exist. No fallback to defaults.
2. No `-c` — walk up to `pubspec.yaml`, then read `fast_dev_config.yaml` beside it.
3. Package root found, no config file — defaults, plus a warning.

A relative `-c` is resolved from the current working directory. Run the CLI from the package root.

Print the merge (writes nothing):

```sh
dart run fast_dev config
```

## Merge

Defaults first. Keys you write override. Partial files are fine.

Lists replace, they do not append. Default `theme.folders.light` is `[light]`. If you write `light: [day]`, the result is `[day]`, not `[light, day]`.

Unknown keys warn and are ignored. The run still succeeds.

## Full example

Every key that is parsed today:

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

Drop what you do not need. Missing fields keep defaults.

## `version`

| | |
| --- | --- |
| Type | int |
| Default | `1` |
| Required | No |

Only `1` is accepted. Omit it and it is `1`. Any other integer fails.

Write `version: 1` so the schema is obvious.

## `generate`

Code generation. `assets` is the only section under it.

### `generate.output`

| | |
| --- | --- |
| Type | string |
| Default | `lib/gen/fast_dev/` |
| Required | No |

Where `.gen.dart` is written, relative to the package root. Does not change what Flutter packs.

Empty string fails. Backslashes become `/`. A missing trailing slash is added.

`build_runner` can override this with `options.output`. See [build_runner](./build-runner.md).

Keep the default, or point at a `lib/gen/` you already use. Commit the generated file.

### `generate.line_length`

| | |
| --- | --- |
| Type | positive int |
| Default | `80` |
| Required | No |

Passed to `dart_style`. Must be `> 0`.

Match `dart format` / `analysis_options.yaml` so generated and handwritten code share one width.

### `generate.assets`

Asset path generation. Turn it off and `assets.gen.dart` is not written.

#### `generate.assets.enabled`

| | |
| --- | --- |
| Type | bool |
| Default | `true` |
| Required | No |

`false` skips assets. Use real YAML booleans (`true` / `false`).

#### `generate.assets.class_name`

| | |
| --- | --- |
| Type | string |
| Default | `Assets` |
| Required | No |

Root class name. Must be a Dart identifier: letter or `_`, then letters, digits, `_`.

Use PascalCase (`Assets`, `AppAssets`). If the name is `AdaptiveAsset` or `AssetPath`, helpers get an `Fd` prefix.

#### `generate.assets.style`

| | |
| --- | --- |
| Type | `nested` / `camel` / `snake` |
| Default | `nested` |
| Required | No |

How paths become members. Anything else fails.

For `assets/images/logo.svg` and `assets/data/hello.json`:

| `style` | Use |
| --- | --- |
| `nested` | `Assets.images.logo`, `Assets.data.hello` |
| `camel` | `Assets.imagesLogo`, `Assets.dataHello` |
| `snake` | `Assets.images_logo`, `Assets.data_hello` |

The top `assets/` segment is flattened in `nested`. You do not get `Assets.assets.images`.

Use `nested` to walk folders. Use `camel` or `snake` to hang everything on the root class.

Names are sanitized. Keywords are avoided. Collisions get a suffix.

#### `generate.assets.variants`

Theme and locale folders. Off by default: `light/`, `dark/`, `zh/` stay normal nested folders.

Turn them on only when files are actually split that way.

You can enable one or both. If both are on, theme folder names and locale folder names cannot overlap (case-insensitive; locales also treat `-` as `_`).

##### `variants.theme.enabled`

| | |
| --- | --- |
| Type | bool |
| Default | `false` |
| Required | No |

When `true`, folders in `folders.light` / `folders.dark` are variants, not members.

```
assets/images/logo.svg
assets/images/dark/logo.svg
```

becomes one `Assets.images.logo`. With variants off you get `Assets.images.logo` and `Assets.images.dark.logo`.

##### `variants.theme.folders.light` / `dark`

| | |
| --- | --- |
| Type | string or list of strings |
| Default | `light: [light]`, `dark: [dark]` |
| Required | No |

```yaml
folders:
  light: day
  dark: [night, dark]
```

Rules: single-segment names only; no density names (`2.0x`); light and dark cannot share a name. Lists replace the default list.

Theme folders can sit at any depth. At most one theme segment is stripped per path.

##### `variants.locale.enabled`

| | |
| --- | --- |
| Type | bool |
| Default | `false` |
| Required | No |

When `true`, `folders` cannot be empty.

##### `variants.locale.folders`

| | |
| --- | --- |
| Type | string or list of strings |
| Default | `[]` |
| Required | Yes if `enabled: true` |

```yaml
folders:
  - zh
  - en
  - zh_CN
```

`folders: zh` also works. Case-insensitive. `-` and `_` match, so `zh-CN` and `zh_CN` collapse to the first one.

Same name rules as theme folders. Cannot overlap enabled theme folders.

##### `variants.locale.fallback`

| | |
| --- | --- |
| Type | string |
| Default | `file` |
| Required | No |

| Value | Meaning |
| --- | --- |
| `file` | Use the file with no locale folder. `File` becomes `file` |
| A locale code | Must be in `folders` |

Empty string fails. Codes are aligned to the spelling in `folders`.

## How to write it

1. Create the file. Set `output`, `class_name`, `style`, `line_length`.
2. Leave `variants` off if you do not split by theme or locale.
3. Turn `theme` on if you have `dark/` or `light/`. Rename `folders` if your names differ.
4. Turn `locale` on if you have `zh/` / `en/`, and list them in `folders`.
5. Run `dart run fast_dev config`.
6. Run `dart run fast_dev gen`.
