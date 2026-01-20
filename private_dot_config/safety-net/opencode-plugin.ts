/**
 * Safety Net - OpenCode Plugin
 *
 * Blocks destructive commands (rm -rf, dangerous git operations, etc.)
 *
 * Environment Variables:
 *   SAFETY_NET_STRICT=1        - Fail-closed on unparseable commands
 *   SAFETY_NET_PARANOID=1      - Enable all paranoid checks
 *   SAFETY_NET_PARANOID_RM=1   - Block rm -rf even in cwd
 *   SAFETY_NET_PARANOID_INTERPRETERS=1 - Block python -c, node -e, etc.
 *   SAFETY_NET_ALLOW_TMP_RM=0  - Block rm -rf in /tmp, /var/tmp, $TMPDIR
 */

import { analyze, formatBlockMessage } from "./core"

interface PluginContext {
  directory: string
}

interface ToolExecuteBeforeInput {
  tool: string
  sessionID: string
}

interface ToolExecuteBeforeOutput {
  args?: {
    command?: string
    cwd?: string
  }
}

export const SafetyNet = async (ctx: PluginContext) => {
  return {
    "tool.execute.before": async (input: ToolExecuteBeforeInput, output: ToolExecuteBeforeOutput) => {
      if (input.tool !== "bash") {
        return
      }

      const command = output?.args?.command ?? ""
      if (!command.trim()) {
        return
      }

      const cwd = output?.args?.cwd ?? ctx.directory

      const result = analyze(command, { cwd })

      if (result.blocked) {
        throw new Error(formatBlockMessage(command, result.segment!, result.reason!))
      }
    },
  }
}
