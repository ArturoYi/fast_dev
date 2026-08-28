/// fast_dev 的 `build_runner` 入口。
///
/// 消费方把本包和 `build_runner` 加到 `dev_dependencies` 后，
/// `dart run build_runner build` 会生成与 `fast_dev gen` 相同的
/// `assets.gen.dart`。输出目录仍以 `fast_dev_config.yaml` 的
/// `generate.output` 为准；也可在应用的 `build.yaml` 里用 `options.output` 覆盖。
///
/// 默认的 build_runner 源文件集合不含 `assets/` 和配置文件。若希望
/// `build_runner watch` 在新增图片或改配置时自动重跑，在应用的
/// `build.yaml` 里把它们加进 `sources.include`：
///
/// ```yaml
/// targets:
///   $default:
///     sources:
///       include:
///         - $package$
///         - lib/**
///         - test/**
///         - pubspec.yaml
///         - fast_dev_config.yaml
///         - assets/**
/// ```
library;

import 'package:build/build.dart';

import 'src/builder/assets_builder.dart';
import 'src/builder/post_process.dart';

/// `build.yaml` 里 `builder_factories` 的入口。
Builder fastDevBuilder(BuilderOptions options) => FastDevBuilder(options);

/// `build.yaml` 里 post-process `builder_factory` 的入口。
PostProcessBuilder fastDevPostProcess(BuilderOptions options) =>
    FastDevPostProcessBuilder();
