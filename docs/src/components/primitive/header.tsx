import type { LucideIcon } from "lucide-react"
import { Menu as MenuIcon } from "lucide-react"
import { motion } from "motion/react"
import { Button } from "@/components/ui/button"
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
  navigationMenuTriggerStyle,
} from "@/components/ui/navigation-menu"
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet"
import { cn } from "@/lib/utils"
import { Container } from "@/components/primitive/container"
import {
  type LanguageOption,
  LanguageSwitcher,
} from "@/components/primitive/language-switcher"
import { ThemeSwitcher } from "@/components/primitive/theme-switcher"

export interface Menu {
  title: string
  href?: string
  icon?: LucideIcon
  children?: Menu[]
}

export interface HeaderProps {
  header: {
    title: string
    description: string
    menus: Menu[]
    homeHref?: string
    languageSwitcher?: {
      value: string
      options: LanguageOption[]
      ariaLabel?: string
    }
  }
  variant?: "contained" | "full"
}

function MobileNav({
  menus,
  languageSwitcher,
}: {
  menus: Menu[]
  languageSwitcher?: HeaderProps["header"]["languageSwitcher"]
}) {
  return (
    <nav className="flex flex-col gap-4 p-4">
      {menus.map((menu) => {
        const { title, href, children } = menu
        if (children) {
          return (
            <div key={title} className="space-y-2">
              <span className="text-sm font-medium text-muted-foreground">
                {title}
              </span>
              <div className="flex flex-col gap-1 pl-2">
                {children.map(({ title, href }) => (
                  <a
                    key={title}
                    href={href || ""}
                    className="text-sm py-1 hover:text-muted-foreground transition-colors font-body"
                  >
                    {title}
                  </a>
                ))}
              </div>
            </div>
          )
        }
        return (
          <a
            key={title}
            href={href || ""}
            className="text-sm font-medium py-1 hover:text-muted-foreground transition-colors font-body"
          >
            {title}
          </a>
        )
      })}

      {languageSwitcher ? (
        <LanguageSwitcher
          value={languageSwitcher.value}
          options={languageSwitcher.options}
          ariaLabel={languageSwitcher.ariaLabel}
          className="w-full"
        />
      ) : null}
    </nav>
  )
}

export function Header({ header, variant = "contained" }: HeaderProps) {
  const { title, menus, languageSwitcher, homeHref } = header

  const inner = (
    <div
      className={cn(
        "flex items-center justify-between py-4 border-b",
        variant === "full" ? "px-6 md:px-8" : "",
      )}
    >
      <div className="flex items-center gap-2">
        <a
          href={homeHref || "/"}
          className="text-sm font-bold hover:text-muted-foreground transition-colors font-brand"
        >
          {title}
        </a>
      </div>

      {/* Desktop navigation */}
      <div className="hidden md:block">
        <NavigationMenu className="mx-auto">
          <NavigationMenuList>
            {menus.map((menu) => {
              const { title, href, children } = menu
              return (
                <NavigationMenuItem key={title}>
                  {children ? (
                    <>
                      <NavigationMenuTrigger>{title}</NavigationMenuTrigger>
                      <NavigationMenuContent>
                        <ul className="grid gap-3 p-4">
                          {children.map(({ title, href }) => (
                            <li key={title}>
                              <a
                                href={href || ""}
                                className="hover:text-muted-foreground transition-colors"
                              >
                                {title}
                              </a>
                            </li>
                          ))}
                        </ul>
                      </NavigationMenuContent>
                    </>
                  ) : (
                    <NavigationMenuLink
                      href={href}
                      className={cn(navigationMenuTriggerStyle())}
                    >
                      {title}
                    </NavigationMenuLink>
                  )}
                </NavigationMenuItem>
              )
            })}
          </NavigationMenuList>
        </NavigationMenu>
      </div>

      <div className="flex items-center gap-2">
        {languageSwitcher ? (
          <LanguageSwitcher
            value={languageSwitcher.value}
            options={languageSwitcher.options}
            ariaLabel={languageSwitcher.ariaLabel}
          />
        ) : null}

        <ThemeSwitcher />

        {/* Mobile hamburger */}
        <Sheet>
          <SheetTrigger asChild>
            <Button variant="ghost" size="icon" className="md:hidden">
              <MenuIcon className="h-5 w-5" />
              <span className="sr-only">Open menu</span>
            </Button>
          </SheetTrigger>
          <SheetContent side="right" className="w-72">
            <MobileNav menus={menus} languageSwitcher={languageSwitcher} />
          </SheetContent>
        </Sheet>
      </div>
    </div>
  )

  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      {variant === "contained" ? <Container>{inner}</Container> : inner}
    </motion.div>
  )
}
