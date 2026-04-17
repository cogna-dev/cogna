import * as fs from "node:fs/promises"
import * as os from "node:os"
import * as path from "node:path"
import { spawn } from "node:child_process"

import { downloadAndUnzipVSCode, resolveCliArgsFromVSCodeExecutablePath, runTests } from "@vscode/test-electron"

function run(command: string, args: string[], cwd: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      env: process.env,
      stdio: "inherit",
    })
    child.on("error", reject)
    child.on("close", (code) => {
      if (code === 0) {
        resolve()
      } else {
        reject(new Error(`${command} ${args.join(" ")} failed with exit code ${code ?? 1}`))
      }
    })
  })
}

async function writeWorkspaceConfig(workspaceDir: string) {
  const content = `schemaVersion: ciq-config/v2
profile: openapi-spec
purl: pkg:openapi/acme/payment-api@2026.03.01
source:
  repo: https://github.com/acme/payment-api
  ref: main
inputs:
  include:
    - openapi/**/*.yaml
checks:
  format: sarif
  policy: ./dist/policy.ciq.tgz
diff:
  includeTestChanges: false
sbom:
  format: spdx
  dependencyBundles: true
  requireLocalPackages: true
publish:
  includeDependencies: true
registry:
  port: 8787
  storeDir: .cogna/cache/registry
mcp:
  port: 3000
`
  await fs.writeFile(path.join(workspaceDir, "cogna.yml"), content, "utf8")
}

async function prepareWorkspace(repoRoot: string): Promise<{ workspaceDir: string; cliPath: string }> {
  const workspaceDir = await fs.mkdtemp(path.join(os.tmpdir(), "cogna-vscode-workspace-"))
  const openapiDir = path.join(workspaceDir, "openapi")
  const distDir = path.join(workspaceDir, "dist")
  await fs.mkdir(openapiDir, { recursive: true })
  await fs.mkdir(distDir, { recursive: true })
  await fs.copyFile(
    path.join(repoRoot, "examples/openapi-spec/full/repo/openapi/payment.yaml"),
    path.join(openapiDir, "payment.yaml"),
  )
  await writeWorkspaceConfig(workspaceDir)
  await fs.writeFile(path.join(distDir, "policy.ciq.tgz"), "policy placeholder", "utf8")
  await fs.writeFile(
    path.join(distDir, "check.sarif.json"),
    JSON.stringify(
      {
        version: "2.1.0",
        runs: [
          {
            tool: {
              driver: {
                rules: [
                  {
                    id: "compat.core.removed-declaration",
                    helpUri: "https://cogna.xaclabs.dev/docs/policies/generated/core/removed-declaration",
                  },
                ],
              },
            },
            results: [
              {
                ruleId: "compat.core.removed-declaration",
                level: "error",
                message: {
                  text: "Public API removal blocked by policy",
                },
                locations: [
                  {
                    physicalLocation: {
                      artifactLocation: { uri: "openapi/payment.yaml" },
                      region: { startLine: 1, endLine: 1 },
                    },
                  },
                ],
              },
            ],
          },
        ],
      },
      null,
      2,
    ),
    "utf8",
  )

  const installDir = path.join(workspaceDir, ".cogna-bin")
  await fs.mkdir(installDir, { recursive: true })
  if (process.platform === "win32") {
    await run("pwsh", ["-File", "integrations/cli/install.ps1", "-InstallDir", installDir, "-BinaryName", "cogna"], repoRoot)
  } else {
    await run("bash", ["integrations/cli/install.sh", installDir, "cogna"], repoRoot)
  }
  const mainPath = path.join(installDir, process.platform === "win32" ? "main.exe" : "main")
  const cognaPath = path.join(installDir, process.platform === "win32" ? "cogna.exe" : "cogna")
  await fs.access(mainPath)
  await fs.access(cognaPath)

  await run(cognaPath, ["build"], workspaceDir)
  const baseDir = path.join(distDir, "base")
  const targetDir = path.join(distDir, "target")
  await fs.mkdir(baseDir, { recursive: true })
  await fs.mkdir(targetDir, { recursive: true })
  await fs.copyFile(path.join(distDir, "manifest.json"), path.join(baseDir, "manifest.json"))
  await fs.copyFile(path.join(distDir, "declarations.ndjson"), path.join(baseDir, "declarations.ndjson"))
  await fs.copyFile(path.join(distDir, "symbols.ndjson"), path.join(baseDir, "symbols.ndjson"))
  await fs.copyFile(path.join(distDir, "declarations.ndjson"), path.join(targetDir, "declarations.ndjson"))
  await fs.copyFile(path.join(distDir, "symbols.ndjson"), path.join(targetDir, "symbols.ndjson"))

  const manifestText = await fs.readFile(path.join(distDir, "manifest.json"), "utf8")
  const manifest = JSON.parse(manifestText) as { purl: string }
  manifest.purl = "pkg:openapi/acme/payment-api@2026.04.01"
  await fs.writeFile(path.join(targetDir, "manifest.json"), JSON.stringify(manifest, null, 2), "utf8")

  return { workspaceDir, cliPath: cognaPath }
}

async function main() {
  const extensionDevelopmentPath = path.resolve(process.cwd())
  const extensionTestsPath = path.resolve(process.cwd(), "out", "test", "suite", "index.js")
  const repoRoot = path.resolve(process.cwd(), "..", "..")
  const { workspaceDir, cliPath } = await prepareWorkspace(repoRoot)

  process.env.COGNA_TEST_WORKSPACE = workspaceDir
  process.env.COGNA_TEST_CLI = cliPath
  process.env.COGNA_TEST_DISABLE_EXTERNAL_OPEN = "true"
  process.env.COGNA_OPA_EVAL_JSON = JSON.stringify({
    result: [
      {
        expressions: [
          {
            value: [
              {
                rule_id: "compat.core.removed-declaration",
                level: "error",
                message: "Public API removal blocked by policy",
                path: "openapi/payment.yaml",
                docs: "https://cogna.xaclabs.dev/docs/policies/generated/core/removed-declaration",
              },
            ],
          },
        ],
      },
    ],
  })

  const vscodeExecutablePath = await downloadAndUnzipVSCode("stable")
  const launchArgs = [...resolveCliArgsFromVSCodeExecutablePath(vscodeExecutablePath), workspaceDir]
  await runTests({
    vscodeExecutablePath,
    extensionDevelopmentPath,
    extensionTestsPath,
    launchArgs,
    extensionTestsEnv: {
      ...process.env,
    },
  })
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
