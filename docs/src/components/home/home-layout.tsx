import type * as React from "react"
import {
  Footer,
  type FooterProps,
} from "@/components/primitive/footer"
import {
  Header,
  type HeaderProps,
} from "@/components/primitive/header"

interface HomeLayoutProps {
  children: React.ReactNode
  header: HeaderProps["header"]
  footer: FooterProps["footer"]
  socials?: FooterProps["socials"]
}

export function HomeLayout({
  children,
  header,
  footer,
  socials,
}: HomeLayoutProps) {
  return (
    <>
      <Header header={header} />
      <main>{children}</main>
      <Footer footer={footer} socials={socials} />
    </>
  )
}
