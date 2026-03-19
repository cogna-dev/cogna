import { defineCollection, z } from "astro:content"
import { glob } from "astro/loaders"

const docs = defineCollection({
  loader: glob({ pattern: "docs/**/*.{md,mdx}", base: "./src/content" }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    order: z.number().default(999),
  }),
})

const articles = defineCollection({
  loader: glob({ pattern: "articles/**/*.{md,mdx}", base: "./src/content" }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    cover: z.string().optional(),
    draft: z.boolean().default(false),
    author: z
      .object({
        name: z.string(),
        avatar: z.string().optional(),
        bio: z.string().optional(),
      })
      .default({ name: "XaC Labs Team" }),
    tags: z.array(z.string()).default([]),
  }),
})

export const collections = { docs, articles }
