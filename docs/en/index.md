---
layout: home

hero:
  name: Fast Dev
  text: Flutter tooling for dev time
  tagline: Lives in dev_dependencies. Typed asset paths from flutter.assets.
  image:
    src: /logo.svg
    alt: Fast Dev Logo
  actions:
    - theme: brand
      text: Start
      link: /en/guide/getting-started
    - theme: alt
      text: Config
      link: /en/guide/configuration
    - theme: alt
      text: GitHub
      link: https://github.com/ArturoYi/fast_dev

features:
  - title: Asset paths
    details: Reads flutter.assets from pubspec.yaml and writes assets.gen.dart. Bad paths fail at compile time.
  - title: Theme and locale
    details: Fold light / dark and zh / en into one asset. Pick a path with of(context).
  - title: Your config
    details: Put a fast_dev_config.yaml at the package root. Class name, style, and output stay in the repo.
  - title: CLI / build_runner
    details: "One package, two entry points, same result: dart run fast_dev gen, or build_runner."
---
