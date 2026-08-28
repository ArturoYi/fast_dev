import 'package:flutter/widgets.dart';

import '../gen/fast_dev/assets.gen.dart';

/// 展示生成出来的资源路径。
class Greeting extends StatelessWidget {
  const Greeting({super.key, required this.ticks});

  final int ticks;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'fast_dev example\nconfig 命令已可用 · ticks=$ticks',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(ExampleAssets.images.logo.of(context)),
        Text(ExampleAssets.data.hello),
      ],
    );
  }
}
