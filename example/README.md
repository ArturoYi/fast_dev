# fast_dev_example

试 Fast Dev 的小应用。CLI 和 `build_runner` 都能生成 `lib/gen/fast_dev/assets.gen.dart`。`pubspec.yaml` 写了 `flutter.fonts` 时还会出 `fonts.gen.dart`。

```sh
cd example
dart run fast_dev gen
# 或：dart run build_runner build
flutter run
```

配置在 `fast_dev_config.yaml`。watch 要看见资源和配置，见仓库里的 `build.yaml`。
