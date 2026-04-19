import { useState } from "react"
import { motion } from "motion/react"
import { Monitor, Terminal, Package, Code2, Bot, Download } from "lucide-react"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { DesktopSection } from "./desktop-section"
import { CliSection } from "./cli-section"
import { SdkSection } from "./sdk-section"
import { VSCodeSection } from "./vscode-section"
import { AiSection } from "./ai-section"

interface DownloadTabsProps {
  data: {
    desktop: {
      title: string
      description: string
      platforms: Array<{
        name: string
        icon: string
        variants: Array<{ label: string; url: string }>
      }>
    }
    cli: {
      title: string
      description: string
      installMethods: Array<{
        name: string
        icon: string
        code: string
      }>
    }
    sdk: {
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
    vscode: {
      title: string
      description: string
      extensionId: string
      features: string[]
      settings: Array<{ name: string; description: string }>
    }
    ai: {
      title: string
      description: string
    }
  }
}

const tabItems = [
  { id: "desktop", label: "Desktop", icon: Monitor },
  { id: "cli", label: "CLI", icon: Terminal },
  { id: "sdk", label: "SDK", icon: Package },
  { id: "vscode", label: "VSCode", icon: Code2 },
  { id: "ai", label: "AI", icon: Bot },
]

export function DownloadTabs({ data }: DownloadTabsProps) {
  const [activeTab, setActiveTab] = useState("desktop")

  return (
    <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
      <div className="flex justify-center mb-8">
        <TabsList className="inline-flex items-center gap-1 p-1.5 bg-muted/50 rounded-full">
          {tabItems.map((item) => {
            const Icon = item.icon
            return (
              <TabsTrigger
                key={item.id}
                value={item.id}
                className="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium rounded-full transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm hover:text-foreground/80"
              >
                <Icon className="h-4 w-4" />
                <span>{item.label}</span>
              </TabsTrigger>
            )
          })}
        </TabsList>
      </div>

      <div className="min-h-[400px]">
        <TabsContent value="desktop" className="mt-0">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            <DesktopSection data={data.desktop} />
          </motion.div>
        </TabsContent>

        <TabsContent value="cli" className="mt-0">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            <CliSection data={data.cli} />
          </motion.div>
        </TabsContent>

        <TabsContent value="sdk" className="mt-0">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            <SdkSection data={data.sdk} />
          </motion.div>
        </TabsContent>

        <TabsContent value="vscode" className="mt-0">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            <VSCodeSection data={data.vscode} />
          </motion.div>
        </TabsContent>

        <TabsContent value="ai" className="mt-0">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            <AiSection data={data.ai} />
          </motion.div>
        </TabsContent>
      </div>
    </Tabs>
  )
}
