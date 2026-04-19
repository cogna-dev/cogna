import { motion } from "motion/react"
import { Check, Download, Settings, Play, ExternalLink, FileJson } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { VSCodeIcon } from "./platform-icons"

interface VSCodeSectionProps {
  data: {
    title: string
    description: string
    extensionId: string
    features: string[]
    settings: Array<{ name: string; description: string }>
  }
}

export function VSCodeSection({ data }: VSCodeSectionProps) {
  const marketplaceUrl = `https://marketplace.visualstudio.com/items?itemName=${data.extensionId}`
  const vsixUrl = `https://github.com/cogna-dev/cogna/releases/latest/download/cogna-vscode.vsix`

  return (
    <div className="space-y-6">
      <div className="text-center max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-2">{data.title}</h2>
        <p className="text-muted-foreground">{data.description}</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Installation */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.3 }}
        >
          <Card className="h-full border-border/50">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                  <VSCodeIcon className="h-6 w-6" />
                </div>
                <div>
                  <CardTitle>安装</CardTitle>
                  <CardDescription>从 VSCode Marketplace 安装</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="p-4 rounded-lg bg-muted/50 border border-border/50">
                <h4 className="text-sm font-medium mb-2">VSCode Marketplace</h4>
                <p className="text-sm text-muted-foreground mb-3">
                  扩展 ID: <code className="px-1.5 py-0.5 rounded bg-background font-mono text-xs">{data.extensionId}</code>
                </p>
                <a
                  href={marketplaceUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-md bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-colors"
                >
                  <ExternalLink className="h-4 w-4" />
                  在 Marketplace 中查看
                </a>
              </div>

              <div className="p-4 rounded-lg bg-muted/50 border border-border/50">
                <h4 className="text-sm font-medium mb-2">下载 VSIX</h4>
                <p className="text-sm text-muted-foreground mb-3">
                  离线安装或自定义部署
                </p>
                <a
                  href={vsixUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-md bg-muted text-muted-foreground text-sm font-medium hover:bg-muted/80 transition-colors"
                >
                  <Download className="h-4 w-4" />
                  下载 VSIX
                </a>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Features & Settings */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.3, delay: 0.1 }}
          className="space-y-6"
        >
          {/* Features */}
          <Card className="border-border/50">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                  <Play className="h-5 w-5" />
                </div>
                <CardTitle className="text-lg">功能特性</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2">
                {data.features.map((feature, index) => (
                  <li key={index} className="flex items-start gap-2">
                    <Check className="h-4 w-4 text-primary mt-0.5 shrink-0" />
                    <span className="text-sm text-muted-foreground">{feature}</span>
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>

          {/* Settings */}
          <Card className="border-border/50">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                  <Settings className="h-5 w-5" />
                </div>
                <CardTitle className="text-lg">设置选项</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {data.settings.map((setting, index) => (
                  <div key={index} className="p-3 rounded-lg bg-muted/50">
                    <code className="text-sm font-mono text-primary">{setting.name}</code>
                    <p className="text-sm text-muted-foreground mt-1">{setting.description}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  )
}
