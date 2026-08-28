import { defineConfig, type HeadConfig } from 'vitepress'

const githubRepo = 'ArturoYi/fast_dev'
const siteBase = '/fast_dev/'
const githubUrl = `https://github.com/${githubRepo}`

/** head 里的绝对路径不会自动加 base，需与 siteBase 一致 */
const sharedHead: HeadConfig[] = [
  ['link', { rel: 'icon', href: `${siteBase}favicon.svg`, type: 'image/svg+xml' }],
]

const sharedLogo = {
  src: '/logo.svg',
  alt: 'Fast Dev',
  height: 24,
}

/** Must live on root themeConfig — local search plugin ignores locales-only config. */
const sharedSearch = {
  provider: 'local' as const,
  options: {
    locales: {
      root: {
        translations: {
          button: {
            buttonText: '搜索',
            buttonAriaLabel: '搜索文档',
          },
          modal: {
            noResultsText: '未找到结果',
            resetButtonTitle: '清除查询条件',
            backButtonTitle: '返回',
            displayDetails: '显示详细列表',
            footer: {
              selectText: '选择',
              selectKeyAriaLabel: 'Enter 键',
              navigateText: '切换',
              navigateUpKeyAriaLabel: '上箭头',
              navigateDownKeyAriaLabel: '下箭头',
              closeText: '关闭',
              closeKeyAriaLabel: 'Esc 键',
            },
          },
        },
      },
      en: {
        translations: {
          button: {
            buttonText: 'Search',
            buttonAriaLabel: 'Search documentation',
          },
        },
      },
    },
  },
}

const sidebarZhGroups = [
  {
    text: '入门',
    items: [
      { text: '定位', link: '/guide/introduction' },
      { text: '开始', link: '/guide/getting-started' },
      { text: 'CLI', link: '/guide/cli' },
      { text: '配置', link: '/guide/configuration' },
      { text: 'build_runner', link: '/guide/build-runner' },
      { text: '计划', link: '/guide/roadmap' },
    ],
  },
  {
    text: '能力',
    items: [{ text: 'Assets', link: '/features/assets' }],
  },
  {
    text: '社区',
    items: [
      { text: '贡献', link: '/community/contributing' },
      { text: '提 Bug', link: '/community/bugs' },
      { text: '许可证', link: '/community/license' },
    ],
  },
]

const sidebarEnGroups = [
  {
    text: 'Getting started',
    items: [
      { text: 'About', link: '/en/guide/introduction' },
      { text: 'Start', link: '/en/guide/getting-started' },
      { text: 'CLI', link: '/en/guide/cli' },
      { text: 'Configuration', link: '/en/guide/configuration' },
      { text: 'build_runner', link: '/en/guide/build-runner' },
      { text: 'Roadmap', link: '/en/guide/roadmap' },
    ],
  },
  {
    text: 'Features',
    items: [{ text: 'Assets', link: '/en/features/assets' }],
  },
  {
    text: 'Community',
    items: [
      { text: 'Contributing', link: '/en/community/contributing' },
      { text: 'Bugs', link: '/en/community/bugs' },
      { text: 'License', link: '/en/community/license' },
    ],
  },
]

function sidebarForPrefixes(prefixes: string[], groups: typeof sidebarZhGroups) {
  return Object.fromEntries(prefixes.map((prefix) => [prefix, groups]))
}

const docSidebarPrefixesZh = ['/guide/', '/features/', '/community/']
const docSidebarPrefixesEn = ['/en/guide/', '/en/features/', '/en/community/']

export default defineConfig({
  base: siteBase,
  title: 'Fast Dev',
  description: '开发期用的 Flutter 工具：CLI 和 build_runner 生成类型安全的资源路径',
  lastUpdated: true,
  head: sharedHead,
  srcExclude: ['README.md'],
  themeConfig: {
    search: sharedSearch,
  },
  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      link: '/',
      themeConfig: {
        logo: sharedLogo,
        search: sharedSearch,
        nav: [
          {
            text: '文档',
            link: '/guide/getting-started',
            activeMatch: '^/(guide|features|community)/',
          },
          { text: 'GitHub', link: githubUrl },
          { text: 'pub.dev', link: 'https://pub.dev/packages/fast_dev' },
        ],
        sidebar: sidebarForPrefixes(docSidebarPrefixesZh, sidebarZhGroups),
        outline: {
          level: [2, 4],
          label: '本页大纲',
        },
        socialLinks: [{ icon: 'github', link: githubUrl }],
        editLink: {
          pattern: `${githubUrl}/edit/main/docs/:path`,
          text: '在 GitHub 上编辑此页',
        },
        lastUpdated: {
          text: '最后更新',
        },
        footer: {
          message: 'MIT License',
          copyright: 'Copyright © ChenYiRen',
        },
      },
    },
    en: {
      label: 'English',
      lang: 'en-US',
      description: 'Flutter dev-time tool: typed asset paths via CLI or build_runner',
      link: '/en/',
      themeConfig: {
        logo: sharedLogo,
        search: sharedSearch,
        nav: [
          {
            text: 'Docs',
            link: '/en/guide/getting-started',
            activeMatch: '^/en/(guide|features|community)/',
          },
          { text: 'GitHub', link: githubUrl },
          { text: 'pub.dev', link: 'https://pub.dev/packages/fast_dev' },
        ],
        sidebar: sidebarForPrefixes(docSidebarPrefixesEn, sidebarEnGroups),
        outline: {
          level: [2, 4],
          label: 'On this page',
        },
        socialLinks: [{ icon: 'github', link: githubUrl }],
        editLink: {
          pattern: `${githubUrl}/edit/main/docs/:path`,
          text: 'Edit this page on GitHub',
        },
        lastUpdated: {
          text: 'Last updated',
        },
        footer: {
          message: 'MIT License',
          copyright: 'Copyright © ChenYiRen',
        },
      },
    },
  },
})
