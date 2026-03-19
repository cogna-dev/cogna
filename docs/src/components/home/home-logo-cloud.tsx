"use client"

import { motion } from "motion/react"
import * as React from "react"
import { cn } from "@/lib/utils"
import { Container } from "@/components/primitive/container"

export interface LogoItem {
  name: string
  src: string
  href?: string
}

export interface LogoCloudProps {
  title?: string
  description?: string
  logos: LogoItem[]
  className?: string
}

export function LogoCloud({
  title,
  description,
  logos,
  className,
}: LogoCloudProps) {
  return (
    <Container className={cn("py-20", className)}>
      {(title || description) && (
        <div className="mb-8 text-center">
          {title && (
            <h2 className="text-2xl font-bold tracking-tight font-title">
              {title}
            </h2>
          )}
          {description && (
            <p className="mt-2 text-muted-foreground font-body">
              {description}
            </p>
          )}
        </div>
      )}
      <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
        {logos.map((logo, i) => {
          const content = (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.3, delay: i * 0.05 }}
              className="flex items-center justify-center grayscale opacity-70 transition-all hover:grayscale-0 hover:opacity-100"
            >
              <img
                src={logo.src}
                alt={logo.name}
                className="h-8 w-auto object-contain md:h-10 dark:invert"
              />
            </motion.div>
          )

          if (logo.href) {
            return (
              <a
                key={logo.name}
                href={logo.href}
                target="_blank"
                rel="noopener noreferrer"
              >
                {content}
              </a>
            )
          }

          return <React.Fragment key={logo.name}>{content}</React.Fragment>
        })}
      </div>
    </Container>
  )
}
