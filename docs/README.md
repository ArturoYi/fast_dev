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

仓库 [Settings → Pages](https://github.com/ArturoYi/fast_dev/settings/pages) 的 Source 选 **GitHub Actions**，否则 `deploy-pages` 会 404。  
之后推 `main` 上的 `docs/`（或手动跑 `Deploy documentation`）就会发。  
<https://arturoyi.github.io/fast_dev/>

中文在 `/`，英文在 `/en/`。搜索是本地 MiniSearch。
