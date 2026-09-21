/// 配置文件名与当前支持的 schema 版本。
///
/// 配置只放在项目根目录（与 `pubspec.yaml` 同级）的
/// [kConfigFileName] 里，**不会**再往 `pubspec.yaml` 写一份，
/// 避免和 Flutter 自己的字段混在一起。
///
/// 资源「打进包里的清单」仍然只认 `pubspec.yaml` 的 `flutter.assets` /
/// `flutter.fonts`；本文件只描述 **工具怎么做**（分组规则、输出目录、类名）。
/// 两份清单一旦分叉，运行时才会发现漏资源。
///
/// 当前解析 assets 与 fonts。`imports` / `generate.colors`
/// 写在配置里会告警并忽略，见 [kReservedRootConfigKeys] 与
/// [kReservedGenerateConfigKeys]。
library;

/// 用户项目根目录下的配置文件名。不要改成别的名字，加载逻辑按此查找。
const kConfigFileName = 'fast_dev_config.yaml';

/// 生成文件默认目录，相对项目根。内部以 `/` 结尾。
const kDefaultGenerateOutput = 'lib/gen/fast_dev/';

/// 当前解析器认识的 schema 版本。
///
/// YAML 里 `version` 缺省时按 1 处理；写了其它整数则直接失败，
/// 避免用新字段的文件被旧工具默默忽略。
const kCurrentConfigVersion = 1;

/// 当前会解析的根键。
const kKnownRootConfigKeys = {'version', 'generate'};

/// 根节点已预留、当前不解析。实现对应功能后移入 [kKnownRootConfigKeys]。
const kReservedRootConfigKeys = {'imports'};

/// `generate` 当前会解析的键。
const kKnownGenerateConfigKeys = {'output', 'line_length', 'assets', 'fonts'};

/// `generate` 已预留的键。实现后移入 [kKnownGenerateConfigKeys]。
const kReservedGenerateConfigKeys = {'colors'};

/// 一份已经和默认值合并过的完整配置。
///
/// YAML 里只写一部分时，未出现的字段保持 [FastDevConfig.defaults]。
/// 列表字段（如 `variants.locale.folders`）是 **整体替换** 不是追加。
final class FastDevConfig {
  /// 见各字段说明。
  const FastDevConfig({required this.version, required this.generate});

  /// 内置默认值。没有配置文件、或文件为空时用这一份。
  static const FastDevConfig defaults = FastDevConfig(
    version: kCurrentConfigVersion,
    generate: GenerateConfig.defaults,
  );

  /// schema 版本，目前必须是 [kCurrentConfigVersion]。
  final int version;

  /// 代码生成（assets / fonts）。
  final GenerateConfig generate;

  /// 把解析结果打成缩进文本，供 `fast_dev config` 打印。
  String toPrettyString({String indent = '  '}) {
    final buf = StringBuffer()
      ..writeln('version: $version')
      ..writeln('generate:')
      ..write(_indentBlock(generate.toPrettyString(), indent));
    return buf.toString().trimRight();
  }
}

/// 代码生成总开关与输出位置。
///
/// `output` 只决定生成文件写到哪；**不会**改变 Flutter 从哪里打包资源。
/// 后续生成器共用这两个字段，各自的段挂在 [assets] / [fonts] 旁边。
final class GenerateConfig {
  /// 见各字段说明。
  const GenerateConfig({
    required this.output,
    required this.lineLength,
    required this.assets,
    this.fonts = FontsGenerateConfig.defaults,
  });

  /// 未在 YAML 中出现时使用的默认值。
  static const GenerateConfig defaults = GenerateConfig(
    output: kDefaultGenerateOutput,
    lineLength: 80,
    assets: AssetsGenerateConfig.defaults,
    fonts: FontsGenerateConfig.defaults,
  );

  /// 生成文件目录，相对项目根。内部统一成 `/` 分隔且以 `/` 结尾。
  ///
  /// 默认 [kDefaultGenerateOutput]。
  final String output;

  /// 生成代码的行宽，交给 `dart_style`。YAML 键 `line_length`。
  final int lineLength;

