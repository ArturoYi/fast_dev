import 'package:args/command_runner.dart';
import 'package:fast_dev/src/cli/runner.dart';
import 'package:test/test.dart';

void main() {
  test('无子命令时打印用法并以 0 退出', () async {
    expect(await runFastDev([]), 0);
  });

  test('--help / help 以 0 退出', () async {
    expect(await runFastDev(['--help']), 0);
    expect(await runFastDev(['-h']), 0);
    expect(await runFastDev(['help']), 0);
  });

  test('help config / help gen / 子命令 --help 以 0 退出', () async {
    expect(await runFastDev(['help', 'config']), 0);
    expect(await runFastDev(['help', 'gen']), 0);
    expect(await runFastDev(['config', '--help']), 0);
    expect(await runFastDev(['gen', '--help']), 0);
  });

  test('未知命令是用法错误', () async {
    expect(await runFastDev(['missing']), 64);
    expect(await runFastDev(['help', 'missing']), 64);
  });

  test('未知命令的报错是中文', () {
    expect(
      () => FastDevCommandRunner().usageException('Could not find a command named "missing".'),
      throwsA(
        isA<UsageException>().having(
          (e) => e.message,
          'message',
          '没有名为 "missing" 的命令。',
        ),
      ),
    );
  });

  test('usage 列出命令和例子', () {
    final usage = FastDevCommandRunner().usage;
    expect(usage, contains('help'));
    expect(usage, contains('config'));
    expect(usage, contains('gen'));
    expect(usage, contains('dart run fast_dev help gen'));
    expect(usage, contains('dart run fast_dev config'));
    expect(usage, contains('dart run fast_dev gen'));
  });

  test('子命令 usage 说明怎么跑', () {
    final runner = FastDevCommandRunner();
    expect(runner.commands['config']!.usage, contains('不写文件'));
    expect(runner.commands['gen']!.usage, contains('assets.gen.dart'));
  });
}
