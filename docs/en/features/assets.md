---
title: Assets
outline: [2, 4]
---

# Assets

Reads `flutter.assets`, expands directories, writes `assets.gen.dart`.

## Where the list comes from

Only `flutter.assets`. Directories are expanded recursively. `assets/` in `pubspec.yaml` covers `assets/images/logo.svg` and `assets/data/hello.json`.

File entries stay files. Missing paths warn and are skipped.

Flutter density folders (`2.0x`, `3.0x`) collapse to the base path. Dotfiles are skipped.

flavors on `flutter.assets` are treated as normal paths, with a warning. transformers are ignored, also with a warning. Neither changes generation rules.

`generate.assets.enabled: false` writes nothing.

## Output

`{generate.output}/assets.gen.dart`, default `lib/gen/fast_dev/assets.gen.dart`.

Commit the file. After assets or config change:

```sh
dart run fast_dev gen
```

## Plain paths

Without variants, each file is an `AssetPath` — an `extension type` over `String`:

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

`camel` / `snake` hang on the root class:

```dart
Assets.imagesLogo
Assets.images_logo
```

## Theme and locale

```
assets/images/logo.svg
assets/images/dark/logo.svg
assets/images/zh/logo.svg
assets/images/zh/dark/logo.svg
assets/images/en/logo.svg
```

With the matching variants on, these become one `Assets.images.logo` of type `AdaptiveAsset`.

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

`of(context)` reads `Theme` brightness and `Localizations`. Override a subtree with `AssetResolveScope`.

`resolve` does not need a `BuildContext`. Omitting `locale` only applies theme on the root node. It does not apply `locale.fallback`.

`zh-CN` and `zh_CN` are the same locale. Country beats language when matching a `Locale`.

If no variant files exist, you still get a plain `AssetPath`, even when `variants` is on.

## Naming

Names are sanitized. Keywords are avoided. If the root class hits `AssetPath` / `AdaptiveAsset` / `AssetResolveScope`, helpers get an `Fd` prefix.

## Tips

- List directories in `pubspec.yaml`, not every file, unless you want a subset.
- Leave `variants` off if you do not split by theme or locale.
- Use `.of(context)` after variants are on. Plain files stay `String`.
- Commit generated files. CI can run `fast_dev gen` again to check.
