import 'dart:io';

import 'package:fast_dev/src/cli/runner.dart';

/// 可执行入口。逻辑全在 [runFastDev]，这里只负责设置 [exitCode]。
void main(List<String> args) async {
  exitCode = await runFastDev(args);
}
