import type * as React from "react"
import { DocBreadcrumb } from "@/components/doc/doc-breadcrumb"
import { DocPagination } from "@/components/doc/doc-pagination"
import {
  DocSidebarLayout,
  type DocsSidebarGroup,
} from "@/components/doc/doc-sidebar"
import { DocToc, type DocTocHeading } from "@/components/doc/doc-toc"
import type { FooterProps } from "@/components/primitive/footer"
import { Footer } from "@/components/primitive/footer"
import type { HeaderProps } from "@/components/primitive/header"
import { Header } from "@/components/primitive/header"

interface DocsLayoutProps {
  children: React.ReactNode
  title: string
  description?: string
  headings?: DocTocHeading[]
  header?: HeaderProps
  footer?: FooterProps
  sidebar: DocsSidebarGroup[]
  currentPath: string
}

export function DocsLayout({
  children,
  title,
  description,
  headings = [],
  sidebar,
  currentPath,
  header,
  footer,
}: DocsLayoutProps) {
  return (
    <>
      {header?.header && <Header header={header.header} />}
      <DocSidebarLayout config={sidebar} currentPath={currentPath}>
        <div className="flex flex-1 w-full gap-6">
          <div className="flex-1 min-w-0 mx-auto max-w-5xl px-6 md:px-8 pb-20 pt-6">
            <DocBreadcrumb currentPath={currentPath} />
            <div className="mt-6">
              <h1 className="scroll-m-20 text-4xl font-extrabold tracking-tight lg:text-5xl mb-8 font-title">
                {title}
              </h1>
              {description && (
                <p className="text-xl text-muted-foreground mb-8 font-body">
                  {description}
                </p>
              )}
              {children}
            </div>
            <DocPagination currentPath={currentPath} config={sidebar} />
          </div>
          <aside className="hidden xl:block w-56 shrink-0 pt-6 pr-6">
            <DocToc headings={headings} />
          </aside>
        </div>
      </DocSidebarLayout>
      {footer?.footer && (
        <Footer footer={footer.footer} socials={footer.socials} />
      )}
    </>
  )
}
