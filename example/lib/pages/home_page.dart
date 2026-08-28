import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/greeting.dart';

/// 首页。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _ticks = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _ticks++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('fast_dev example')),
      body: Center(child: Greeting(ticks: _ticks)),
    );
  }
}
