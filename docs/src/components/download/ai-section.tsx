import { motion } from "motion/react"
import { Server, Terminal } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { NpmIcon, PnpmIcon, YarnIcon, BunIcon } from "./platform-icons"

interface AiSectionProps {
  data: {
    title: string
    description: string
  }
}

const skillIcons: Record<string, React.ReactNode> = {
  npm: <NpmIcon className="h-4 w-4" />,
  pnpm: <PnpmIcon className="h-4 w-4" />,
  yarn: <YarnIcon className="h-4 w-4" />,
  bun: <BunIcon className="h-4 w-4" />,
}

export function AiSection({ data }: AiSectionProps) {
  return (
    <div className="space-y-6">
      <div className="text-center max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-2">{data.title}</h2>
        <p className="text-muted-foreground">{data.description}</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* SKILL Card */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.3 }}
        >
          <Card className="h-full border-border/50">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                  <Server className="h-6 w-6" />
                </div>
                <div>
                  <CardTitle>SKILL</CardTitle>
                  <CardDescription>安装 @cogna-dev/skill 包</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Tabs defaultValue="npm" className="w-full">
                <TabsList className="flex flex-wrap justify-start gap-1 h-auto p-1 bg-muted/30 rounded-full mb-4">
                  {[
                    { key: "npm", label: "npm" },
                    { key: "pnpm", label: "pnpm" },
                    { key: "yarn", label: "Yarn" },
                    { key: "bun", label: "Bun" },
                  ].map(({ key, label }) => (
                    <TabsTrigger
                      key={key}
                      value={key}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                    >
                      {skillIcons[key]}
                      <span>{label}</span>
                    </TabsTrigger>
                  ))}
                </TabsList>

                <TabsContent value="npm" className="mt-0">
                  <pre className="p-3 rounded-lg bg-muted/50 border font-mono text-xs overflow-x-auto">
                    <code>npm install @cogna-dev/skill</code>
                  </pre>
                </TabsContent>
                <TabsContent value="pnpm" className="mt-0">
                  <pre className="p-3 rounded-lg bg-muted/50 border font-mono text-xs overflow-x-auto">
                    <code>pnpm add @cogna-dev/skill</code>
                  </pre>
                </TabsContent>
                <TabsContent value="yarn" className="mt-0">
                  <pre className="p-3 rounded-lg bg-muted/50 border font-mono text-xs overflow-x-auto">
                    <code>yarn add @cogna-dev/skill</code>
                  </pre>
                </TabsContent>
                <TabsContent value="bun" className="mt-0">
                  <pre className="p-3 rounded-lg bg-muted/50 border font-mono text-xs overflow-x-auto">
                    <code>bun add @cogna-dev/skill</code>
                  </pre>
                </TabsContent>
              </Tabs>
            </CardContent>
          </Card>
        </motion.div>

        {/* MCP Card */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.3, delay: 0.1 }}
          className="space-y-6"
        >
          {/* Claude Code */}
          <Card className="border-border/50">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                  <Terminal className="h-5 w-5" />
                </div>
                <CardTitle className="text-lg">Claude Code</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground mb-3">
                在 Claude Code 中使用 MCP 服务
              </p>
              <pre className="p-3 rounded-lg bg-muted/50 border font-mono text-xs overflow-x-auto">
                <code>{`# 在 Claude Code 配置中添加 MCP 服务
claude mcp add cogna http://localhost:3000/sse`}</code>
              </pre>
            </CardContent>
          </Card>

          {/* Inspector */}
          <Card className="border-border/50">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                  <Server className="h-5 w-5" />
                </div>
                <CardTitle className="text-lg">Inspector</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <h4 className="text-sm font-medium mb-2">安装 mcp-inspect</h4>
                <pre className="p-3 rounded-lg bg-muted/50 border font-mono text-xs overflow-x-auto">
                  <code>npm install -g @modelcontextprotocol/inspector</code>
                </pre>
              </div>
              <div>
                <h4 className="text-sm font-medium mb-2">启动 Inspector</h4>
                <pre className="p-3 rounded-lg bg-muted/50 border font-mono text-xs overflow-x-auto">
                  <code>mcp-inspector http://localhost:3000</code>
                </pre>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  )
}
