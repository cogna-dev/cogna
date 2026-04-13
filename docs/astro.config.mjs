// @ts-check

import mdx from "@astrojs/mdx"
import react from "@astrojs/react"
import tailwindcss from "@tailwindcss/vite"
import { defineConfig } from "astro/config"
import rehypeMermaid from "rehype-mermaid"

export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },
  markdown: {
    syntaxHighlight: {
      type: "shiki",
      excludeLangs: ["mermaid"],
    },
    shikiConfig: {
      themes: {
        light: "github-light",
        dark: "andromeeda",
      }
    },
    rehypePlugins: [rehypeMermaid],
  },
  integrations: [mdx(), react()],
})
