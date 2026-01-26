#!/usr/bin/env bun
/**
 * Safety Net CLI - Stdin/exit-code wrapper for Amp and Claude Code.
 *
 * Amp Delegate Protocol:
 *   - Exit 0 → allow the command
 *   - Exit 1 → ask the operator for approval
 *   - Exit ≥2 → reject (stderr is surfaced to the model)
 *
 * Claude Code Hook Protocol:
 *   - Exit 0 → allow
 *   - Exit non-zero → block (stderr shown to Claude)
 *
 * Input Detection:
 *   - Amp:        {"cmd": "...", "cwd": "..."}
 *   - Claude Code: {"tool_name": "Bash", "tool_input": {"command": "...", "cwd": "..."}}
 *
 * Environment Variables:
 *   SAFETY_NET_STRICT=1        - Fail-closed on unparseable commands
 *   SAFETY_NET_PARANOID=1      - Enable all paranoid checks
 *   SAFETY_NET_PARANOID_RM=1   - Block rm -rf even in cwd
 *   SAFETY_NET_PARANOID_INTERPRETERS=1 - Block python -c, node -e, etc.
 *   SAFETY_NET_ALLOW_TMP_RM=0  - Block rm -rf in /tmp, /var/tmp, $TMPDIR
 *   SAFETY_NET_ALLOW_CWD_RM=1  - Allow rm -rf within cwd
 */

import { analyze, formatBlockMessage, getOptionsFromEnv } from "./core"

interface AmpInput {
  cmd: string
  cwd?: string
}

interface ClaudeCodeInput {
  tool_name: string
  tool_input: {
    command: string
    cwd?: string
  }
}

type Input = AmpInput | ClaudeCodeInput

function isClaudeCodeInput(input: unknown): input is ClaudeCodeInput {
  return (
    typeof input === "object" &&
    input !== null &&
    "tool_name" in input &&
    "tool_input" in input &&
    typeof (input as ClaudeCodeInput).tool_input === "object"
  )
}

function isAmpInput(input: unknown): input is AmpInput {
  return typeof input === "object" && input !== null && "cmd" in input && typeof (input as AmpInput).cmd === "string"
}

function extractCommand(input: unknown): { command: string; cwd?: string } | null {
  if (isClaudeCodeInput(input)) {
    if (input.tool_name !== "Bash") {
      return null
    }
    return {
      command: input.tool_input.command,
      cwd: input.tool_input.cwd,
    }
  }

  if (isAmpInput(input)) {
    return {
      command: input.cmd,
      cwd: input.cwd,
    }
  }

  return null
}

async function main(): Promise<number> {
  const [mode, ...rest] = process.argv.slice(2)
  if (mode === "scan") {
    const { runScan } = await import("./scan-runner")
    return runScan(rest)
  }

  const toolName = process.env.AGENT_TOOL_NAME
  if (toolName && toolName !== "Bash") {
    return 0
  }

  const options = getOptionsFromEnv()

  let inputText: string
  try {
    inputText = await Bun.stdin.text()
  } catch {
    if (options.strict) {
      console.error("Safety Net: failed to read stdin")
      return 2
    }
    return 0
  }

  if (!inputText.trim()) {
    return 0
  }

  let input: unknown
  try {
    input = JSON.parse(inputText)
  } catch {
    if (options.strict) {
      console.error("Safety Net: invalid JSON input")
      return 2
    }
    return 0
  }

  const extracted = extractCommand(input)
  if (!extracted) {
    return 0
  }

  const { command, cwd } = extracted
  if (!command || !command.trim()) {
    return 0
  }

  const result = analyze(command, { ...options, cwd })

  if (result.blocked) {
    const message = formatBlockMessage(command, result.segment!, result.reason!, result.ruleId)
    console.error(message)
    return 2
  }

  return 0
}

process.exit(await main())
