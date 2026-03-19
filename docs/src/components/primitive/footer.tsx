import { Github, Linkedin, Twitter } from "lucide-react"
import { motion } from "motion/react"

import { Container } from "@/components/primitive/container"

export interface FooterMenu {
  title: string
  href?: string
  children?: FooterMenu[]
}

export interface Socials {
  github?: string
  linkedin?: string
  twitter?: string
}

export interface FooterProps {
  socials?: Socials
  footer: {
    title: string
    description: string
    menus: FooterMenu[]
    copyright: string
  }
}

export function Footer({ footer, socials }: FooterProps) {
  const { title, description, copyright, menus } = footer
  return (
    <motion.footer
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.5 }}
      className="my-12"
    >
      <Container className="border-t py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-24">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="md:col-span-1 space-y-4"
          >
            <h1 className="text-lg font-semibold tracking-tight font-brand">
              {title}
            </h1>
            <p className="text-sm leading-relaxed font-body">{description}</p>
            <div className="flex items-center space-x-4">
              {socials?.github && (
                <a
                  href={socials.github}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-muted-foreground transition-colors"
                >
                  <Github className="h-5 w-5" />
                </a>
              )}
              {socials?.linkedin && (
                <a
                  href={socials.linkedin}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-muted-foreground transition-colors"
                >
                  <Linkedin className="h-5 w-5" />
                </a>
              )}
              {socials?.twitter && (
                <a
                  href={socials.twitter}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-muted-foreground transition-colors"
                >
                  <Twitter className="h-5 w-5" />
                </a>
              )}
            </div>
            <p className="text-sm font-body">
              Copyright {copyright} &copy; {new Date().getFullYear()}
            </p>
          </motion.div>
          <div className="md:col-span-3">
            <nav className="flex flex-wrap gap-x-16 gap-y-8 justify-center">
              {menus?.map(({ title, children }, index) => (
                <motion.div
                  key={title}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: 0.2 + index * 0.1 }}
                  className="space-y-4"
                >
                  <h3 className="text-lg font-semibold tracking-tight font-title">
                    {title}
                  </h3>
                  <ul className="space-y-2">
                    {children?.map(({ title, href }) => {
                      const resolvedHref = href || ""
                      const isExternal = resolvedHref.startsWith("http")
                      return (
                        <li key={title}>
                          <a
                            href={resolvedHref}
                            target={isExternal ? "_blank" : undefined}
                            rel={isExternal ? "noopener noreferrer" : undefined}
                            className="text-sm hover:text-muted-foreground transition-colors font-body"
                          >
                            {title}
                          </a>
                        </li>
                      )
                    })}
                  </ul>
                </motion.div>
              ))}
            </nav>
          </div>
        </div>
      </Container>
    </motion.footer>
  )
}