  /// 图片 / 其它 asset。
  final AssetsGenerateConfig assets;

  /// 字体族。
  final FontsGenerateConfig fonts;

  /// 见 [FastDevConfig.toPrettyString]。
  String toPrettyString({String indent = '  '}) {
    final buf = StringBuffer()
      ..writeln('output: $output')
      ..writeln('line_length: $lineLength')
      ..writeln('assets:')
      ..write(_indentBlock(assets.toPrettyString(), indent))
      ..writeln('fonts:')
      ..write(_indentBlock(fonts.toPrettyString(), indent));
    return buf.toString().trimRight();
  }
}

/// 资源路径的类名风格。
///
/// YAML 里写字符串：`nested` / `camel` / `snake`。
enum AssetStyle {
  /// `Assets.images.logo`（默认）。
  nested,

  /// `Assets.imagesLogo`。
  camel,

  /// `Assets.images_logo`。
  snake,
}

/// `locale.fallback` 为这个值时，未匹配语言就用无语言目录的那份文件。
const kLocaleFallbackFile = 'file';

/// 语言目录比较用的键：忽略大小写，并把 `-` 当成 `_`。
///
/// `zh-CN` 与 `zh_CN` 视为同一语言，避免磁盘目录和配置写法不一致时拆成两项。
String normalizeLocaleFolderKey(String name) =>
    name.toLowerCase().replaceAll('-', '_');

/// `generate.fonts` 段。
final class FontsGenerateConfig {
  /// 见各字段说明。
  const FontsGenerateConfig({
    required this.enabled,
    required this.className,
    this.package = false,
    this.fallbacks = const [],
  });

  /// 未在 YAML 中出现时使用的默认值。
  static const FontsGenerateConfig defaults = FontsGenerateConfig(
    enabled: true,
    className: 'FontFamily',
  );

  /// 为 false 时不生成 `fonts.gen.dart`。
  final bool enabled;

  /// 生成的根类名。YAML 键 `class_name`，必须是合法 Dart 标识符。
  final String className;

  /// YAML 键 `package`。
  ///
  /// 为 true 时按库模式生成：写出 [className].package，成员值为
  /// `packages/$package/Family`，给其它包直接当 `fontFamily` 用。
  final bool package;

  /// YAML 键 `fallbacks`。`flutter.fonts` 里的 family 名，按这个顺序
  /// 生成 `FontFamily.fallbacks`，交给 `TextStyle.fontFamilyFallback`。
  ///
  /// 空列表（默认）不生成该成员。列表整份替换。
  final List<String> fallbacks;

  /// 见 [FastDevConfig.toPrettyString]。
  String toPrettyString({String indent = '  '}) {
    final buf = StringBuffer()
      ..writeln('enabled: $enabled')
      ..writeln('class_name: $className')
      ..writeln('package: $package')
      ..writeln('fallbacks:')
      ..write(_prettyList(fallbacks, indent));
    return buf.toString().trimRight();
  }
}

/// `generate.assets` 段。
final class AssetsGenerateConfig {
  /// 见各字段说明。
  const AssetsGenerateConfig({
    required this.enabled,
    required this.className,
    required this.style,
    this.variants = AssetsVariantsConfig.defaults,
  });

  /// 未在 YAML 中出现时使用的默认值。
  static const AssetsGenerateConfig defaults = AssetsGenerateConfig(
    enabled: true,
    className: 'Assets',
    style: AssetStyle.nested,
  );

  /// 为 false 时不生成 `assets.gen.dart`。
  final bool enabled;

  /// 生成的根类名。YAML 键 `class_name`，必须是合法 Dart 标识符。
  final String className;

  /// 路径怎么变成成员名。
  final AssetStyle style;

  /// 主题 / 语言目录变体。默认全关，以免把业务目录当成变体。
  final AssetsVariantsConfig variants;

  /// 见 [FastDevConfig.toPrettyString]。
  String toPrettyString({String indent = '  '}) {
    final buf = StringBuffer()
      ..writeln('enabled: $enabled')
      ..writeln('class_name: $className')
      ..writeln('style: ${style.name}')
      ..writeln('variants:')
      ..write(_indentBlock(variants.toPrettyString(indent: indent), indent));
    return buf.toString().trimRight();
  }
}

