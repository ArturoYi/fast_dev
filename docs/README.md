# 文档

VitePress。`base` 和仓库链接在 `.vitepress/config.ts`。

## 本地

Node 20+。

```bash
cd docs
npm ci
npm run docs:dev
```

`http://localhost:5173/fast_dev/`

```bash
npm run docs:build
npm run docs:preview
```

## 上线

GitHub Pages 用 Actions。推 `main` 上的 `docs/` 就会发。  
<https://arturoyi.github.io/fast_dev/>

中文在 `/`，英文在 `/en/`。搜索是本地 MiniSearch。
