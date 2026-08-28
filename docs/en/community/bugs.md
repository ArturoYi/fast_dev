---
title: Bugs
outline: [2, 3]
---

# Bugs

Use GitHub Issues. Search [existing ones](https://github.com/ArturoYi/fast_dev/issues) first.

The **[form](https://github.com/ArturoYi/fast_dev/issues/new?template=bug_report.yml)** is enough.

## Bring

1. **One line**  
   e.g. "With locale on, `zh_CN` folders are not stripped."

2. **Actual / expected**  
   Separate.

3. **A small repro**
   - Trimmed `pubspec.yaml` (at least `flutter.assets`)
   - `fast_dev_config.yaml`
   - Asset tree (`find assets -type f`)
   - The command (`dart run fast_dev gen` or `build_runner`)

4. **Environment**
   - Fast Dev version, or a commit
   - Dart / Flutter version
   - OS
   - CLI or `build_runner`

5. **Full output**  
   Written / skipped / warnings. Keep the warnings.

## Thin reports

- "It's wrong" with no config or tree
- A zip of a whole product app
- Secrets, certs, internal package lists
- New ideas use the [feature form](https://github.com/ArturoYi/fast_dev/issues/new?template=feature_request.yml)

## Security

Supply-chain or hostile codegen still goes in an Issue. Skip the full exploit in public comments.
