import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { execFileSync } from 'node:child_process'

const __dirname = dirname(fileURLToPath(import.meta.url))
const packageRoot = resolve(__dirname, '..')
const repoRoot = resolve(packageRoot, '../../..')
const distDir = resolve(packageRoot, 'dist')
const sourceDir = resolve(packageRoot, 'src')
const moonbitDistDir = resolve(distDir, 'moonbit')
const tscBin = resolve(packageRoot, 'node_modules/.bin/tsc')
const buildRoot = resolve(repoRoot, '_build/js/release/build')

const run = (cmd, args, cwd) => {
  execFileSync(cmd, args, { cwd, stdio: 'inherit' })
}

const stageMoonBitModule = (relativeSource, targetName) => {
  const source = resolve(buildRoot, relativeSource)
  if (!existsSync(source)) {
    throw new Error(`expected MoonBit JS output not found: ${relativeSource}`)
  }
  const target = resolve(moonbitDistDir, targetName)
  let text = readFileSync(source, 'utf8')
  if (text.includes('require(')) {
    text = [
      "import { createRequire as __moonbitCreateRequire } from 'node:module'",
      'const require = __moonbitCreateRequire(import.meta.url)',
      '',
      text,
    ].join('\n')
  }
  writeFileSync(target, text)
}

const stageWrapperFile = name => {
  const source = resolve(sourceDir, name)
  if (!existsSync(source)) {
    throw new Error(`expected wrapper source not found: ${name}`)
  }
  cpSync(source, resolve(distDir, name))
}

const buildGeneratedModules = () => {
  const generatedIndex = resolve(sourceDir, 'generated', 'index.ts')
  if (!existsSync(generatedIndex)) {
    throw new Error('expected generated TypeScript entry not found: src/generated/index.ts')
  }
  if (!existsSync(tscBin)) {
    throw new Error('expected TypeScript compiler not found: node_modules/.bin/tsc')
  }
  run(tscBin, ['-p', 'tsconfig.generated.json'], packageRoot)
}

rmSync(distDir, { recursive: true, force: true })
mkdirSync(distDir, { recursive: true })
mkdirSync(moonbitDistDir, { recursive: true })

run('moon', ['build', 'src/sdk/contracts', 'src/sdk/query', 'src/sdk/index', '--target', 'js', '--release'], repoRoot)

stageMoonBitModule('sdk/contracts/contracts.js', 'contracts.js')
stageMoonBitModule('sdk/query/query.js', 'query.js')
stageMoonBitModule('sdk/index/index.js', 'index.js')
buildGeneratedModules()

for (const file of [
  'shared.js',
  'contracts.js',
  'index-api.js',
  'query.js',
  'index.js',
  'types.d.ts',
  'contracts.d.ts',
  'index-api.d.ts',
  'query.d.ts',
  'index.d.ts',
]) {
  stageWrapperFile(file)
}
