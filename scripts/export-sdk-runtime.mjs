import { copyFileSync, existsSync, mkdirSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { execSync } from 'node:child_process'

const repoRoot = resolve(dirname(new URL(import.meta.url).pathname), '..')

function run(command, cwd) {
  execSync(command, {
    cwd,
    stdio: 'inherit',
    env: process.env,
  })
}

run('moon build --target js src/sdk', repoRoot)

const runtimeSource = resolve(
  repoRoot,
  '_build',
  'js',
  'debug',
  'build',
  'sdk',
  'sdk.js',
)
if (!existsSync(runtimeSource)) {
  throw new Error(`MoonBit JS runtime not found at ${runtimeSource}`)
}

const runtimeTarget = resolve(repoRoot, 'dist/runtime/sdk.runtime.js')
mkdirSync(dirname(runtimeTarget), { recursive: true })
copyFileSync(runtimeSource, runtimeTarget)

const runtimeMapSource = resolve(
  repoRoot,
  '_build',
  'js',
  'debug',
  'build',
  'sdk',
  'sdk.js.map',
)
const runtimeMapTarget = resolve(repoRoot, 'dist/runtime/sdk.runtime.js.map')
if (existsSync(runtimeMapSource)) {
  copyFileSync(runtimeMapSource, runtimeMapTarget)
}
