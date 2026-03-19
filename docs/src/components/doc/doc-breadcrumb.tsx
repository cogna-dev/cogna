import { ChevronRightIcon } from "lucide-react"
import * as React from "react"

interface DocBreadcrumbProps {
  currentPath: string
}

export function DocBreadcrumb({ currentPath }: DocBreadcrumbProps) {
  const path = currentPath.replace(/\/$/, "").replace(/^\//, "")
  const segments = path.split("/").filter(Boolean)

  return (
    <nav
      aria-label="Breadcrumb"
      className="flex items-center text-sm text-muted-foreground mb-4 font-body"
    >
      {segments.map((segment, index) => {
        const isLast = index === segments.length - 1
        const title = segment
          .split("-")
          .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
          .join(" ")

        return (
          <React.Fragment key={segment}>
            {index > 0 && (
              <ChevronRightIcon className="mx-2 h-4 w-4 shrink-0" />
            )}

            {isLast ? (
              <span className="font-medium text-foreground font-title">
                {title}
              </span>
            ) : segment === "docs" ? (
              <a
                href="/docs"
                className="hover:text-foreground transition-colors"
              >
                Docs
              </a>
            ) : (
              <span>{title}</span>
            )}
          </React.Fragment>
        )
      })}
    </nav>
  )
}
