import 'dart:io';

import 'package:args/command_runner.dart';

import '../config/load.dart';

/// 加载当前项目配置并打印解析结果。
///
/// 用来确认「找到了哪份文件、默认值怎么合并、未知键有没有告警」，
/// 不改任何源码。`gen` 和后续子命令复用同一套 `loadFastDevConfig`。
final class ConfigCommand extends Command<void> {
  @override
  String get name => 'config';

  @override
  String get description => '解析并打印当前项目的配置（不写文件）';

  @override
  String get invocation => 'fast_dev config';

  @override
  Never usageException(String message) => throw UsageException(message, usage);

  @override
  String get usage => '''
$description

用法：
  dart run fast_dev config
  dart run fast_dev -c <path> config

会打印包根、实际读到的文件、告警、合并后的完整值。
改完 fast_dev_config.yaml 可以先跑这条，再 gen。

选项：
  -h, --help             打印帮助
  -c, --config=<path>    配置文件（全局选项，文件必须存在）
''';

  @override
  Future<void> run() async {
    final configPath = globalResults?['config'] as String?;
    final result = loadFastDevConfig(configPath: configPath);
    stdout.writeln(result.format());
  }
}
