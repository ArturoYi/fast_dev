---
title: Configuration
outline: [2, 3]
---

# Configuration

Create `fast_dev_config.yaml` next to `pubspec.yaml`.

The tool can run without it and will use the defaults below. A file in the repo is better: class name, style, output, and variants are visible.

What Flutter packs into the app still comes from `flutter.assets` in `pubspec.yaml`. `fast_dev_config.yaml` does not change that. It only controls code generation (output dir, class name, style, variants).

Which keys each feature reads, and the rules for them: [Assets](/en/features/assets#config). Theme and locale: [Theme and locale](/en/features/assets#theme-and-locale).

## How it loads

1. `dart run fast_dev -c path/to.yaml gen` — that file only. It has to exist. No fallback to defaults.
2. No `-c` — walk up to `pubspec.yaml`, then read `fast_dev_config.yaml` beside it.
3. Package root found, no config file — defaults, plus a warning.

A relative `-c` is resolved from the current working directory. Run the CLI from the package root. Keep `-c` for one-off experiments.

## Merge

Defaults first. Keys you write override. Partial files are fine.

Lists replace, they do not append. Default `theme.folders.light` is `[light]`. If you write `light: [day]`, the result is `[day]`, not `[light, day]`.

Unknown keys warn and are ignored. The run still succeeds. Reserved keys do the same: `imports`, `generate.fonts`, `generate.colors` warn and are not treated as implemented.

Write `version: 1`. Only `1` is accepted. Omit it and it is `1`. Any other integer fails.

## Check the merge

After editing YAML (writes nothing):

```sh
dart run fast_dev config
```

Prints the package root, the file that was read, warnings, and the merged values. Then `dart run fast_dev gen`.

`build_runner` can override the output dir with `options.output` in the app `build.yaml`. See [build_runner](./build-runner.md).

## Default config

Every key that is parsed today, with the built-in defaults. Drop what you do not need.

Field details live on the feature pages. Today that is [Assets](/en/features/assets#config). Theme and locale keys: [Theme and locale](/en/features/assets#theme-and-locale).

```yaml
# Schema. Only 1 is accepted. Omit it and it is 1. Any other integer fails.
version: 1

# Code generation. assets is the only section under it today.
# Reserved keys fonts / colors warn and are ignored.
generate:
  # Where .gen.dart is written, relative to the package root.
  # Does not change what Flutter packs. Empty string fails.
  # Backslashes become /. A missing trailing slash is added.
  output: lib/gen/fast_dev/

  # Passed to dart_style. Must be > 0.
  # Match dart format / analysis_options.yaml.
  line_length: 80

  # Asset path generation. Turn it off and assets.gen.dart is not written.
  # Field details: Assets.
  assets:
    # false skips generation. Use real YAML booleans (true / false).
    enabled: true

    # Root class name. Must be a Dart identifier. Prefer PascalCase.
    class_name: Assets

    # How paths become members: nested | camel | snake
    style: nested

    # Theme and locale folders. Off by default: light/, dark/, zh/ stay
    # normal nested folders. Turn them on only when files are actually
    # split that way. Details: Assets.
    variants:
      theme:
        # When true, folders in folders.light / folders.dark are variants.
        enabled: false
        folders:
          # Light / dark folder names. A string or a list.
          # Lists replace, they do not append.
          light: [light]
          dark: [dark]
      locale:
        # When true, folders cannot be empty.
        enabled: false
        # Locale folders to strip. folders: zh also works.
        folders: []
        # Miss on the current locale:
        # file = the file with no locale folder; or a code in folders.
        fallback: file
```

## How to write it

1. Create the file. Only write the keys you want to change.
2. Leave `variants` off if you do not split by theme or locale.
3. Turn `theme` on if you have `dark/` or `light/`. Rename `folders` if your names differ.
4. Turn `locale` on if you have `zh/` / `en/`, and list them in `folders`.
5. Run `dart run fast_dev config`.
6. Run `dart run fast_dev gen`.
