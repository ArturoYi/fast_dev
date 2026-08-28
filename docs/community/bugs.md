---
title: 提 Bug
outline: [2, 3]
---

# 提 Bug

用 GitHub Issue。先搜一下 [已有的](https://github.com/ArturoYi/fast_dev/issues)。

用这个 **[模板](https://github.com/ArturoYi/fast_dev/issues/new?template=bug_report.yml)** 就行。

## 最好带上

1. **一句话**  
   比如：「开了 locale 之后，`zh_CN` 目录没被剥掉」。

2. **实际 / 期望**  
   分开写。

3. **最小复现**
   - 精简后的 `pubspec.yaml`（至少有 `flutter.assets`）
   - `fast_dev_config.yaml`
   - 资源目录（`find assets -type f`）
   - 跑的命令（`dart run fast_dev gen` 或 `build_runner`）

4. **环境**
   - Fast Dev / runner 版本，或 git commit
   - Dart / Flutter 版本
   - 系统
   - CLI 还是 `build_runner`

5. **完整输出**  
   「已生成 / 已跳过 / 警告」或相关日志，告警留着。

## 不太够的

- 只说「生成不对」，没有配置和目录
- 整个商业项目打成 zip（先裁一下）
- 密钥、证书、内部包名
- 新想法走 [功能模板](https://github.com/ArturoYi/fast_dev/issues/new?template=feature_request.yml)

## 安全

和供应链、恶意生成代码有关的，还是开 Issue。利用细节先别贴到公开评论。
