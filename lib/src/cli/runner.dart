import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../config/exception.dart';
import '../generate/exception.dart';
import 'config_command.dart';
import 'gen_command.dart';

/// CLI 入口。`bin/fast_dev.dart` 只做转发，方便测试时直接调本函数
/// 而不 `Process.run`。
///
/// 返回进程退出码：0 成功，1 配置或生成错误，64 用法错误（和 BSD sysexits 一致）。
Future<int> runFastDev(List<String> arguments) async {
  final runner = FastDevCommandRunner();
  try {
    await runner.run(arguments);
    return 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    return 64;
  } on ConfigException catch (e) {
    stderr.writeln(e.message);
    return 1;
  } on GenerateException catch (e) {
    stderr.writeln(e.message);
    return 1;
  }
}

/// 子命令注册处。后续命令加在 [addCommand] 旁边，不要在 bin/ 里再开一套 ArgParser。
final class FastDevCommandRunner extends CommandRunner<void> {
  /// 注册全局选项和已实现的子命令。
  FastDevCommandRunner()
    : super('fast_dev', '根据 flutter.assets / flutter.fonts 生成类型安全的引用。') {
    argParser.addOption(
      'config',
      abbr: 'c',
      help: '配置文件路径（默认：项目根目录的 fast_dev_config.yaml）',
      valueHelp: 'path',
    );
    addCommand(ConfigCommand());
    addCommand(GenCommand());
  }

  /// 没有子命令时打印用法并以 0 退出，避免裸跑变成错误码 64。
  /// 未知命令仍走 [usageException]，退出码 64。
  @override
  Future<void> runCommand(ArgResults topLevelResults) {
    if (topLevelResults.command == null) {
      if (topLevelResults.rest.isEmpty) {
        printUsage();
        return Future.value();
      }
      usageException('没有名为 "${topLevelResults.rest[0]}" 的命令。');
    }
    return super.runCommand(topLevelResults);
  }

  @override
  Never usageException(String message) {
    throw UsageException(_localizeUsage(message), usage);
  }

  @override
  String get usage {
    final lines = <String>[
      description,
      '',
      '用法：',
      '  dart run fast_dev <command> [arguments]',
      '',
      '全局选项：',
      '  -h, --help             打印帮助',
      '  -c, --config=<path>    配置文件路径（默认：fast_dev_config.yaml）',
      '',
      '命令：',
      '  help      打印帮助；help <command> 看某个命令',
    ];
    for (final entry in commands.entries) {
      if (entry.value.hidden) {
        continue;
      }
      lines.add('  ${entry.key.padRight(10)}${entry.value.description}');
    }
    lines.addAll(const [
      '',
      '例子：',
      '  dart run fast_dev help',
      '  dart run fast_dev help gen',
      '  dart run fast_dev config',
      '  dart run fast_dev gen',
      '  dart run fast_dev -c custom.yaml gen',
      '',
      '在项目根目录执行。没有 fast_dev_config.yaml 时用内置默认值。',
      '某个命令的说明：dart run fast_dev help <command> 或 dart run fast_dev <command> --help',
    ]);
    return lines.join('\n');
  }
}

String _localizeUsage(String message) {
  final unknown = RegExp(r'^Could not find a command named "(.+)"\.$');
  final match = unknown.firstMatch(message);
  if (match != null) {
    return '没有名为 "${match.group(1)}" 的命令。';
  }
  return message;
}
