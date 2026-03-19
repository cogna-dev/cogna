import { cn } from "@/lib/utils"

export interface DocTocHeading {
  depth: number
  slug: string
  text: string
}

export interface DocTocProps {
  headings: DocTocHeading[]
}

export function DocToc({ headings }: DocTocProps) {
  const tocHeadings = headings.filter((h) => h.depth === 2 || h.depth === 3)

  if (tocHeadings.length === 0) return null

  return (
    <div className="sticky top-20">
      <p className="text-sm font-medium mb-4 font-title">On this page</p>
      <nav className="flex flex-col gap-2">
        {tocHeadings.map((h) => (
          <a
            key={h.slug}
            href={`#${h.slug}`}
            className={cn(
              "text-sm text-muted-foreground hover:text-foreground transition-colors",
              h.depth === 3 && "pl-4",
            )}
          >
            {h.text}
          </a>
        ))}
      </nav>
    </div>
  )
}
