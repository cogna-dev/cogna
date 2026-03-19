import Autoplay from "embla-carousel-autoplay"
import { motion } from "motion/react"
import type { ButtonProps } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
} from "@/components/ui/carousel"
import { cn } from "@/lib/utils"
import { Container } from "@/components/primitive/container"

export interface FeatureAction {
  title: string
  href: string
  variant?: ButtonProps["variant"]
  icon?: React.ComponentType<{ className?: string }>
}

export interface FeatureItem {
  title: string
  description: string
  cover?: string
  action: FeatureAction
  span?: 1 | 2 | 3
}

export interface HomeFeatureProps {
  feature: {
    title: string
    description: string
    variant?: "primary" | "default"
    layout: "bento" | "carousel"
    items: FeatureItem[]
  }
}

export function HomeFeature({ feature }: HomeFeatureProps) {
  const { variant, layout, title, description, items } = feature
  return (
    <div
      className={cn(
        "mx-4",
        variant === "primary" &&
          "bg-primary text-primary-foreground dark:bg-secondary dark:text-secondary-foreground",
        "rounded-2xl",
      )}
    >
      <Container className="gap-16 py-16">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="flex flex-col gap-4 py-8 px-2 basis-1/3"
        >
          <h1 className="text-3xl font-bold font-title">{title}</h1>
          <p className="text-lg text-muted-foreground font-body">
            {description}
          </p>
        </motion.div>
        {layout === "bento" && (
          <div className="grid grid-cols-3 gap-4">
            {items.map((item, index) => {
              const span = item.span || 3
              const spanVariants: Record<number, string> = {
                1: "lg:col-span-1",
                2: "lg:col-span-2",
                3: "lg:col-span-3",
              }
              return (
                <motion.a
                  key={item.title}
                  href={item.action.href}
                  className={cn(spanVariants[span], "col-span-3")}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                >
                  <Card className="h-full flex flex-col p-4 rounded-xl hover:scale-105 transition-all">
                    <CardHeader className="gap-2">
                      <CardTitle className="font-title">{item.title}</CardTitle>
                      <CardDescription className="text-base text-foreground font-body">
                        {item.description}
                      </CardDescription>
                    </CardHeader>
                    <CardContent className="flex-1 flex items-end">
                      {item.cover && (
                        <img
                          className="mx-auto max-h-48 w-full object-contain"
                          src={item.cover}
                          alt={item.title}
                        />
                      )}
                    </CardContent>
                  </Card>
                </motion.a>
              )
            })}
          </div>
        )}
        {layout === "carousel" && (
          <Carousel plugins={[Autoplay({ delay: 5000 })]} className="w-full">
            <CarouselContent>
              {items.map((item, index) => (
                <CarouselItem
                  key={item.title}
                  className="mx-auto md:basis-1/2 lg:basis-1/3"
                >
                  <motion.div
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.5, delay: index * 0.1 }}
                  >
                    <a href={item.action.href}>
                      <Card className="h-full flex flex-col p-6 rounded-xl hover:scale-105 transition-all">
                        <CardHeader className="gap-2">
                          <CardTitle className="font-title">
                            {item.title}
                          </CardTitle>
                          <CardDescription className="text-base text-foreground font-body">
                            {item.description}
                          </CardDescription>
                        </CardHeader>
                        <CardContent className="flex-1 flex items-end">
                          {item.cover && (
                            <img
                              className="mx-auto max-h-48 w-full object-contain"
                              src={item.cover}
                              alt={item.title}
                            />
                          )}
                        </CardContent>
                      </Card>
                    </a>
                  </motion.div>
                </CarouselItem>
              ))}
            </CarouselContent>
            <CarouselPrevious />
            <CarouselNext />
          </Carousel>
        )}
      </Container>
    </div>
  )
}
