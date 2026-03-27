export interface NavItem {
  title: string
  href: string
}

export interface NavGroup {
  title: string
  items: NavItem[]
}

export interface FooterGroup {
  title: string
  children: NavItem[]
}

export const topNavigation: NavItem[] = [
  { title: "快速开始", href: "/docs/quickstart" },
  { title: "用户文档", href: "/docs" },
  { title: "贡献者文档", href: "/contrib/introduction" },
  { title: "开发进度", href: "/contrib/progress" },
  { title: "GitHub", href: "https://github.com/yufeiminds/codeiq" },
]

export const userSidebar: NavGroup[] = [
  {
    title: "教程",
    items: [{ title: "快速开始", href: "/docs/quickstart" }],
  },
  {
    title: "操作指南",
    items: [
      { title: "发版检查", href: "/docs/release-check" },
      { title: "AI 查询", href: "/docs/mcp" },
      { title: "共享 Bundle", href: "/docs/bundle-sharing" },
    ],
  },
  {
    title: "参考",
    items: [
      { title: "CLI", href: "/docs/cli" },
      { title: "配置与 PURL", href: "/docs/config" },
      { title: "Bundle 与结果", href: "/docs/indexing" },
      { title: "MCP / Registry", href: "/docs/runtime-reference" },
    ],
  },
  {
    title: "解释",
    items: [
      { title: "概览", href: "/docs/introduction" },
      { title: "工作方式", href: "/docs/runtime-model" },
      { title: "支持范围", href: "/docs/providers" },
      { title: "当前状态", href: "/docs/progress" },
    ],
  },
]

export const contributorSidebar: NavGroup[] = [
  {
    title: "开始",
    items: [{ title: "贡献指南", href: "/contrib/introduction" }],
  },
  {
    title: "内部参考",
    items: [
      { title: "架构边界", href: "/contrib/architecture" },
      { title: "计划进展", href: "/contrib/progress" },
    ],
  },
]

export const footerMenus: FooterGroup[] = [
  {
    title: "用户文档",
    children: [
      { title: "快速开始", href: "/docs/quickstart" },
      { title: "用户文档", href: "/docs" },
      { title: "CLI", href: "/docs/cli" },
      { title: "产品状态", href: "/docs/progress" },
    ],
  },
  {
    title: "贡献者文档",
    children: [
      { title: "贡献指南", href: "/contrib/introduction" },
      { title: "架构边界", href: "/contrib/architecture" },
      { title: "开发进度", href: "/contrib/progress" },
      { title: "GitHub", href: "https://github.com/yufeiminds/codeiq" },
    ],
  },
]
