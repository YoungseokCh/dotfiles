import { tool } from "@opencode-ai/plugin"
import { mkdtemp, readFile, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import path from "node:path"

const MODELS = ["codex", "gemini", "claude"] as const
type Model = (typeof MODELS)[number]

type ToolResult = {
  model: Model
  ok: boolean
  output?: string
  error?: string
}

type ProviderOutput = {
  output: string
  error?: string
}

type CommandSpec = {
  cmd: string[]
  outputFile?: string
}

export default tool({
  description: "Ask Codex, Gemini, or Claude and return their responses",
  args: {
    model: tool.schema
      .enum(["codex", "gemini", "claude"])
      .describe("Model to query: codex, gemini, or claude"),
    prompt: tool.schema.string().min(1).describe("Prompt to send to the selected model"),
  },
  async execute(args, context) {
    const result = await runModel(args.model, args.prompt, context.directory)
    return formatResults(args.model, args.prompt, result)
  },
})

async function runModel(
  model: Model,
  prompt: string,
  directory: string,
): Promise<ToolResult> {
  const tempDir = await mkdtemp(path.join(tmpdir(), "opencode-ai-tool-"))

  try {
    const spec = buildCommand(model, prompt, directory, tempDir)
    const proc = Bun.spawn(spec.cmd, {
      cwd: directory,
      stdout: "pipe",
      stderr: "pipe",
    })
    const timed = await waitForProcess(proc, 120_000)
    const stderr = (await new Response(timed.stderr).text()).trim()

    if (timed.exitCode !== 0) {
      return {
        model,
        ok: false,
        error: stderr || `${model} exited with code ${timed.exitCode}`,
      }
    }

    const response = await readProviderOutput(model, timed.stdout, spec.outputFile)
    if (response.error) {
      return {
        model,
        ok: false,
        error: response.error,
      }
    }

    if (!response.output) {
      return {
        model,
        ok: false,
        error: stderr || `${model} returned an empty response`,
      }
    }

    return { model, ok: true, output: response.output }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return { model, ok: false, error: message }
  } finally {
    await rm(tempDir, { recursive: true, force: true })
  }
}

function buildCommand(
  model: Model,
  prompt: string,
  directory: string,
  tempDir: string,
): CommandSpec {
  if (model === "codex") {
    const outputFile = path.join(tempDir, "codex-last-message.txt")
    return {
      cmd: [
        "codex",
        "exec",
        "--sandbox",
        "read-only",
        "--skip-git-repo-check",
        "--cd",
        directory,
        "--output-last-message",
        outputFile,
        prompt,
      ],
      outputFile,
    }
  }

  if (model === "gemini") {
    return {
      cmd: [
        "gemini",
        "--prompt",
        prompt,
        "--approval-mode",
        "plan",
        "--output-format",
        "json",
      ],
    }
  }

  return {
    cmd: [
      "claude",
      "-p",
      prompt,
      "--permission-mode",
      "plan",
      "--output-format",
      "json",
      "--tools",
      "",
    ],
  }
}

async function waitForProcess(
  proc: Bun.Subprocess<"pipe", "pipe", "inherit">,
  timeoutMs: number,
) {
  const timeout = new Promise<never>((_, reject) => {
    const timer = setTimeout(() => {
      proc.kill()
      reject(new Error(`Timed out after ${timeoutMs}ms`))
    }, timeoutMs)
    proc.exited.finally(() => clearTimeout(timer))
  })

  const exitCode = await Promise.race([proc.exited, timeout])
  return { exitCode, stdout: proc.stdout, stderr: proc.stderr }
}

async function readProviderOutput(
  model: Model,
  stdout: ReadableStream,
  outputFile?: string,
): Promise<ProviderOutput> {
  if (model === "codex") {
    if (!outputFile) return { output: "" }
    return { output: (await readFile(outputFile, "utf8")).trim() }
  }

  const raw = (await new Response(stdout).text()).trim()
  if (!raw) return { output: "" }

  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>

    if (parsed.is_error === true) {
      return { output: "", error: pickString(parsed.result) || `${model} returned an error` }
    }

    if (model === "gemini") {
      return { output: pickString(parsed.response) || raw }
    }

    return { output: pickString(parsed.result) || raw }
  } catch {
    return { output: raw }
  }
}

function pickString(value: unknown): string {
  return typeof value === "string" ? value.trim() : ""
}

function formatResults(model: Model, prompt: string, result: ToolResult): string {
  const lines = [`model: ${model}`, `prompt: ${prompt}`, ""]

  lines.push(`## ${result.model}`)
  if (result.ok) {
    lines.push(result.output || "")
  } else {
    lines.push(`ERROR: ${result.error || "Unknown error"}`)
  }

  return lines.join("\n").trim()
}
