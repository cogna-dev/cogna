import { useState } from "react"
import { motion } from "motion/react"
import { Check, Copy, Server, Terminal, Play } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

interface McpSectionProps {
  data: {
    title: string
    description: string
  }
}

function CodeBlock({ code, language = "bash" }: { code: string; language?: string }) {
  const [copied, setCopied] = useState(false)

  const copyToClipboard = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="relative group">
      <div className="absolute right-2 top-2 opacity-0 group-hover:opacity-100 transition-opacity">
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8 bg-background/80 backdrop-blur-sm"
          onClick={copyToClipboard}
        >
          {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
        </Button>
      </div>
      <pre className="p-4 rounded-lg bg-muted/50 border font-mono text-sm overflow-x-auto">
        <code>{code}</code>
      </pre>
    </div>
  )
}

export function McpSection({ data }: McpSectionProps) {
  return (
    <div className="space-y-6">
      <div className="text-center max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-2">{data.title}</h2>
        <p className="text-muted-foreground">{data.description}</p>
      </div>

      <Tabs defaultValue="skill" className="w-full">
        <TabsList className="flex flex-wrap justify-center gap-2 h-auto p-1 bg-muted/50 rounded-full">
          <TabsTrigger
            value="skill"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
          >
            <Server className="h-4 w-4" />
            <span className="hidden sm:inline">pnpm skill</span>
          </TabsTrigger>
          <TabsTrigger
            value="local"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
          >
            <Terminal className="h-4 w-4" />
            <span className="hidden sm:inline">本地启动</span>
          </TabsTrigger>
        </TabsList>

        {/* pnpm skill Tab */}
        <TabsContent value="skill" className="mt-6">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <Card className="border-border/50">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                    <Server className="h-6 w-6" />
                  </div>
                  <div>
                    <CardTitle>pnpm skill 安装</CardTitle>
                    <CardDescription>通过 pnpm 安装 MCP skill</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-6">
                <div>
                  <h4 className="text-sm font-medium mb-3">安装</h4>
                  <CodeBlock code={`pnpm skill add @cogna/mcp`} />
                </div>
                <div>
                  <h4 className="text-sm font-medium mb-3">配置</h4>
                  <p className="text-sm text-muted-foreground mb-3">
                    安装后，pnpm 会自动将 MCP 服务添加到 Claude Desktop 配置中。
                  </p>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        </TabsContent>

        {/* 本地启动 Tab */}
        <TabsContent value="local" className="mt-6">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <Card className="border-border/50">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                    <Terminal className="h-6 w-6" />
                  </div>
                  <div>
                    <CardTitle>本地启动</CardTitle>
                    <CardDescription>本地启动 MCP 服务并使用 mcp-inspect 调试</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-6">
                <div>
                  <h4 className="text-sm font-medium mb-3">1. 本地启动 MCP 服务</h4>
                  <CodeBlock code={`# 克隆仓库
git clone https://github.com/cogna-dev/cogna.git
cd cogna

# 启动 MCP 服务
pnpm mcp:serve

# 或者使用 npm
npm run mcp:serve`} />
                </div>

                <div>
                  <h4 className="text-sm font-medium mb-3">2. 安装 mcp-inspect</h4>
                  <CodeBlock code={`# 全局安装 mcp-inspect
npm install -g @anthropics/mcp-inspect

# 或者使用 pnpm
pnpm add -g @anthropics/mcp-inspect`} />
                </div>

                <div>
                  <h4 className="text-sm font-medium mb-3">3. 使用 mcp-inspect 调试</h4>
                  <CodeBlock code={`# 连接到本地 MCP 服务
mcp-inspect http://localhost:3000

# 或者指定 SSE 端点
mcp-inspect http://localhost:3000/sse`} />
                </div>

                <div className="p-4 rounded-lg bg-muted/50 border border-border/50">
                  <div className="flex items-start gap-3">
                    <Play className="h-5 w-5 text-primary mt-0.5" />
                    <div>
                      <h4 className="text-sm font-medium mb-1">提示</h4>
                      <p className="text-sm text-muted-foreground">
                        mcp-inspect 是一个交互式调试工具，可以帮助你测试 MCP 服务的各种功能，
                        包括资源访问、工具调用等。
                      </p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
