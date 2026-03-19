import { motion } from "motion/react"
import { Button, type ButtonProps } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import { Container } from "@/components/primitive/container"

export interface HomeCtaProps {
  cta: {
    title: string
    description: string
    variant: "primary" | "secondary"
    action: {
      title: string
      href: string
      variant?: ButtonProps["variant"]
    }
  }
}

export function HomeCta({ cta }: HomeCtaProps) {
  const { variant, title, description, action } = cta
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.5 }}
      className={cn(
        "mx-4",
        variant === "primary" &&
          "bg-primary text-primary-foreground dark:bg-secondary dark:text-secondary-foreground",
        "rounded-2xl",
      )}
    >
      <Container className="gap-24 py-32">
        <div className="flex gap-4 basis-2/3">
          <div className="flex flex-col gap-4 basis-2/3">
            <h1 className="text-3xl font-bold font-title">{title}</h1>
            <p className="text-lg text-muted-foreground font-body">
              {description}
            </p>
          </div>
          <div className="flex flex-col gap-4 my-auto basis-1/3">
            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
              <Button
                variant="secondary"
                size="lg"
                className="border border-border"
                asChild
              >
                <a href={action.href}>{action.title}</a>
              </Button>
            </motion.div>
          </div>
        </div>
      </Container>
    </motion.div>
  )
}
