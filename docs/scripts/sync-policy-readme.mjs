import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const docsRoot = resolve(__dirname, '..')
const repoRoot = resolve(docsRoot, '..')
const readmePath = resolve(repoRoot, 'policies/README.md')
const outputPath = resolve(docsRoot, 'src/content/docs/policies.mdx')

const frontmatter = `---
title: 内置策略规则
description: Cogna 内置 compatibility policy 的规则目录与 canonical helpUri 入口。
order: 25
---

`

const body = readFileSync(readmePath, 'utf-8').trimEnd()
mkdirSync(dirname(outputPath), { recursive: true })
writeFileSync(outputPath, `${frontmatter}${body}\n`, 'utf-8')
