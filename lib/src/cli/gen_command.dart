import 'dart:io';

import 'package:args/command_runner.dart';

import '../config/load.dart';
import '../generate/run.dart';

/// 根据 pubspec 和配置生成类型安全代码。当前跑内置 assets 生成器。
final class GenCommand extends Command<void> {
  @override
  String get name => 'gen';

  @override
  String get description => '生成 assets.gen.dart';

  @override
  String get invocation => 'fast_dev gen';

  @override
  Never usageException(String message) => throw UsageException(message, usage);

  @override
  String get usage => '''
$description

用法：
  dart run fast_dev gen
  dart run fast_dev -c <path> gen

读 pubspec.yaml 的 flutter.assets 和 fast_dev_config.yaml，
写出 generate.output 下的 assets.gen.dart（默认 lib/gen/fast_dev/）。

会打印已生成 / 已跳过 / 警告。
flutter.assets 为空或 assets.enabled: false 时跳过。

选项：
  -h, --help             打印帮助
  -c, --config=<path>    配置文件（全局选项，文件必须存在）
''';

  @override
  Future<void> run() async {
    final configPath = globalResults?['config'] as String?;
    final loaded = loadFastDevConfig(configPath: configPath);
    final result = runGenerate(loaded);
    stdout.writeln(result.format());
  }
}
