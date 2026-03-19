"use client"

import type * as React from "react"
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarInset,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar"

export interface DocsSidebarItem {
  title: string
  href: string
}

export interface DocsSidebarGroup {
  title: string
  items: DocsSidebarItem[]
}

interface DocSidebarProps extends React.ComponentProps<typeof Sidebar> {
  config: DocsSidebarGroup[]
  currentPath: string
}

export function DocSidebar({ config, currentPath, ...props }: DocSidebarProps) {
  return (
    <Sidebar
      collapsible="offcanvas"
      variant="sidebar"
      side="left"
      className="sticky top-0 h-screen overflow-y-auto border-r"
      {...props}
    >
      <SidebarContent className="p-4">
        {config.map((group) => (
          <SidebarGroup key={group.title}>
            <SidebarGroupLabel>{group.title}</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {group.items.map((item) => (
                  <SidebarMenuItem key={item.title}>
                    <SidebarMenuButton
                      asChild
                      isActive={item.href === currentPath}
                    >
                      <a href={item.href}>{item.title}</a>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        ))}
      </SidebarContent>
    </Sidebar>
  )
}

interface DocSidebarLayoutProps {
  children: React.ReactNode
  config: DocsSidebarGroup[]
  currentPath: string
}

export function DocSidebarLayout({
  children,
  config,
  currentPath,
}: DocSidebarLayoutProps) {
  return (
    <SidebarProvider>
      <DocSidebar config={config} currentPath={currentPath} />
      <SidebarInset>
        <header className="flex h-14 shrink-0 items-center gap-2 border-b px-4 transition-[width,height] ease-linear group-has-[[data-collapsible=icon]]/sidebar-wrapper:h-12 md:hidden">
          <SidebarTrigger />
        </header>
        <div className="flex flex-1 flex-col gap-4 p-4 pt-0">{children}</div>
      </SidebarInset>
    </SidebarProvider>
  )
}
