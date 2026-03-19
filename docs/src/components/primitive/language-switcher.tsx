"use client"

import { Check, Languages } from "lucide-react"
import * as React from "react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { cn } from "@/lib/utils"

export interface LanguageOption {
  value: string
  label: string
  href: string
}

export interface LanguageSwitcherProps {
  value: string
  options: LanguageOption[]
  ariaLabel?: string
  className?: string
}

export function LanguageSwitcher({
  value,
  options,
  ariaLabel = "Switch language",
  className,
}: LanguageSwitcherProps) {
  const isFullWidth = className?.split(" ").includes("w-full")

  const handleSelect = React.useCallback((href: string) => {
    window.location.assign(href)
  }, [])

  if (options.length === 0) {
    return null
  }

  return (
    <div className={cn("inline-flex", className)}>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon" aria-label={ariaLabel}>
            <Languages className="h-4 w-4" />
            <span className="sr-only">{ariaLabel}</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent
          sideOffset={6}
          align={isFullWidth ? "start" : "end"}
          className={cn(
            isFullWidth
              ? "w-(--radix-dropdown-menu-trigger-width)"
              : "min-w-28",
          )}
        >
          {options.map((option) => (
            <DropdownMenuItem
              key={option.value}
              onSelect={() => handleSelect(option.href)}
              className={cn(
                "justify-between",
                option.value === value ? "font-medium" : "",
              )}
            >
              <span>{option.label}</span>
              {option.value === value ? <Check className="h-4 w-4" /> : null}
            </DropdownMenuItem>
          ))}
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  )
}