/// `generate.assets.variants`：light/dark 与语言目录。默认不识别。
final class AssetsVariantsConfig {
  /// 见各字段说明。
  const AssetsVariantsConfig({required this.theme, required this.locale});

  /// 未写 `variants:` 时：主题和语言都不剥目录。
  static const AssetsVariantsConfig defaults = AssetsVariantsConfig(
    theme: ThemeVariantsConfig.defaults,
    locale: LocaleVariantsConfig.defaults,
  );

  /// light / dark 目录。
  final ThemeVariantsConfig theme;

  /// zh / en 等语言目录。
  final LocaleVariantsConfig locale;

  /// 主题或语言至少开了一项。
  bool get anyEnabled => theme.enabled || locale.enabled;

  /// 见 [FastDevConfig.toPrettyString]。
  String toPrettyString({String indent = '  '}) {
    final buf = StringBuffer()
      ..writeln('theme:')
      ..write(_indentBlock(theme.toPrettyString(indent: indent), indent))
      ..writeln('locale:')
      ..write(_indentBlock(locale.toPrettyString(indent: indent), indent));
    return buf.toString().trimRight();
  }
}

/// `generate.assets.variants.theme`。
final class ThemeVariantsConfig {
  /// 见各字段说明。
  const ThemeVariantsConfig({
    required this.enabled,
    required this.lightFolders,
    required this.darkFolders,
  });

  /// 默认关闭；打开后才把 [lightFolders] / [darkFolders] 当变体。
  static const ThemeVariantsConfig defaults = ThemeVariantsConfig(
    enabled: false,
    lightFolders: ['light'],
    darkFolders: ['dark'],
  );

  /// 为 false 时 `light/`、`dark/` 仍是普通嵌套目录。
  final bool enabled;

  /// 亮色目录名。YAML：`folders.light`。
  final List<String> lightFolders;

  /// 暗色目录名。YAML：`folders.dark`。
  final List<String> darkFolders;

  /// 见 [FastDevConfig.toPrettyString]。
  String toPrettyString({String indent = '  '}) {
    final buf = StringBuffer()
      ..writeln('enabled: $enabled')
      ..writeln('light:')
      ..write(_prettyList(lightFolders, indent))
      ..writeln('dark:')
      ..write(_prettyList(darkFolders, indent));
    return buf.toString().trimRight();
  }
}

/// `generate.assets.variants.locale`。
final class LocaleVariantsConfig {
  /// 见各字段说明。
  const LocaleVariantsConfig({
    required this.enabled,
    required this.folders,
    required this.fallback,
  });

  /// 默认关闭；[folders] 为空。
  static const LocaleVariantsConfig defaults = LocaleVariantsConfig(
    enabled: false,
    folders: [],
    fallback: kLocaleFallbackFile,
  );

  /// 为 false 时语言目录名仍是普通嵌套目录。
  final bool enabled;

  /// 要剥掉的语言目录，必须显式列出。YAML：`folders`。
  final List<String> folders;

  /// 未匹配时：`file` 用无语言目录的文件，否则用这个语言码（须在 [folders] 里）。
  final String fallback;

  /// 见 [FastDevConfig.toPrettyString]。
  String toPrettyString({String indent = '  '}) {
    final buf = StringBuffer()
      ..writeln('enabled: $enabled')
      ..writeln('folders:')
      ..write(_prettyList(folders, indent))
      ..writeln('fallback: $fallback');
    return buf.toString().trimRight();
  }
}

String _prettyList(List<String> items, String indent) {
  if (items.isEmpty) {
    return '$indent(empty)\n';
  }
  final buf = StringBuffer();
  for (final item in items) {
    buf.writeln('$indent- $item');
  }
  return buf.toString();
}

String _indentBlock(String text, String indent) {
  final buf = StringBuffer();
  for (final line in text.split('\n')) {
    buf.writeln('$indent$line');
  }
  return buf.toString();
}
