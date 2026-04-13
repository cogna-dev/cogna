import { spawn } from "node:child_process"
import * as fs from "node:fs/promises"
import * as path from "node:path"

export interface WorkspaceFolderLike {
  uri: {
    fsPath: string
  }
}

export interface CommandResult {
  command: string
  args: string[]
  cwd: string
  exitCode: number
  stdout: string
  stderr: string
}

export interface AnalysisResult {
  steps: CommandResult[]
  sarifPath: string
}

export class CodeIQCommandError extends Error {
  readonly result: CommandResult
  readonly completedSteps: CommandResult[]

  constructor(message: string, result: CommandResult, completedSteps: CommandResult[]) {
    super(message)
    this.name = "CodeIQCommandError"
    this.result = result
    this.completedSteps = completedSteps
  }
}

export function workspaceRoot(
  workspaceFolders: readonly WorkspaceFolderLike[] | undefined,
): string | undefined {
  return workspaceFolders?.[0]?.uri.fsPath
}

export function resolveWorkingDirectory(
  workspaceFolders: readonly WorkspaceFolderLike[] | undefined,
  configured: string | undefined,
): string | undefined {
  const root = workspaceRoot(workspaceFolders)
  const trimmed = configured?.trim()
  if (!trimmed) {
    return root
  }
  if (path.isAbsolute(trimmed)) {
    return trimmed
  }
  return path.resolve(root ?? process.cwd(), trimmed)
}

export function resolveCliPath(configured: string | undefined, workspaceDir?: string): string {
  const trimmed = configured?.trim()
  if (!trimmed) {
    return "codeiq"
  }
  if (path.isAbsolute(trimmed)) {
    return trimmed
  }
  if (!trimmed.includes(path.sep) && !trimmed.includes("/")) {
    return trimmed
  }
  return path.resolve(workspaceDir ?? process.cwd(), trimmed)
}

export function resolveSarifPath(workingDirectory: string, configured = "dist/check.sarif.json"): string {
  if (path.isAbsolute(configured)) {
    return configured
  }
  return path.resolve(workingDirectory, configured)
}

export async function fileExists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

export async function readTextFile(filePath: string): Promise<string> {
  return fs.readFile(filePath, "utf8")
}

export async function runCommand(
  cliPath: string,
  workingDirectory: string,
  subcommand: string,
  args: string[] = [],
  env: NodeJS.ProcessEnv = process.env,
): Promise<CommandResult> {
  return new Promise<CommandResult>((resolve, reject) => {
    const child = spawn(cliPath, [subcommand, ...args], {
      cwd: workingDirectory,
      env,
      stdio: ["ignore", "pipe", "pipe"],
    })
    let stdout = ""
    let stderr = ""

    child.stdout.on("data", (chunk: Buffer | string) => {
      stdout += chunk.toString()
    })
    child.stderr.on("data", (chunk: Buffer | string) => {
      stderr += chunk.toString()
    })
    child.on("error", (error) => {
      reject(error)
    })
    child.on("close", (code) => {
      resolve({
        command: cliPath,
        args: [subcommand, ...args],
        cwd: workingDirectory,
        exitCode: code ?? 1,
        stdout,
        stderr,
      })
    })
  })
}

export async function runAnalysis(
  cliPath: string,
  workingDirectory: string,
  env: NodeJS.ProcessEnv = process.env,
): Promise<AnalysisResult> {
  const steps: CommandResult[] = []
  for (const subcommand of ["build", "diff", "check"]) {
    const result = await runCommand(cliPath, workingDirectory, subcommand, [], env)
    steps.push(result)
    if (result.exitCode !== 0) {
      throw new CodeIQCommandError(
        `codeiq ${subcommand} failed with exit code ${result.exitCode}`,
        result,
        steps,
      )
    }
  }
  return {
    steps,
    sarifPath: resolveSarifPath(workingDirectory),
  }
}
