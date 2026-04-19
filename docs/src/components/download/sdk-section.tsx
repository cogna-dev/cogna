import { useState } from "react"
import { motion } from "motion/react"
import { Check, Copy, FileJson } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { MoonBitIcon, NodeJsIcon, PnpmIcon, BunIcon, YarnIcon, NpmIcon } from "./platform-icons"

interface SdkSectionProps {
  data: {
    title: string
    description: string
    moonbit: {
      install: string
      usage: string
    }
    node: {
      npm: { install: string; usage: string }
      pnpm: { install: string; usage: string }
      yarn: { install: string; usage: string }
      bun: { install: string; usage: string }
    }
  }
}

const nodeIcons: Record<string, React.ReactNode> = {
  npm: <NpmIcon className="h-5 w-5" />,
  pnpm: <PnpmIcon className="h-5 w-5" />,
  yarn: <YarnIcon className="h-5 w-5" />,
  bun: <BunIcon className="h-5 w-5" />,
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

export function SdkSection({ data }: SdkSectionProps) {
  return (
    <div className="space-y-6">
      <div className="text-center max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-2">{data.title}</h2>
        <p className="text-muted-foreground">{data.description}</p>
      </div>

      {/* 第一层 Tabs: MoonBit vs Node */}
      <Tabs defaultValue="moonbit" className="w-full">
        <TabsList className="flex flex-wrap justify-center gap-2 h-auto p-1 bg-muted/50 rounded-full">
          <TabsTrigger
            value="moonbit"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
          >
            <MoonBitIcon className="h-4 w-4" />
            <span>MoonBit</span>
          </TabsTrigger>
          <TabsTrigger
            value="node"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
          >
            <NodeJsIcon className="h-4 w-4" />
            <span>Node.js</span>
          </TabsTrigger>
        </TabsList>

        {/* MoonBit Tab */}
        <TabsContent value="moonbit" className="mt-6">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <Card className="border-border/50">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                    <MoonBitIcon className="h-6 w-6" />
                  </div>
                  <div>
                    <CardTitle>MoonBit</CardTitle>
                    <CardDescription>原生支持 MoonBit 模块系统</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-6">
                <div>
                  <h4 className="text-sm font-medium mb-3">安装</h4>
                  <CodeBlock code={data.moonbit.install} />
                </div>
                <div>
                  <h4 className="text-sm font-medium mb-3">使用示例</h4>
                  <CodeBlock code={data.moonbit.usage} />
                </div>
              </CardContent>
            </Card>
          </motion.div>
        </TabsContent>

        {/* Node.js Tab - 第二层 Tabs */}
        <TabsContent value="node" className="mt-6">
          <Tabs defaultValue="npm" className="w-full">
            <TabsList className="flex flex-wrap justify-center gap-2 h-auto p-1 bg-muted/30 rounded-full mb-6">
              {[
                { key: "npm", label: "npm" },
                { key: "pnpm", label: "pnpm" },
                { key: "yarn", label: "Yarn" },
                { key: "bun", label: "Bun" },
              ].map(({ key, label }) => (
                <TabsTrigger
                  key={key}
                  value={key}
                  className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                >
                  {nodeIcons[key] || <FileJson className="h-4 w-4" />}
                  <span className="hidden sm:inline">{label}</span>
                </TabsTrigger>
              ))}
            </TabsList>

            {[
              { key: "npm", label: "npm" },
              { key: "pnpm", label: "pnpm" },
              { key: "yarn", label: "Yarn" },
              { key: "bun", label: "Bun" },
            ].map(({ key, label }) => (
              <TabsContent key={key} value={key} className="mt-0">
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <Card className="border-border/50">
                    <CardHeader>
                      <div className="flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                          {nodeIcons[key] || <FileJson className="h-6 w-6" />}
                        </div>
                        <div>
                          <CardTitle>{label}</CardTitle>
                          <CardDescription>使用 {label} 安装 @cogna/sdk</CardDescription>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-6">
                      <div>
                        <h4 className="text-sm font-medium mb-3">安装</h4>
                        <CodeBlock code={data.node[key].install} />
                      </div>
                      <div>
                        <h4 className="text-sm font-medium mb-3">使用示例</h4>
                        <CodeBlock code={data.node[key].usage} />
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              </TabsContent>
            ))}
          </Tabs>
        </TabsContent>
      </Tabs>
    </div>
  )
}
