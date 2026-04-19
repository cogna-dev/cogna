import { motion } from "motion/react"
import { Download, Apple, Container, AppWindow } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

interface DesktopSectionProps {
  data: {
    title: string
    description: string
    platforms: Array<{
      name: string
      icon: string
      variants: Array<{ label: string; url: string }>
    }>
  }
}

const platformIcons: Record<string, React.ReactNode> = {
  macOS: <Apple className="h-6 w-6" />,
  Linux: <Container className="h-6 w-6" />,
  Windows: <AppWindow className="h-6 w-6" />,
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
}

export function DesktopSection({ data }: DesktopSectionProps) {
  return (
    <div className="space-y-6">
      <div className="text-center max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-2">{data.title}</h2>
        <p className="text-muted-foreground">{data.description}</p>
      </div>

      <motion.div
        className="grid gap-4 md:grid-cols-3"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        {data.platforms.map((platform) => (
          <motion.div key={platform.name} variants={itemVariants}>
            <Card className="h-full group hover:shadow-lg transition-all duration-300 border-border/50 hover:border-primary/20">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 text-primary group-hover:from-primary/20 group-hover:to-primary/10 transition-colors">
                    {platformIcons[platform.name]}
                  </div>
                  <div className="flex items-center gap-2">
                    <CardTitle className="text-lg">{platform.name}</CardTitle>
                    {platform.name === "macOS" && (
                      <Badge variant="secondary" className="text-xs">人工测试</Badge>
                    )}
                  </div>
                </div>
              </CardHeader>
              <CardContent className="pt-0">
                <div className="space-y-1.5">
                  {platform.variants.map((variant) => (
                    <a
                      key={variant.label}
                      href={variant.url}
                      className="flex items-center justify-between p-2 rounded-lg text-sm text-muted-foreground hover:text-foreground hover:bg-muted/80 transition-colors group/link"
                    >
                      <span>{variant.label}</span>
                      <Download className="h-3.5 w-3.5 opacity-0 group-hover/link:opacity-100 transition-opacity" />
                    </a>
                  ))}
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </motion.div>

      <div className="text-center text-sm text-muted-foreground">
        <p>
          查看{" "}
          <a href="https://github.com/cogna-dev/cogna/releases" className="text-primary hover:underline">
            GitHub Releases
          </a>{" "}
          获取所有历史版本
        </p>
      </div>
    </div>
  )
}
