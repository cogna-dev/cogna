import { execSync, spawnSync } from 'node:child_process'
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
} from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const packageRoot = resolve(__dirname, '..')
const repoRoot = resolve(packageRoot, '../../..')

function run(command, cwd) {
  execSync(command, {
    cwd,
    stdio: 'inherit',
    env: process.env,
  })
}

function commandExists(command) {
  const lookupCommand = process.platform === 'win32' ? 'where' : 'which'
  const result = spawnSync(lookupCommand, [command], {
    stdio: 'ignore',
    env: process.env,
  })
  return result.status === 0
}

function shouldSkipBufGenerate(errorMessage) {
  return errorMessage.includes(
    'symbol "xaclabs.cogna.v1.SourceLocation" already defined',
  )
}

function tryBufGenerate() {
  try {
    execSync('buf generate --template buf.gen.yaml', {
      cwd: repoRoot,
      stdio: 'pipe',
      env: process.env,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    const stdout =
      typeof error === 'object' && error && 'stdout' in error
        ? String(error.stdout ?? '')
        : ''
    const stderr =
      typeof error === 'object' && error && 'stderr' in error
        ? String(error.stderr ?? '')
        : ''
    const combined = `${message}\n${stdout}\n${stderr}`
    if (!shouldSkipBufGenerate(combined)) {
      throw error
    }
  }
}

const generatedMarker = resolve(packageRoot, 'src', 'generated', 'index.ts')
const bufAvailable = commandExists('buf')
if (bufAvailable) {
  tryBufGenerate()
} else if (!existsSync(generatedMarker)) {
  throw new Error(
    'buf is required to generate SDK bindings because src/generated artifacts are missing.',
  )
} else {
  console.warn('buf is not installed; using checked-in SDK generated bindings.')
}

const runtimeTarget = resolve(packageRoot, 'src/runtime/sdk.runtime.js')
const moonAvailable = commandExists('moon')
if (moonAvailable) {
  run('node ./scripts/export-sdk-runtime.mjs', repoRoot)
} else if (!existsSync(runtimeTarget)) {
  throw new Error(
    'moon is required to generate SDK runtime because src/runtime/sdk.runtime.js is missing.',
  )
} else {
  console.warn('moon is not installed; using checked-in SDK runtime artifact.')
}

const runtimeSource = resolve(repoRoot, 'dist', 'runtime', 'sdk.runtime.js')
if (moonAvailable && !existsSync(runtimeSource)) {
  throw new Error(`MoonBit JS runtime not found at ${runtimeSource}`)
}

if (existsSync(runtimeSource)) {
  mkdirSync(dirname(runtimeTarget), { recursive: true })
  copyFileSync(runtimeSource, runtimeTarget)
  const runtimeText = readFileSync(runtimeTarget, 'utf-8')
  const strippedRuntimeText = runtimeText.replace(
    /\/\/# sourceMappingURL=.*$/m,
    '',
  )
  if (runtimeText !== strippedRuntimeText) {
    writeFileSync(runtimeTarget, strippedRuntimeText)
  }
}

const runtimeMapSource = resolve(
  repoRoot,
  'dist',
  'runtime',
  'sdk.runtime.js.map',
)
const runtimeMapTarget = resolve(packageRoot, 'src/runtime/sdk.js.map')
if (existsSync(runtimeMapSource)) {
  copyFileSync(runtimeMapSource, runtimeMapTarget)
}
