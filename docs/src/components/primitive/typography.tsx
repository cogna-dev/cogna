"use client"

import * as React from "react"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Terminal } from "@/components/primitive/code-block"

// ── Individual Components ───────────────────────────────────────

export function H1({
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h1
      className="scroll-m-20 text-2xl font-bold tracking-tight mb-6 mt-12 first:mt-0 font-title"
      {...props}
    >
      {children}
    </h1>
  )
}

export function H2({
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h2
      className="scroll-m-20 text-xl font-semibold tracking-tight mb-4 mt-10 first:mt-0 border-b pb-2 font-title"
      {...props}
    >
      {children}
    </h2>
  )
}

export function H3({
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className="scroll-m-20 text-lg font-semibold tracking-tight mb-3 mt-8 first:mt-0 font-title"
      {...props}
    >
      {children}
    </h3>
  )
}

export function H4({
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h4
      className="scroll-m-20 text-base font-semibold tracking-tight mb-2 mt-6 first:mt-0 font-title"
      {...props}
    >
      {children}
    </h4>
  )
}

export function H5({
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h5
      className="scroll-m-20 text-sm font-semibold tracking-tight mb-2 mt-6 first:mt-0 font-title"
      {...props}
    >
      {children}
    </h5>
  )
}

export function H6({
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h6
      className="scroll-m-20 text-xs font-semibold tracking-tight mb-2 mt-6 first:mt-0 font-title"
      {...props}
    >
      {children}
    </h6>
  )
}

export function P({
  children,
  ...props
}: React.HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p
      className="mb-5 leading-7 [&:not(:first-child)]:mt-0 font-body"
      {...props}
    >
      {children}
    </p>
  )
}

export function A({
  children,
  href,
  ...props
}: React.AnchorHTMLAttributes<HTMLAnchorElement>) {
  const isExternal = href?.startsWith("http")
  return (
    <a
      href={href}
      className="text-primary underline underline-offset-4 hover:text-primary/80 transition-colors font-medium"
      {...(isExternal ? { target: "_blank", rel: "noopener noreferrer" } : {})}
      {...props}
    >
      {children}
    </a>
  )
}

export function Blockquote({
  children,
  ...props
}: React.BlockquoteHTMLAttributes<HTMLQuoteElement>) {
  return (
    <blockquote
      className="border-l-4 border-border pl-6 italic my-6 text-muted-foreground [&>p]:mb-0 font-body"
      {...props}
    >
      {children}
    </blockquote>
  )
}

export function Ul({
  children,
  ...props
}: React.HTMLAttributes<HTMLUListElement>) {
  return (
    <ul className="list-disc pl-6 mb-5 space-y-2 font-body" {...props}>
      {children}
    </ul>
  )
}

export function Ol({
  children,
  ...props
}: React.HTMLAttributes<HTMLOListElement>) {
  return (
    <ol className="list-decimal pl-6 mb-5 space-y-2 font-body" {...props}>
      {children}
    </ol>
  )
}

export function Li({
  children,
  ...props
}: React.LiHTMLAttributes<HTMLLIElement>) {
  return (
    <li className="leading-7 font-body" {...props}>
      {children}
    </li>
  )
}

export function Pre({
  children,
  ...props
}: React.HTMLAttributes<HTMLPreElement>) {
  const ref = React.useRef<HTMLDivElement>(null)
  const getText = React.useCallback(() => ref.current?.textContent ?? "", [])

  return (
    <Terminal className="my-6" getText={getText}>
      <div ref={ref}>
        <pre className="overflow-x-auto shiki font-code" {...props}>
          {children}
        </pre>
      </div>
    </Terminal>
  )
}

export function Em({ children, ...props }: React.HTMLAttributes<HTMLElement>) {
  return (
    <em className="italic" {...props}>
      {children}
    </em>
  )
}

export function Strong({
  children,
  ...props
}: React.HTMLAttributes<HTMLElement>) {
  return (
    <strong className="font-semibold" {...props}>
      {children}
    </strong>
  )
}

export function Hr(props: React.HTMLAttributes<HTMLHRElement>) {
  return <hr className="my-10 border-border" {...props} />
}

export function Br(props: React.HTMLAttributes<HTMLBRElement>) {
  return <br {...props} />
}

export function Img(props: React.ImgHTMLAttributes<HTMLImageElement>) {
  return <img className="rounded-lg my-6" alt="" {...props} />
}

export function Del({
  children,
  ...props
}: React.DelHTMLAttributes<HTMLModElement>) {
  return (
    <del className="line-through text-muted-foreground" {...props}>
      {children}
    </del>
  )
}

export function MdxTable({ children }: { children?: React.ReactNode }) {
  return (
    <div className="my-6 w-full overflow-auto">
      <Table>{children}</Table>
    </div>
  )
}

export function Thead({ children }: { children?: React.ReactNode }) {
  return <TableHeader>{children}</TableHeader>
}

export function Tbody({ children }: { children?: React.ReactNode }) {
  return <TableBody>{children}</TableBody>
}

export function Tr({ children }: { children?: React.ReactNode }) {
  return <TableRow>{children}</TableRow>
}

export function Th({ children }: { children?: React.ReactNode }) {
  return <TableHead>{children}</TableHead>
}

export function Td({ children }: { children?: React.ReactNode }) {
  return <TableCell>{children}</TableCell>
}

// ── MDX Components Map ──────────────────────────────────────────

export const mdxComponents = {
  h1: H1,
  h2: H2,
  h3: H3,
  h4: H4,
  h5: H5,
  h6: H6,
  p: P,
  a: A,
  blockquote: Blockquote,
  ul: Ul,
  ol: Ol,
  li: Li,
  pre: Pre,
  em: Em,
  strong: Strong,
  hr: Hr,
  br: Br,
  img: Img,
  del: Del,
  table: MdxTable,
  thead: Thead,
  tbody: Tbody,
  tr: Tr,
  th: Th,
  td: Td,
}
