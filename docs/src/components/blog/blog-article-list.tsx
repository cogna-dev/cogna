import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { cn } from "@/lib/utils"

export interface ArticleItem {
  title: string
  description: string
  date: Date
  href: string
  cover?: string
  author?: {
    name: string
    avatar?: string
  }
  tags?: string[]
}

export interface BlogArticleListProps {
  articles: ArticleItem[]
  className?: string
}

export function BlogArticleList({ articles, className }: BlogArticleListProps) {
  return (
    <div
      className={cn(
        "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4",
        className,
      )}
    >
      {articles.map((article) => (
        <a key={article.href} href={article.href} className="block group">
          <Card className="h-full overflow-hidden transition-all duration-300 hover:scale-105 hover:shadow-lg dark:hover:shadow-primary/5 border-muted/60">
            {article.cover && (
              <div className="aspect-video w-full overflow-hidden border-b border-muted/60">
                <img
                  src={article.cover}
                  alt={article.title}
                  className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
              </div>
            )}
            <CardHeader className="gap-2 p-5">
              <div className="flex items-center justify-between gap-2">
                <time
                  dateTime={article.date.toISOString()}
                  className="text-xs font-medium text-muted-foreground/80 font-body"
                >
                  {new Intl.DateTimeFormat("en-US", {
                    month: "long",
                    day: "numeric",
                    year: "numeric",
                  }).format(article.date)}
                </time>
                {article.tags && article.tags.length > 0 && (
                  <div className="flex gap-1.5">
                    {article.tags.slice(0, 2).map((tag) => (
                      <span
                        key={tag}
                        className="inline-flex items-center rounded-sm bg-secondary px-1.5 py-0.5 text-[10px] font-medium text-secondary-foreground ring-1 ring-inset ring-secondary-foreground/10"
                      >
                        {tag}
                      </span>
                    ))}
                    {article.tags.length > 2 && (
                      <span className="text-[10px] text-muted-foreground font-body">
                        +{article.tags.length - 2}
                      </span>
                    )}
                  </div>
                )}
              </div>

              <CardTitle className="line-clamp-2 text-lg font-semibold tracking-tight group-hover:text-primary transition-colors font-title">
                {article.title}
              </CardTitle>

              <CardDescription className="line-clamp-3 text-sm text-muted-foreground/90 font-body">
                {article.description}
              </CardDescription>
            </CardHeader>

            {article.author && (
              <CardContent className="p-5 pt-0 mt-auto">
                <div className="flex items-center gap-2.5 pt-4 border-t border-muted/40">
                  {article.author.avatar ? (
                    <img
                      src={article.author.avatar}
                      alt={article.author.name}
                      className="h-6 w-6 rounded-full object-cover ring-1 ring-border"
                    />
                  ) : (
                    <div className="h-6 w-6 rounded-full bg-muted flex items-center justify-center text-[10px] font-bold text-muted-foreground ring-1 ring-border">
                      {article.author.name.charAt(0)}
                    </div>
                  )}
                  <span className="text-xs font-medium text-foreground/80 font-body">
                    {article.author.name}
                  </span>
                </div>
              </CardContent>
            )}
          </Card>
        </a>
      ))}
    </div>
  )
}
