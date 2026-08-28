---
title: Assets
outline: [2, 4]
---

# Assets

Reads `flutter.assets`, expands directories, writes `assets.gen.dart`.

No theme or locale folders? [Quick start](#quick-start) is enough. If you have `light/` / `dark/` or `zh/` / `en/`, see [Theme and locale](#theme-and-locale).

## Quick start

List a directory in `pubspec.yaml`. One line is usually enough:

```yaml
flutter:
  assets:
    - assets/
```

You can skip the config file and keep the defaults. To set the class name and style, put `fast_dev_config.yaml` at the package root and **leave `variants` off**:

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  assets:
    class_name: Assets
    style: nested
```

Then generate:

```sh
dart run fast_dev gen
# or: dart run build_runner build
```

Default output is `lib/gen/fast_dev/assets.gen.dart`. Commit it.

Each file is an `AssetPath` — an `extension type` over `String`. Pass it to `Image.asset` or `rootBundle`:

```dart
import 'package:your_app/gen/fast_dev/assets.gen.dart';

Image.asset(Assets.images.logo);
await rootBundle.loadString(Assets.data.hello);
debugPrint(Assets.images.logo); // assets/images/logo.svg
```

`nested` (default) walks folders and flattens the top `assets/` segment:

```dart
Assets.images.logo
Assets.data.hello
```

To hang everything on the root class, set `style` to `camel` or `snake`:

```dart
Assets.imagesLogo
Assets.images_logo
```

The root class is `abstract final class` with `static const` members. Nested folders become small classes.

Field details: [Config](#config). How to create and load the file: [Configuration](/en/guide/configuration).

## Where the list comes from

Only `flutter.assets`. Directories are expanded recursively. `assets/` in `pubspec.yaml` covers `assets/images/logo.svg` and `assets/data/hello.json`.

File entries stay files. Missing paths warn and are skipped.

Flutter density folders (`2.0x`, `3.0x`) collapse to the base path. Dotfiles are skipped.

flavors on `flutter.assets` are treated as normal paths, with a warning. transformers are ignored, also with a warning. Neither changes generation rules.

`generate.assets.enabled: false` writes nothing.

## Config

How to create and load the file: [Configuration](/en/guide/configuration). Only write the keys you want to change. Missing fields keep defaults. Lists replace, they do not append.

Theme and locale keys are under [Theme and locale](#theme-and-locale).

### `output`

`generate.output`.

| | |
| --- | --- |
| Type | string |
| Default | `lib/gen/fast_dev/` |
| Required | No |

Where `.gen.dart` is written, relative to the package root. Does not change what Flutter packs.

Empty string fails. Backslashes become `/`. A missing trailing slash is added.

`build_runner` can override this with `options.output`. See [build_runner](/en/guide/build-runner).

Keep the default, or point at a `lib/gen/` you already use. Commit the generated file.

### `line_length`

`generate.line_length`.

| | |
| --- | --- |
| Type | positive int |
| Default | `80` |
| Required | No |

Passed to `dart_style`. Must be `> 0`.

Match `dart format` / `analysis_options.yaml` so generated and handwritten code share one width.

### `assets.enabled`

`generate.assets.enabled`.

| | |
| --- | --- |
| Type | bool |
| Default | `true` |
| Required | No |

`false` skips assets. Use real YAML booleans (`true` / `false`).

### `assets.class_name`

`generate.assets.class_name`.

| | |
| --- | --- |
| Type | string |
| Default | `Assets` |
| Required | No |

Root class name. Must be a Dart identifier: letter or `_`, then letters, digits, `_`.

Use PascalCase (`Assets`, `AppAssets`). If the name is `AdaptiveAsset` or `AssetPath`, helpers get an `Fd` prefix.

### `assets.style`

`generate.assets.style`.

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

## Theme and locale

::: warning Use with care
Leave this off unless files are actually split by theme or locale. When it is on, folder names in the config are stripped from paths — a business folder that happens to match will be treated as a variant too. The type changes from `AssetPath` (`String`) to `AdaptiveAsset`, and you must call `.of(context)`.
:::

Off by default. `light/`, `dark/`, `zh/` stay normal nested folders, so you get paths like `Assets.images.dark.logo`.

```
assets/images/logo.svg
assets/images/dark/logo.svg
assets/images/zh/logo.svg
assets/images/zh/dark/logo.svg
assets/images/en/logo.svg
```

Turn the matching variants on:

```yaml
generate:
  assets:
    variants:
      theme:
        enabled: true
      locale:
        enabled: true
        folders:
          - zh
          - en
        fallback: file
```

These become one `Assets.images.logo` of type `AdaptiveAsset`:

```dart
Image.asset(Assets.images.logo.of(context));

Assets.images.logo.resolve(
  brightness: Brightness.dark,
  locale: const Locale('zh'),
);
```

Order:

1. locale + theme
2. locale only
3. theme only
4. `fallback` (the unlocalized file by default)

`of(context)` reads `Theme` brightness and `Localizations`. Override a subtree with `AssetResolveScope`:

```dart
AssetResolveScope(
  brightness: Brightness.dark,
  locale: const Locale('zh'),
  child: Image.asset(Assets.images.logo.of(context)),
)
```

`resolve` does not need a `BuildContext`. Omitting `locale` only applies theme on the root node. It does not apply `locale.fallback`.

If there is no unlocalized file, root `fallback` follows the config (`file` or a locale). If there is only dark and no light, no-theme falls back to dark.

`zh-CN` and `zh_CN` are the same locale. Country beats language when matching a `Locale`.

If no variant files exist, you still get a plain `AssetPath`, even when `variants` is on.

You can enable one or both. If both are on, theme folder names and locale folder names cannot overlap (case-insensitive; locales also treat `-` as `_`).

### `theme.enabled`

`generate.assets.variants.theme.enabled`.

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

### `theme.folders`

`generate.assets.variants.theme.folders.light` / `dark`.

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

### `locale.enabled`

`generate.assets.variants.locale.enabled`.

| | |
| --- | --- |
| Type | bool |
| Default | `false` |
| Required | No |

When `true`, `folders` cannot be empty.

### `locale.folders`

`generate.assets.variants.locale.folders`.

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

### `locale.fallback`

`generate.assets.variants.locale.fallback`.

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

## Naming

Names are sanitized. Keywords are avoided. If the root class hits `AssetPath` / `AdaptiveAsset` / `AssetResolveScope`, helpers get an `Fd` prefix.

## Tips

- List directories in `pubspec.yaml`, not every file, unless you want a subset.
- Leave `variants` off if you do not split by theme or locale.
- Use `.of(context)` after variants are on. Plain files stay `String`.
- Commit generated files. CI can run `fast_dev gen` again to check.
