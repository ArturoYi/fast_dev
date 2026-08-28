---
layout: home

hero:
  name: Fast Dev
  text: 开发期用的 Flutter 工具
  tagline: 写在 dev_dependencies。根据 flutter.assets 生成类型安全的资源路径。
  image:
    src: /logo.svg
    alt: Fast Dev Logo
  actions:
    - theme: brand
      text: 开始
      link: /guide/getting-started
    - theme: alt
      text: 配置
      link: /guide/configuration
    - theme: alt
      text: GitHub
      link: https://github.com/ArturoYi/fast_dev

features:
  - title: 资源路径
    details: 读 pubspec.yaml 的 flutter.assets，写出 assets.gen.dart。路径写错会在编译期发现。
  - title: 主题和语言
    details: 可以把 light / dark、zh / en 目录收成一份资源，用 of(context) 选路径。
  - title: 自己的配置
    details: 建议在项目根放一份 fast_dev_config.yaml，类名、风格、输出目录都写清楚。
  - title: CLI / build_runner
    details: dart run fast_dev gen，或走 build_runner。两套入口，同一套结果。
---
