import 'package:dart_style/dart_style.dart';

import 'exception.dart';

/// 用 [lineLength] 格式化生成代码。失败则抛 [GenerateException]。
String formatGeneratedDart(String source, {required int lineLength}) {
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
    pageWidth: lineLength,
  );
  try {
    return formatter.format(source);
  } on FormatterException catch (e) {
    throw GenerateException('生成的 Dart 格式化失败：\n$e');
  }
}
