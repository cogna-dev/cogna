import { mkdir, writeFile } from 'node:fs/promises'
import { resolve } from 'node:path'

const cjsDir = resolve(new URL('../dist/cjs/', import.meta.url).pathname)

await mkdir(cjsDir, { recursive: true })
await writeFile(resolve(cjsDir, 'package.json'), '{\n  "type": "commonjs"\n}\n', 'utf-8')
