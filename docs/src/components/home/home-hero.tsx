"use client"

import { motion } from "motion/react"
import { Button, type ButtonProps } from "@/components/ui/button"
import { Container } from "@/components/primitive/container"

export interface HeroAction {
  title: string
  href: string
  variant?: ButtonProps["variant"]
  icon?: React.ComponentType<{ className?: string }>
}

export interface HomeHeroProps {
  hero: {
    title: string
    description: string
    actions: HeroAction[]
  }
}

export function HomeHero({ hero }: HomeHeroProps) {
  const { title, description, actions } = hero
  return (
    <Container className="pb-20 pt-28 lg:pb-44 lg:pt-36">
      <div className="flex flex-col lg:flex-row gap-24">
        <div className="my-auto flex flex-col gap-12 lg:basis-1/3">
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: "easeOut" }}
            className="text-4xl font-bold font-title"
          >
            {title}
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1, ease: "easeOut" }}
            className="text-xl font-body"
          >
            {description}
          </motion.p>
          <div className="flex gap-2">
            {actions?.map((action, index) => (
              <motion.div
                key={action.title}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{
                  duration: 0.5,
                  delay: 0.2 + index * 0.1,
                  ease: "easeOut",
                }}
              >
                <Button variant={action.variant} asChild>
                  <a href={action.href}>{action.title}</a>
                </Button>
              </motion.div>
            ))}
          </div>
        </div>
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.6, delay: 0.2, ease: "easeOut" }}
          className="lg:basis-2/3"
        >
          <img src="/images/hero.svg" alt="Hero" />
        </motion.div>
      </div>
    </Container>
  )
}
