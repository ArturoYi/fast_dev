/// 配置解析或加载失败。
///
/// 这是配置模块对外的唯一错误类型：YAML 语法不对、字段类型不对、
/// `version` 不支持、指定的配置文件不存在等，都包装成它。
/// CLI 捕获后把 [message] 打到 stderr；调用方不必再依赖 `package:yaml`
/// 的异常类型。
final class ConfigException implements Exception {
  /// 创建一条可直接展示给用户的错误。
  const ConfigException(this.message);

  /// 给用户看的说明，已包含路径、期望类型、行列号（若有）。
  final String message;

  /// 某个配置项类型不对时使用，带上 YAML 节点的行列，方便定位。
  factory ConfigException.wrongType({
    required String path,
    required String expected,
    required Object actual,
    int? line,
    int? column,
  }) {
    final actualName = actual.runtimeType.toString();
    final location = (line != null && column != null)
        ? '（第 $line 行第 $column 列）'
        : '';
    return ConfigException('配置项 `$path` 应为 $expected，实际是 $actualName$location');
  }

  @override
  String toString() => 'ConfigException: $message';
}
