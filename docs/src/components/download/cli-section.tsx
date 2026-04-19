import { useState } from "react"
import { motion } from "motion/react"
import { Check, Copy, Terminal } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

interface CliSectionProps {
  data: {
    title: string
    description: string
    installMethods: Array<{
      name: string
      icon: string
      code: string
    }>
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

export function CliSection({ data }: CliSectionProps) {
  return (
    <div className="space-y-6">
      <div className="text-center max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-2">{data.title}</h2>
        <p className="text-muted-foreground">{data.description}</p>
      </div>

      <Tabs defaultValue="curl" className="w-full">
        <TabsList className="flex flex-wrap justify-center gap-2 h-auto p-1 bg-muted/50 rounded-full">
          <TabsTrigger
            value="curl"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
          >
            <Terminal className="h-4 w-4" />
            <span className="hidden sm:inline">cURL (macOS/Linux)</span>
          </TabsTrigger>
          <TabsTrigger
            value="powershell"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
          >
            <Terminal className="h-4 w-4" />
            <span className="hidden sm:inline">PowerShell (Windows)</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="curl" className="mt-6">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <Card className="border-border/50">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                    <Terminal className="h-5 w-5" />
                  </div>
                  <CardTitle>cURL (macOS/Linux)</CardTitle>
                </div>
              </CardHeader>
              <CardContent>
                <CodeBlock code={`curl -fsSL https://github.com/cogna-dev/cogna/releases/latest/download/install.sh | sh`} />
              </CardContent>
            </Card>
          </motion.div>
        </TabsContent>

        <TabsContent value="powershell" className="mt-6">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <Card className="border-border/50">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary">
                    <Terminal className="h-5 w-5" />
                  </div>
                  <CardTitle>PowerShell (Windows)</CardTitle>
                </div>
              </CardHeader>
              <CardContent>
                <CodeBlock code={`irm https://github.com/cogna-dev/cogna/releases/latest/download/install.ps1 | iex`} />
              </CardContent>
            </Card>
          </motion.div>
        </TabsContent>
      </Tabs>

      <div className="text-center text-sm text-muted-foreground">
        <p>
          安装完成后，运行{" "}
          <code className="px-1.5 py-0.5 rounded bg-muted font-mono">cogna --version</code>{" "}
          验证安装
        </p>
      </div>
    </div>
  )
}
