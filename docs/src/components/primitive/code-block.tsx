import { Check, Copy, FileCode } from "lucide-react"
import { AnimatePresence, motion } from "motion/react"
import * as React from "react"
import { codeToHtml } from "shiki"
import { cn } from "@/lib/utils"

const LIGHT_SHIKI_THEME = "github-light"
const DARK_SHIKI_THEME = "andromeeda"

// ── Shared copy button with animated feedback ───────────────────

export function CopyButton({
  getText,
  className,
}: {
  getText: () => string
  className?: string
}) {
  const [copied, setCopied] = React.useState(false)

  const handleCopy = React.useCallback(() => {
    navigator.clipboard.writeText(getText()).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    })
  }, [getText])

  return (
    <button
      type="button"
      onClick={handleCopy}
      className={cn(
        "absolute right-3 top-3 z-10 flex items-center gap-1 rounded-md border bg-background/80 px-2 py-1 text-xs text-muted-foreground backdrop-blur-sm transition-colors hover:bg-muted hover:text-foreground",
        className,
      )}
    >
      <AnimatePresence mode="wait" initial={false}>
        {copied ? (
          <motion.span
            key="check"
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.8 }}
            transition={{ duration: 0.15 }}
            className="flex items-center gap-1"
          >
            <Check className="h-3 w-3" />
            Copied!
          </motion.span>
        ) : (
          <motion.span
            key="copy"
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.8 }}
            transition={{ duration: 0.15 }}
            className="flex items-center gap-1"
          >
            <Copy className="h-3 w-3" />
            Copy
          </motion.span>
        )}
      </AnimatePresence>
    </button>
  )
}

// ── Terminal chrome wrapper ─────────────────────────────────────

export interface TerminalProps {
  title?: string
  children: React.ReactNode
  className?: string
  /** Provide a getter for the copy text. If omitted, the copy button is hidden. */
  getText?: () => string
}

export function Terminal({
  title,
  children,
  className,
  getText,
}: TerminalProps) {
  return (
    <div
      className={cn(
        "rounded-lg border bg-card text-card-foreground overflow-hidden",
        className,
      )}
    >
      <div className="relative flex items-center justify-center border-b bg-muted/50 px-4 py-3">
        <div className="absolute left-4 top-1/2 flex -translate-y-1/2 items-center gap-2">
          <span className="h-3 w-3 rounded-full bg-[#FF5F56]" />
          <span className="h-3 w-3 rounded-full bg-[#FFBD2E]" />
          <span className="h-3 w-3 rounded-full bg-[#27C93F]" />
        </div>
        {title && (
          <span className="text-sm font-medium text-muted-foreground font-code">
            {title}
          </span>
        )}
      </div>
      <div className="relative">
        {getText && <CopyButton getText={getText} />}
        <div className="max-h-[600px] overflow-auto text-sm font-code [&_pre]:p-4 [&_pre]:m-0 [&_pre]:!bg-transparent [&_code]:!bg-transparent">
          {children}
        </div>
      </div>
    </div>
  )
}

// ── Client-side Shiki highlighter ───────────────────────────────

export function HighlightedCode({
  code,
  language,
}: {
  code: string
  language: string
}) {
  const ref = React.useRef<HTMLDivElement>(null)
  const [ready, setReady] = React.useState(false)
  const [isDark, setIsDark] = React.useState(true)

  React.useEffect(() => {
    const root = document.documentElement
    const syncTheme = () => {
      setIsDark(root.classList.contains("dark"))
    }

    syncTheme()

    const observer = new MutationObserver(() => {
      syncTheme()
    })

    observer.observe(root, {
      attributes: true,
      attributeFilter: ["class"],
    })

    return () => {
      observer.disconnect()
    }
  }, [])

  React.useEffect(() => {
    let cancelled = false
    setReady(false)

    codeToHtml(code, {
      lang: language,
      theme: isDark ? DARK_SHIKI_THEME : LIGHT_SHIKI_THEME,
    }).then((result) => {
      if (!cancelled && ref.current) {
        ref.current.innerHTML = result
        setReady(true)
      }
    })
    return () => {
      cancelled = true
    }
  }, [code, isDark, language])

  return (
    <>
      <div ref={ref} className={cn(!ready && "hidden")} />
      {!ready && (
        <pre className="p-4 font-code">
          <code>{code}</code>
        </pre>
      )}
    </>
  )
}

// ── CodeBlock component ─────────────────────────────────────────

export interface CodeBlockProps {
  code: string
  language?: string
  filename?: string
  showLineNumbers?: boolean
  className?: string
  variant?: "default" | "terminal" | "filename"
}

export function CodeBlock({
  code,
  language = "tsx",
  filename,
  showLineNumbers = false,
  className,
  variant,
}: CodeBlockProps) {
  const effectiveVariant = variant || (filename ? "filename" : "default")
  const getText = React.useCallback(() => code, [code])

  const codeContent = (
    <div
      className={cn(
        showLineNumbers &&
          "[&_.line]:before:mr-4 [&_.line]:before:inline-block [&_.line]:before:w-4 [&_.line]:before:text-right [&_.line]:before:text-muted-foreground [&_.line]:before:content-[counter(line)] [&_.line]:before:[counter-increment:line] [&_pre]:[counter-reset:line]",
      )}
    >
      <HighlightedCode code={code} language={language} />
    </div>
  )

  if (effectiveVariant === "terminal") {
    return (
      <Terminal title={filename} className={className} getText={getText}>
        {codeContent}
      </Terminal>
    )
  }

  return (
    <div
      className={cn(
        "rounded-lg border bg-card text-card-foreground overflow-hidden",
        className,
      )}
    >
      {effectiveVariant === "filename" && (
        <div className="flex items-center justify-between border-b bg-muted/50 px-4 py-2">
          <div className="flex items-center gap-2">
            <FileCode className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm font-medium font-code">{filename}</span>
          </div>
          <span className="text-xs text-muted-foreground font-code">
            {language}
          </span>
        </div>
      )}
      <div className="relative">
        <CopyButton getText={getText} />
        <div
          className={cn(
            "max-h-[600px] overflow-auto text-sm font-code [&_pre]:p-4 [&_pre]:m-0 [&_pre]:!bg-transparent [&_code]:!bg-transparent",
            showLineNumbers &&
              "[&_.line]:before:mr-4 [&_.line]:before:inline-block [&_.line]:before:w-4 [&_.line]:before:text-right [&_.line]:before:text-muted-foreground [&_.line]:before:content-[counter(line)] [&_.line]:before:[counter-increment:line] [&_pre]:[counter-reset:line]",
          )}
        >
          <HighlightedCode code={code} language={language} />
        </div>
      </div>
    </div>
  )
}
