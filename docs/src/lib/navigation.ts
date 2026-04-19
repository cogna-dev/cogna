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
  { title: "用户文档", href: "/docs" },
  { title: "贡献者文档", href: "/contrib/introduction" },
  { title: "GitHub", href: "https://github.com/cogna-dev/cogna" },
]

export const userSidebar: NavGroup[] = [
  {
    title: "教程",
    items: [
      { title: "快速开始", href: "/docs/quickstart" },
    ],
  },
  {
    title: "操作指南",
    items: [
      { title: "构建索引", href: "/docs/build-indexes" },
      { title: "检索函数签名", href: "/docs/query-signatures" },
      { title: "分析变更", href: "/docs/analyze-changes" },
      { title: "远程索引", href: "/docs/remote-indexing" },
    ],
  },
  {
    title: "集成",
    items: [
      { title: "CLI", href: "/docs/cli" },
      { title: "IDE", href: "/docs/ide" },
      { title: "Web", href: "/docs/web" },
      { title: "MCP", href: "/docs/mcp" },
      { title: "持续集成", href: "/docs/ci" },
    ],
  },
  {
    title: "生态系统",
    items: [
      { title: "核心配置", href: "/docs/config" },
      { title: "Go", href: "/docs/go" },
      { title: "Rust", href: "/docs/rust" },
      { title: "Terraform", href: "/docs/terraform" },
      { title: "OpenAPI", href: "/docs/openapi" },
    ],
  },
  {
    title: "高级主题",
    items: [
      { title: "软件成分分析", href: "/docs/sca-spdx" },
      { title: "内置策略规则", href: "/docs/policies" },
      { title: "SARIF", href: "/docs/sarif" },
    ],
  },
]

export const contributorSidebar: NavGroup[] = [
  {
    title: "开始",
    items: [
      { title: "贡献指南", href: "/contrib/introduction" },
    ],
  },
  {
    title: "数据模型",
    items: [
      { title: "变更", href: "/contrib/changes" },
      { title: "策略", href: "/contrib/policy" },
    ],
  },
  {
    title: "附录",
    items: [
      { title: "开源协议", href: "/contrib/license" },
      { title: "行为准则", href: "/contrib/code-of-conduct" },
      { title: "CLA", href: "/contrib/cla" },
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
      { title: "支持范围", href: "/docs/providers" },
    ],
  },
  {
    title: "附录",
    children: [
      { title: "开源协议", href: "/contrib/license" },
      { title: "行为准则", href: "/contrib/code-of-conduct" },
      { title: "CLA", href: "/contrib/cla" },
    ],
  },
]
