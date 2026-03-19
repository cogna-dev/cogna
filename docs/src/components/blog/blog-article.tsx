import { Container } from "@/components/primitive/container"

export interface BlogAuthor {
  name: string
  avatar?: string
  bio?: string
}

export interface BlogArticleProps {
  title: string
  description: string
  date: Date
  cover?: string
  author: BlogAuthor
  tags: string[]
  children: React.ReactNode
}

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(date)
}

function AuthorAvatar({
  author,
  size = "sm",
}: {
  author: BlogAuthor
  size?: "sm" | "md"
}) {
  const sizeClasses = size === "sm" ? "w-8 h-8 text-xs" : "w-10 h-10 text-sm"
  if (author.avatar) {
    return (
      <img
        src={author.avatar}
        alt={author.name}
        className={`${sizeClasses} rounded-full`}
      />
    )
  }
  return (
    <div
      className={`${sizeClasses} rounded-full bg-primary text-primary-foreground flex items-center justify-center font-medium shrink-0`}
    >
      {author.name
        .split(" ")
        .map((n) => n[0])
        .join("")
        .slice(0, 2)}
    </div>
  )
}

export function BlogArticle({
  title,
  description,
  date,
  cover,
  author,
  tags,
  children,
}: BlogArticleProps) {
  return (
    <>
      <Container className="py-12 border-b">
        <div className="mx-auto flex flex-col gap-6">
          {tags.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {tags.map((tag) => (
                <span
                  key={tag}
                  className="bg-secondary text-secondary-foreground rounded-full px-3 py-1 text-xs font-medium"
                >
                  {tag}
                </span>
              ))}
            </div>
          )}
          <h1 className="text-4xl font-extrabold tracking-tight lg:text-5xl font-title">
            {title}
          </h1>
          <p className="text-xl text-muted-foreground font-body">
            {description}
          </p>
          <div className="flex items-center gap-3 text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <AuthorAvatar author={author} />
              <span className="font-medium text-foreground font-body">
                {author.name}
              </span>
            </div>
            <span>&middot;</span>
            <time dateTime={date.toISOString()}>{formatDate(date)}</time>
          </div>
          {cover && (
            <img
              src={cover}
              alt={title}
              className="w-full h-auto rounded-lg mt-2"
            />
          )}
        </div>
      </Container>

      <Container className="py-12">
        <div className="mx-auto">{children}</div>
      </Container>

      <Container className="pb-16">
        <div className="mx-auto border rounded-lg p-6 flex gap-4 items-start">
          <AuthorAvatar author={author} size="md" />
          <div className="flex flex-col gap-1">
            <p className="text-xs text-muted-foreground uppercase tracking-wider font-body">
              Written by
            </p>
            <p className="font-semibold font-body">{author.name}</p>
            {author.bio && (
              <p className="text-sm text-muted-foreground font-body">
                {author.bio}
              </p>
            )}
          </div>
        </div>
      </Container>
    </>
  )
}
