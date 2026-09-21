---
title: Fonts
outline: [2, 4]
---

# Fonts

Reads `flutter.fonts` from `pubspec.yaml` and writes `fonts.gen.dart`.

You get typed constants such as `FontFamily.raleway`. Do not write `fontFamily: "Raleway"`. Typos fail at compile time. The IDE can complete and rename them.

## Quick start

List fonts only in `pubspec.yaml` — the same list Flutter uses:

```yaml
flutter:
  fonts:
    - family: Raleway
      fonts:
        - asset: fonts/Raleway-Regular.ttf
        - asset: fonts/Raleway-Italic.ttf
          style: italic
    - family: RobotoMono
      fonts:
        - asset: fonts/RobotoMono-Regular.ttf
        - asset: fonts/RobotoMono-Bold.ttf
          weight: 700
```

You can skip the config file and keep the defaults. To set the class name, put `fast_dev_config.yaml` at the package root:

```yaml
version: 1

generate:
  output: lib/gen/fast_dev/
  fonts:
    class_name: FontFamily
```

Then generate:

```sh
dart run fast_dev gen
# or: dart run build_runner build
# watch: dart run build_runner watch
```

Default output is `lib/gen/fast_dev/fonts.gen.dart`. Commit it.

```dart
import 'package:your_app/gen/fast_dev/fonts.gen.dart';

Text(
  'Hello',
  style: TextStyle(fontFamily: FontFamily.raleway),
);

Text(
  'Hello 你好',
  style: TextStyle(
    fontFamily: FontFamily.raleway,
    fontFamilyFallback: FontFamily.fallbacks,
  ),
);
```

`fallbacks` is written only if you list it in config. See [`fonts.fallbacks`](#fontsfallbacks). You can still write `const [FontFamily.notoSansSC]` by hand.

The root class is `abstract final class` with `static const String` members. Field details: [Config](#config). How to create and load the file: [Configuration](/en/guide/configuration).

Private packages or a multi-module setup that exports fonts: [Package mode](#package-mode).

## Where the list comes from

Only `flutter.fonts`. Each entry must be a map with `family`. The same `family` twice keeps the first and warns. Duplicate `asset` paths in one family are dropped.

A missing `family`, a non-list `fonts`, or an item without `asset` warns and skips that item. A non-map entry fails.

`generate.fonts.enabled: false` writes nothing.

Generation uses family names only. It does not read font file bytes. A new family has to be added in `pubspec.yaml` (Flutter already requires that).

## Config

How to create and load the file: [Configuration](/en/guide/configuration). Only write the keys you want to change. Missing fields keep defaults.

Output dir and line length are shared with assets: `generate.output` / `generate.line_length`.

### `fonts.enabled`

`generate.fonts.enabled`.

| | |
| --- | --- |
| Type | boolean |
| Default | `true` |
| Required | no |

`false` skips font generation. Use real YAML booleans (`true` / `false`).

### `fonts.class_name`

`generate.fonts.class_name`.

| | |
| --- | --- |
| Type | string |
| Default | `FontFamily` |
| Required | no |

Root class name. Must be a Dart identifier: letter or `_` first, then letters, digits, `_`. `123Fonts` and `My-Fonts` fail.

Prefer PascalCase: `FontFamily`, `AppFonts`.

### `fonts.package`

`generate.fonts.package`.

| | |
| --- | --- |
| Type | boolean |
| Default | `false` |
| Required | no |

`true` turns on [package mode](#package-mode). The package name comes from `name` in `pubspec.yaml`. No `name` → a warning, and app mode is used.

### `fonts.fallbacks`

`generate.fonts.fallbacks`.

| | |
| --- | --- |
| Type | string, or list of strings |
| Default | `[]` |
| Required | no |

Family names to put in `FontFamily.fallbacks`. Each must be a `family` already declared in `flutter.fonts`. Order is the fallback order. An empty list (the default) does not emit the member. Lists replace. `fallbacks: NotoSansSC` also works.

```yaml
generate:
  fonts:
    fallbacks:
      - NotoSansSC
      - NotoNaskh
```

```dart
static const List<String> fallbacks = [notoSansSC, notoNaskh];
```

```dart
TextStyle(
  fontFamily: FontFamily.raleway,
  fontFamilyFallback: FontFamily.fallbacks,
);
```

A name that is not in `flutter.fonts` fails. Duplicates keep the first. An empty string fails.

This is only a `List<String>` for `fontFamilyFallback`. It does not pick a primary family by locale.

## Package mode

Turn this on when a private package or another module declares fonts for other packages. Leave it `false` when the app uses its own fonts.

```yaml
generate:
  fonts:
    package: true
```

If the package name is `design_system`:

```dart
abstract final class FontFamily {
  static const String package = 'design_system';

  /// Font family: Raleway
  static const String raleway = 'packages/$package/Raleway';
}
```

Consumers pass the member to `fontFamily`. **Do not** also pass `package:`, or the prefix is applied twice:

```dart
import 'package:design_system/gen/fast_dev/fonts.gen.dart';

TextStyle(fontFamily: FontFamily.raleway);
```

The package that declares the fonts uses the same constants.

## Naming

Family names become camelCase members: `Raleway` → `raleway`, `RobotoMono` → `robotoMono`, `Arial Black` → `arialBlack`.

Spaces and symbols split words. A name that cannot start with a letter gets a prefix. Dart keywords get `_`. Collisions get a suffix so the file compiles.

Package mode reserves the member name `package`. A non-empty `fallbacks` list reserves `fallbacks`. A family that collides with either gets a suffix.

## Tips

- List fonts only under `flutter.fonts` in `pubspec.yaml`. The tool does not keep a second list.
- Keep the default for an app. Turn on `package: true` only when fonts live in a package others import.
- After package mode is on, consumers should not write `package: FontFamily.package`.
- Commit the generated file. If you already use `build_runner`, one `watch` is enough. Changes to `pubspec.yaml` or the config rebuild.
