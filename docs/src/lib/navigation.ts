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
      { title: "文档检索", href: "/docs/build-indexes" },
      { title: "变更审查", href: "/docs/analyze-changes" },
      { title: "远程索引", href: "/docs/remote-indexing" },
    ],
  },
  {
    title: "集成",
    items: [
      { title: "Desktop", href: "/docs/desktop" },
      { title: "CLI", href: "/docs/cli" },
      { title: "SDK", href: "/docs/sdk" },
      { title: "IDE", href: "/docs/ide" },
      { title: "SKILL", href: "/docs/skill" },
      { title: "MCP", href: "/docs/mcp" },
      { title: "CI & CD", href: "/docs/ci" },
    ],
  },
  {
    title: "生态系统",
    items: [
      { title: "配置", href: "/docs/config" },
      { title: "Go (beta)", href: "/docs/go" },
      { title: "Rust (alpha)", href: "/docs/rust" },
      { title: "Terraform (alpha)", href: "/docs/terraform" },
      { title: "OpenAPI (alpha)", href: "/docs/openapi" },
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
]
