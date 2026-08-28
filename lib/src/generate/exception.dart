/// 代码生成失败。
///
/// 读 pubspec、展开资源、格式化生成代码出错时抛这个，和配置解析错误分开，
/// 方便 CLI 用同一套退出码但文案来源不同。
final class GenerateException implements Exception {
  /// 创建一条可直接展示给用户的错误。
  const GenerateException(this.message);

  /// 给用户看的说明。
  final String message;

  @override
  String toString() => 'GenerateException: $message';
}
