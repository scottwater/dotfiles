/**
 * Safety Net Core - Cross-platform command analysis for blocking destructive operations.
 *
 * Supports: Amp, Claude Code, OpenCode
 */

import { extractHeredocBodies, extractHereStrings, extractStringLiterals, ScriptLanguage } from "./ast"

const MAX_RECURSION_DEPTH = 5

const STRICT_SUFFIX = " [strict mode - disable with: unset SAFETY_NET_STRICT]"
const PARANOID_INTERPRETERS_SUFFIX =
  " [paranoid mode - disable with: unset SAFETY_NET_PARANOID SAFETY_NET_PARANOID_INTERPRETERS]"

const REASON_FIND_DELETE = "find -delete permanently deletes matched files. Use -print first."
const REASON_XARGS_RM_RF = "xargs can feed arbitrary input to rm -rf. List files first, then delete individually."
const REASON_PARALLEL_RM_RF =
  "parallel can feed arbitrary input to rm -rf. List files first, then delete individually."
const REASON_INTERPRETER_ONE_LINER =
  "Interpreter one-liners can hide destructive commands. Write the code to a file instead."

const REASON_RM_RF = "rm -rf is destructive. Use `trash` instead, or list files first, then delete individually."
const REASON_RM_RF_ROOT_HOME = "rm -rf on root or home paths is extremely dangerous."
const REASON_RM_RF_TMP =
  "rm -rf in temp directories blocked. [allow_tmp disabled - enable with: unset SAFETY_NET_ALLOW_TMP_RM]"
const PARANOID_RM_SUFFIX = " [disable with: SAFETY_NET_PARANOID_RM=0]"
const REASON_INLINE_SCRIPT = "Inline scripts can hide destructive commands. Write the code to a file instead."

const REASON_GIT_CHECKOUT_DOUBLE_DASH =
  "git checkout -- discards uncommitted changes permanently. Use 'git stash' first."
const REASON_GIT_CHECKOUT_REF_DOUBLE_DASH =
  "git checkout <ref> -- <path> overwrites working tree. Use 'git stash' first."
const REASON_GIT_CHECKOUT_REF_PATHSPEC =
  "git checkout <ref> <path> overwrites working tree. Use 'git stash' first."
const REASON_GIT_CHECKOUT_PATHSPEC_FROM_FILE =
  "git checkout --pathspec-from-file overwrites working tree. Use 'git stash' first."
const REASON_GIT_RESTORE = "git restore discards uncommitted changes. Use 'git stash' or 'git diff' first."
const REASON_GIT_RESTORE_WORKTREE = "git restore --worktree discards uncommitted changes permanently."
const REASON_GIT_RESET_HARD = "git reset --hard destroys uncommitted changes. Use 'git stash' first."
const REASON_GIT_RESET_MERGE = "git reset --merge can lose uncommitted changes."
const REASON_GIT_CLEAN_FORCE = "git clean -f removes untracked files permanently. Review with 'git clean -n' first."
const REASON_GIT_PUSH_FORCE = "Force push can destroy remote history. Use --force-with-lease if necessary."
const REASON_GIT_WORKTREE_REMOVE_FORCE =
  "git worktree remove --force can delete worktree files. Verify the path first."
const REASON_GIT_BRANCH_DELETE_FORCE = "git branch -D force-deletes without merge check. Use -d for safety."
const REASON_GIT_STASH_DROP =
  "git stash drop permanently deletes stashed changes. List stashes first with 'git stash list'."
const REASON_GIT_STASH_CLEAR = "git stash clear permanently deletes ALL stashed changes."

type Severity = "ERROR" | "WARNING"

interface BlockReason {
  reason: string
  ruleId: string
  severity: Severity
}

const DANGEROUS_PATTERNS: Array<{ pattern: RegExp; ruleId: string; severity: Severity }> = [
  { pattern: /\brm\s+.*-[^\s]*r[^\s]*f/, ruleId: "core.pattern.rm-rf", severity: "ERROR" },
  { pattern: /\brm\s+.*-[^\s]*f[^\s]*r/, ruleId: "core.pattern.rm-rf", severity: "ERROR" },
  { pattern: />\s*\/dev\/[sh]d[a-z]/, ruleId: "core.pattern.dev-disk", severity: "ERROR" },
  { pattern: /\bdd\b.*\bof=/, ruleId: "core.pattern.dd-of", severity: "ERROR" },
  { pattern: /\bmkfs\b/, ruleId: "core.pattern.mkfs", severity: "ERROR" },
  { pattern: /\bshred\b/, ruleId: "core.pattern.shred", severity: "ERROR" },
]

const FIND_CONSUMES_ONE = new Set([
  "-name",
  "-iname",
  "-path",
  "-ipath",
  "-wholename",
  "-iwholename",
  "-regex",
  "-iregex",
  "-lname",
  "-ilname",
  "-samefile",
  "-newer",
  "-newerxy",
  "-perm",
  "-user",
  "-group",
  "-printf",
  "-fprintf",
  "-fprint",
  "-fprint0",
  "-fls",
])

const FIND_EXEC_LIKE = new Set(["-exec", "-execdir", "-ok", "-okdir"])

const SHELLS = new Set(["sh", "bash", "zsh", "fish", "dash", "ksh", "tcsh", "csh"])

const INTERPRETERS = new Set(["python", "python3", "node", "ruby", "perl"])

const INLINE_TRIGGER = /\b(rm|git|find|dd|mkfs|shred)\b/i

const INLINE_LIMIT_BYTES = 1024 * 1024
const INLINE_LIMIT_LINES = 10000
const INLINE_LIMIT_PAYLOADS = 10

const XARGS_CONSUMES_VALUE = new Set([
  "-a",
  "-I",
  "-J",
  "-L",
  "-l",
  "-n",
  "-R",
  "-S",
  "-s",
  "-P",
  "-d",
  "-E",
  "--arg-file",
  "--delimiter",
  "--eof",
  "--max-args",
  "--max-lines",
  "--max-procs",
  "--max-chars",
  "--process-slot-var",
])

const PARALLEL_CONSUMES_VALUE = new Set([
  "-j",
  "--jobs",
  "-S",
  "--sshlogin",
  "--sshloginfile",
  "-a",
  "--arg-file",
  "--arg-sep",
  "--col-sep",
  "-I",
  "--replace",
  "-U",
  "--delay",
  "--retries",
  "--timeout",
  "--progress-char",
  "-n",
  "--max-args",
  "-N",
  "--max-replace-args",
  "-L",
  "--max-lines",
  "-E",
  "--eof",
  "-s",
  "--max-chars",
])

const GIT_OPTS_WITH_VALUE = new Set([
  "-c",
  "-C",
  "--exec-path",
  "--git-dir",
  "--namespace",
  "--super-prefix",
  "--work-tree",
])

const GIT_OPTS_NO_VALUE = new Set([
  "-p",
  "-P",
  "-h",
  "--help",
  "--no-pager",
  "--paginate",
  "--version",
  "--bare",
  "--no-replace-objects",
  "--literal-pathspecs",
  "--noglob-pathspecs",
  "--icase-pathspecs",
])

const CHECKOUT_OPTS_WITH_VALUE = new Set([
  "-b",
  "-B",
  "--orphan",
  "--conflict",
  "-U",
  "--unified",
  "--inter-hunk-context",
  "--pathspec-from-file",
])

const CHECKOUT_OPTS_NO_VALUE = new Set([
  "-f",
  "--force",
  "-m",
  "--merge",
  "-q",
  "--quiet",
  "--detach",
  "--ignore-skip-worktree-bits",
  "--overwrite-ignore",
  "--no-overlay",
  "--overlay",
  "--progress",
  "--no-progress",
  "--guess",
  "--no-guess",
  "--pathspec-file-nul",
])

export interface AnalysisResult {
  blocked: boolean
  segment?: string
  reason?: string
  ruleId?: string
  severity?: Severity
}

export interface AnalysisOptions {
  cwd?: string
  strict?: boolean
  paranoidRm?: boolean
  paranoidInterpreters?: boolean
  allowTmp?: boolean
  allowCwdRm?: boolean
}

// Shell parsing utilities

function splitShellCommands(command: string): string[] {
  const parts: string[] = []
  const buf: string[] = []
  let inSingle = false
  let inDouble = false
  let escape = false

  let i = 0
  while (i < command.length) {
    const ch = command[i]

    if (escape) {
      buf.push(ch)
      escape = false
      i++
      continue
    }

    if (ch === "\\" && !inSingle) {
      buf.push(ch)
      escape = true
      i++
      continue
    }

    if (ch === "'" && !inDouble) {
      inSingle = !inSingle
      buf.push(ch)
      i++
      continue
    }

    if (ch === '"' && !inSingle) {
      inDouble = !inDouble
      buf.push(ch)
      i++
      continue
    }

    if (!inSingle && !inDouble) {
      if (command.slice(i, i + 2) === "&&" || command.slice(i, i + 2) === "||") {
        const part = buf.join("").trim()
        if (part) parts.push(part)
        buf.length = 0
        i += 2
        continue
      }

      if (command.slice(i, i + 2) === "|&") {
        const part = buf.join("").trim()
        if (part) parts.push(part)
        buf.length = 0
        i += 2
        continue
      }

      if (ch === "|") {
        const part = buf.join("").trim()
        if (part) parts.push(part)
        buf.length = 0
        i++
        continue
      }

      if (ch === "&") {
        const prev = i > 0 ? command[i - 1] : ""
        const nxt = i + 1 < command.length ? command[i + 1] : ""
        if (prev === ">" || prev === "<" || nxt === ">") {
          buf.push(ch)
          i++
          continue
        }

        const part = buf.join("").trim()
        if (part) parts.push(part)
        buf.length = 0
        i++
        continue
      }

      if (ch === ";" || ch === "\n") {
        const part = buf.join("").trim()
        if (part) parts.push(part)
        buf.length = 0
        i++
        continue
      }
    }

    buf.push(ch)
    i++
  }

  const part = buf.join("").trim()
  if (part) parts.push(part)
  return parts
}

function shlexSplit(segment: string): string[] | null {
  const tokens: string[] = []
  let current = ""
  let inSingle = false
  let inDouble = false
  let escape = false

  for (let i = 0; i < segment.length; i++) {
    const ch = segment[i]

    if (escape) {
      current += ch
      escape = false
      continue
    }

    if (ch === "\\" && !inSingle) {
      escape = true
      continue
    }

    if (ch === "'" && !inDouble) {
      inSingle = !inSingle
      continue
    }

    if (ch === '"' && !inSingle) {
      inDouble = !inDouble
      continue
    }

    if (!inSingle && !inDouble && /\s/.test(ch)) {
      if (current) {
        tokens.push(current)
        current = ""
      }
      continue
    }

    current += ch
  }

  if (inSingle || inDouble) {
    return null
  }

  if (current) {
    tokens.push(current)
  }

  return tokens
}

function shortOpts(tokens: string[]): Set<string> {
  const opts = new Set<string>()
  for (const tok of tokens) {
    if (tok.startsWith("--") || !tok.startsWith("-") || tok === "-") continue
    for (const c of tok.slice(1)) {
      opts.add(c)
    }
  }
  return opts
}

function stripEnvAssignments(tokens: string[]): string[] {
  let i = 0
  while (i < tokens.length) {
    const tok = tokens[i]
    if (!tok.includes("=")) break

    const [key] = tok.split("=", 2)
    if (!key || !/^[a-zA-Z_]/.test(key)) break
    if (!key.slice(1).split("").every((c) => /[a-zA-Z0-9_]/.test(c))) break

    i++
  }
  return tokens.slice(i)
}

function stripWrappers(tokens: string[]): string[] {
  let previous: string[] | null = null
  let depth = 0

  while (tokens.length > 0 && depth < 20) {
    if (previous && tokens.join("\0") === previous.join("\0")) break
    previous = [...tokens]
    depth++

    tokens = stripEnvAssignments(tokens)
    if (tokens.length === 0) return tokens

    const head = tokens[0].toLowerCase()

    if (head === "sudo") {
      let i = 1
      while (i < tokens.length && tokens[i].startsWith("-") && tokens[i] !== "--") {
        i++
      }
      if (i < tokens.length && tokens[i] === "--") i++
      tokens = tokens.slice(i)
      continue
    }

    if (head === "env") {
      let i = 1
      while (i < tokens.length) {
        const tok = tokens[i]
        if (tok === "--") {
          i++
          break
        }
        if (["-u", "--unset", "-C", "-P", "-S"].includes(tok)) {
          i += 2
          continue
        }
        if (tok.startsWith("--unset=")) {
          i++
          continue
        }
        if (
          (tok.startsWith("-u") || tok.startsWith("-C") || tok.startsWith("-P") || tok.startsWith("-S")) &&
          tok.length > 2
        ) {
          i++
          continue
        }
        if (tok.startsWith("-") && tok !== "-") {
          i++
          continue
        }
        break
      }
      tokens = tokens.slice(i)
      continue
    }

    if (head === "command") {
      let i = 1
      while (i < tokens.length) {
        const tok = tokens[i]
        if (tok === "--") {
          i++
          break
        }
        if (["-p", "-v", "-V"].includes(tok)) {
          i++
          continue
        }
        if (tok.startsWith("-") && tok !== "-" && !tok.startsWith("--")) {
          const chars = tok.slice(1)
          if (chars && chars.split("").every((c) => ["p", "v", "V"].includes(c))) {
            i++
            continue
          }
        }
        break
      }
      tokens = tokens.slice(i)
      continue
    }

    break
  }

  return stripEnvAssignments(tokens)
}

function stripTokenWrappers(token: string): string {
  let tok = token.trim()
  while (tok.startsWith("$(")) {
    tok = tok.slice(2)
  }
  tok = tok.replace(/^[\\`({\[]+/, "")
  tok = tok.replace(/[`)\}\]]+$/, "")
  return tok
}

function normalizeCmdToken(token: string): string {
  let tok = stripTokenWrappers(token)
  tok = tok.replace(/;$/, "")
  tok = tok.toLowerCase()
  return tok.split("/").pop() || tok
}

// Path utilities

function normalizePath(path: string): string {
  const home = process.env.HOME || ""
  let normalized = path

  if (normalized.startsWith("~")) {
    normalized = home + normalized.slice(1)
  }

  const parts: string[] = []
  for (const part of normalized.split("/")) {
    if (part === "..") {
      parts.pop()
    } else if (part && part !== ".") {
      parts.push(part)
    }
  }

  return "/" + parts.join("/")
}

function isRootOrHomePath(path: string): boolean {
  return (
    path === "/" ||
    (path.startsWith("/") && normalizePath(path) === "/") ||
    path === "~" ||
    path.startsWith("~/") ||
    path === "$HOME" ||
    path.startsWith("$HOME/") ||
    path.startsWith("${HOME}")
  )
}

function isTempPath(path: string, allowTmpdirVar: boolean): boolean {
  if (path.startsWith("/")) {
    const normalized = normalizePath(path)
    return (
      normalized === "/tmp" ||
      normalized.startsWith("/tmp/") ||
      normalized === "/var/tmp" ||
      normalized.startsWith("/var/tmp/")
    )
  }

  if (!allowTmpdirVar) return false

  for (const prefix of ["$TMPDIR", "${TMPDIR}"]) {
    if (path === prefix) return true
    if (path.startsWith(`${prefix}/`)) {
      const rest = path.slice(prefix.length + 1)
      if (rest.split("/").includes("..")) return false
      return true
    }
  }

  return false
}

function isCwdItself(path: string, cwd: string): boolean {
  const normalized = normalizePath(path)
  if (normalized === "." || normalized === "") return true

  const resolved = path.startsWith("/") ? normalizePath(path) : normalizePath(`${cwd}/${path}`)

  return resolved === normalizePath(cwd)
}

function isPathWithinCwd(path: string, cwd: string): boolean {
  if (path.startsWith("~") || path.startsWith("$HOME") || path.startsWith("${HOME}")) return false
  if (path.includes("$") || path.includes("`")) return false

  const normalized = normalizePath(path)
  if (normalized === "." || normalized === "") return false

  const resolved = path.startsWith("/") ? normalizePath(path) : normalizePath(`${cwd}/${path}`)

  const cwdNormalized = normalizePath(cwd)
  if (resolved === cwdNormalized) return false

  return resolved.startsWith(`${cwdNormalized}/`)
}

// rm analysis

function rmTargets(tokens: string[]): string[] {
  const targets: string[] = []
  let afterDoubleDash = false

  for (const tok of tokens.slice(1)) {
    if (afterDoubleDash) {
      targets.push(tok)
      continue
    }
    if (tok === "--") {
      afterDoubleDash = true
      continue
    }
    if (tok.startsWith("-") && tok !== "-") continue
    targets.push(tok)
  }

  return targets
}

function analyzeRm(
  tokens: string[],
  opts: { allowTmpdirVar?: boolean; allowTmp?: boolean; cwd?: string; paranoid?: boolean; allowCwdRm?: boolean }
): BlockReason | null {
  const { allowTmpdirVar = true, allowTmp = true, cwd, paranoid = false, allowCwdRm = false } = opts
  const rest = tokens.slice(1)

  const optTokens: string[] = []
  for (const tok of rest) {
    if (tok === "--") break
    optTokens.push(tok)
  }

  const optsLower = optTokens.map((t) => t.toLowerCase())
  const short = shortOpts(optTokens)
  const recursive = optsLower.includes("--recursive") || short.has("r") || short.has("R")
  const force = optsLower.includes("--force") || short.has("f")

  if (!recursive || !force) return null

  const targets = rmTargets(tokens)
  if (targets.some((t) => isRootOrHomePath(t))) {
    return { reason: REASON_RM_RF_ROOT_HOME, ruleId: "core.rm.root-home", severity: "ERROR" }
  }

  if (cwd && targets.some((t) => isCwdItself(t, cwd))) {
    return { reason: REASON_RM_RF, ruleId: "core.rm.cwd", severity: "WARNING" }
  }

  if (targets.length > 0 && targets.every((t) => isTempPath(t, allowTmpdirVar))) {
    return allowTmp ? null : { reason: REASON_RM_RF_TMP, ruleId: "core.rm.tmp", severity: "WARNING" }
  }

  if (paranoid) {
    return { reason: REASON_RM_RF + PARANOID_RM_SUFFIX, ruleId: "core.rm.paranoid", severity: "WARNING" }
  }

  if (allowCwdRm && cwd && targets.length > 0) {
    const home = process.env.HOME
    if (home && normalizePath(cwd) === normalizePath(home)) {
      return { reason: REASON_RM_RF_ROOT_HOME, ruleId: "core.rm.root-home", severity: "ERROR" }
    }

    if (targets.every((t) => isPathWithinCwd(t, cwd))) return null
  }

  return { reason: REASON_RM_RF, ruleId: "core.rm.rf", severity: "WARNING" }
}

// git analysis

function gitSubcommandAndRest(tokens: string[]): [string | null, string[]] {
  if (tokens.length === 0 || tokens[0].toLowerCase() !== "git") return [null, []]

  let i = 1
  while (i < tokens.length) {
    const tok = tokens[i]
    if (tok === "--") {
      i++
      break
    }

    if (!tok.startsWith("-") || tok === "-") break

    if (GIT_OPTS_NO_VALUE.has(tok)) {
      i++
      continue
    }

    if (GIT_OPTS_WITH_VALUE.has(tok)) {
      i += 2
      continue
    }

    if (tok.startsWith("--")) {
      if (tok.includes("=")) {
        const [opt] = tok.split("=", 2)
        if (GIT_OPTS_WITH_VALUE.has(opt)) {
          i++
          continue
        }
      }
      i++
      continue
    }

    if ((tok.startsWith("-C") || tok.startsWith("-c")) && tok.length > 2) {
      i++
      continue
    }

    i++
  }

  if (i >= tokens.length) return [null, []]

  return [tokens[i], tokens.slice(i + 1)]
}

function checkoutPositionalArgs(rest: string[]): string[] {
  const positionals: string[] = []
  let i = 0

  while (i < rest.length) {
    const tok = rest[i]
    if (tok === "--") break

    if (tok === "-") {
      positionals.push(tok)
      i++
      continue
    }

    if (tok.startsWith("-")) {
      if (CHECKOUT_OPTS_NO_VALUE.has(tok)) {
        i++
        continue
      }

      if (tok.startsWith("--") && tok.includes("=")) {
        const [opt] = tok.split("=", 2)
        if (CHECKOUT_OPTS_WITH_VALUE.has(opt)) {
          i++
          continue
        }
        i++
        continue
      }

      if ((tok.startsWith("-U") || tok.startsWith("-b") || tok.startsWith("-B")) && tok.length > 2) {
        i++
        continue
      }

      if (CHECKOUT_OPTS_WITH_VALUE.has(tok)) {
        i += 2
        continue
      }

      if (tok === "--recurse-submodules") {
        if (i + 1 < rest.length && ["checkout", "on-demand"].includes(rest[i + 1])) {
          i += 2
          continue
        }
        i++
        continue
      }

      if (["-t", "--track"].includes(tok)) {
        if (i + 1 < rest.length && ["direct", "inherit"].includes(rest[i + 1])) {
          i += 2
          continue
        }
        i++
        continue
      }

      if (tok.startsWith("--")) {
        if (i + 1 < rest.length && !rest[i + 1].startsWith("-")) {
          i += 2
          continue
        }
        i++
        continue
      }

      i++
      continue
    }

    positionals.push(tok)
    i++
  }

  return positionals
}

function analyzeGit(tokens: string[]): BlockReason | null {
  const [sub, rest] = gitSubcommandAndRest(tokens)
  if (!sub) return null

  const subLower = sub.toLowerCase()
  const restLower = rest.map((t) => t.toLowerCase())
  const short = shortOpts(rest)

  switch (subLower) {
    case "checkout": {
      if (rest.includes("--")) {
        const idx = rest.indexOf("--")
        return idx === 0
          ? { reason: REASON_GIT_CHECKOUT_DOUBLE_DASH, ruleId: "core.git.checkout-double-dash", severity: "WARNING" }
          : {
              reason: REASON_GIT_CHECKOUT_REF_DOUBLE_DASH,
              ruleId: "core.git.checkout-ref-double-dash",
              severity: "WARNING",
            }
      }

      if (rest.includes("-b") || short.has("b")) return null
      if (rest.includes("-B") || short.has("B")) return null
      if (restLower.includes("--orphan")) return null

      const hasPathspecFromFile = restLower.some(
        (t) => t === "--pathspec-from-file" || t.startsWith("--pathspec-from-file=")
      )
      if (hasPathspecFromFile) {
        return { reason: REASON_GIT_CHECKOUT_PATHSPEC_FROM_FILE, ruleId: "core.git.checkout-pathspec", severity: "WARNING" }
      }

      const positional = checkoutPositionalArgs(rest)
      if (positional.length >= 2) {
        return { reason: REASON_GIT_CHECKOUT_REF_PATHSPEC, ruleId: "core.git.checkout-ref-pathspec", severity: "WARNING" }
      }

      return null
    }

    case "restore": {
      if (restLower.includes("-h") || restLower.includes("--help") || restLower.includes("--version")) return null
      if (restLower.includes("--worktree")) {
        return { reason: REASON_GIT_RESTORE_WORKTREE, ruleId: "core.git.restore-worktree", severity: "WARNING" }
      }
      if (restLower.includes("--staged")) return null
      return { reason: REASON_GIT_RESTORE, ruleId: "core.git.restore", severity: "WARNING" }
    }

    case "reset": {
      if (restLower.includes("--hard")) {
        return { reason: REASON_GIT_RESET_HARD, ruleId: "core.git.reset-hard", severity: "WARNING" }
      }
      if (restLower.includes("--merge")) {
        return { reason: REASON_GIT_RESET_MERGE, ruleId: "core.git.reset-merge", severity: "WARNING" }
      }
      return null
    }

    case "clean": {
      const hasForce = restLower.includes("--force") || short.has("f")
      return hasForce ? { reason: REASON_GIT_CLEAN_FORCE, ruleId: "core.git.clean-force", severity: "WARNING" } : null
    }

    case "push": {
      const hasForceWithLease = restLower.some((t) => t.startsWith("--force-with-lease"))
      const hasForce = restLower.includes("--force") || short.has("f")

      if (hasForce && !hasForceWithLease) {
        return { reason: REASON_GIT_PUSH_FORCE, ruleId: "core.git.push-force", severity: "WARNING" }
      }
      if (restLower.includes("--force") && hasForceWithLease) {
        return { reason: REASON_GIT_PUSH_FORCE, ruleId: "core.git.push-force", severity: "WARNING" }
      }
      if (short.has("f") && hasForceWithLease) {
        return { reason: REASON_GIT_PUSH_FORCE, ruleId: "core.git.push-force", severity: "WARNING" }
      }
      return null
    }

    case "worktree": {
      if (restLower.length === 0) return null
      if (restLower[0] !== "remove") return null

      let restForOpts = [...rest]
      if (restForOpts.includes("--")) {
        restForOpts = restForOpts.slice(0, restForOpts.indexOf("--"))
      }

      const restForOptsLower = restForOpts.map((t) => t.toLowerCase())
      const shortForOpts = shortOpts(restForOpts)
      const hasForce = restForOptsLower.includes("--force") || shortForOpts.has("f")

      return hasForce
        ? { reason: REASON_GIT_WORKTREE_REMOVE_FORCE, ruleId: "core.git.worktree-force", severity: "WARNING" }
        : null
    }

    case "branch": {
      if (rest.includes("-D") || short.has("D")) {
        return { reason: REASON_GIT_BRANCH_DELETE_FORCE, ruleId: "core.git.branch-force", severity: "WARNING" }
      }
      return null
    }

    case "stash": {
      if (restLower.length === 0) return null
      if (restLower[0] === "drop") {
        return { reason: REASON_GIT_STASH_DROP, ruleId: "core.git.stash-drop", severity: "WARNING" }
      }
      if (restLower[0] === "clear") {
        return { reason: REASON_GIT_STASH_CLEAR, ruleId: "core.git.stash-clear", severity: "WARNING" }
      }
      return null
    }
  }

  return null
}

// find analysis

function findHasDelete(args: string[]): boolean {
  let i = 0
  while (i < args.length) {
    const tok = stripTokenWrappers(args[i]).toLowerCase()

    if (FIND_EXEC_LIKE.has(tok)) {
      i++
      while (i < args.length) {
        const endTok = stripTokenWrappers(args[i])
        if ([";", "+"].includes(endTok)) {
          i++
          break
        }
        i++
      }
      continue
    }

    if (FIND_CONSUMES_ONE.has(tok)) {
      i += 2
      continue
    }

    if (tok === "-delete") return true

    i++
  }

  return false
}

// xargs/parallel analysis

function extractXargsChildCommand(tokens: string[]): string[] | null {
  if (tokens.length === 0 || normalizeCmdToken(tokens[0]) !== "xargs") return null

  let i = 1
  while (i < tokens.length) {
    const tok = tokens[i]
    if (tok === "--") {
      i++
      break
    }
    if (!tok.startsWith("-")) break

    if (XARGS_CONSUMES_VALUE.has(tok)) {
      i += 2
      continue
    }
    if (tok.startsWith("--") && tok.includes("=")) {
      i++
      continue
    }
    i++
  }

  if (i >= tokens.length) return null

  return tokens.slice(i)
}

function extractParallelChildCommand(tokens: string[]): string[] | null {
  if (tokens.length === 0 || normalizeCmdToken(tokens[0]) !== "parallel") return null

  let i = 1
  while (i < tokens.length) {
    const tok = tokens[i]
    if (tok === "--") {
      i++
      break
    }
    if (!tok.startsWith("-")) break

    if (tok === ":::" || tok === "::::") return null

    if (PARALLEL_CONSUMES_VALUE.has(tok)) {
      i += 2
      continue
    }
    if (tok.startsWith("--") && tok.includes("=")) {
      i++
      continue
    }
    i++
  }

  if (i >= tokens.length) return null

  return tokens.slice(i)
}

// Shell -c extraction

function extractDashCArg(tokens: string[]): string | null {
  for (let i = 1; i < tokens.length; i++) {
    const tok = tokens[i]
    if (tok === "--") return null

    if (tok === "-c") {
      return i + 1 < tokens.length ? tokens[i + 1] : null
    }

    if (tok.startsWith("-") && tok.length > 1 && /^[a-zA-Z]+$/.test(tok.slice(1))) {
      const letters = new Set(tok.slice(1).split(""))
      if (letters.has("c") && [...letters].every((c) => ["c", "l", "i", "s"].includes(c))) {
        return i + 1 < tokens.length ? tokens[i + 1] : null
      }
    }
  }
  return null
}

function hasShellDashC(tokens: string[]): boolean {
  for (let i = 1; i < tokens.length; i++) {
    const tok = tokens[i]
    if (tok === "--") break

    if (tok === "-c") return true

    if (tok.startsWith("-") && tok.length > 1 && /^[a-zA-Z]+$/.test(tok.slice(1))) {
      const letters = new Set(tok.slice(1).split(""))
      if (letters.has("c") && [...letters].every((c) => ["c", "l", "i", "s"].includes(c))) {
        return true
      }
    }
  }
  return false
}

function extractPythonishCodeArg(tokens: string[]): string | null {
  for (let i = 1; i < tokens.length; i++) {
    const tok = tokens[i]
    if (tok === "--") return null

    if (["-c", "-e"].includes(tok)) {
      return i + 1 < tokens.length ? tokens[i + 1] : null
    }
  }
  return null
}

function rmHasRecursiveForce(tokens: string[]): boolean {
  if (tokens.length === 0) return false

  const opts: string[] = []
  for (const tok of tokens.slice(1)) {
    if (tok === "--") break
    opts.push(tok)
  }

  const optsLower = opts.map((t) => t.toLowerCase())
  const short = shortOpts(opts)
  const recursive = optsLower.includes("--recursive") || short.has("r") || short.has("R")
  const force = optsLower.includes("--force") || short.has("f")

  return recursive && force
}

function dangerousInText(text: string): BlockReason | null {
  for (const { pattern, ruleId, severity } of DANGEROUS_PATTERNS) {
    if (pattern.test(text)) {
      return { reason: `Dangerous pattern detected: ${pattern.source}`, ruleId, severity }
    }
  }
  return null
}

// Main analysis

interface SegmentResult {
  segment: string
  reason: string
  ruleId: string
  severity: Severity
}

function interpreterLanguage(head: string): ScriptLanguage {
  switch (head) {
    case "python":
    case "python3":
      return "python"
    case "node":
      return "javascript"
    case "ruby":
      return "ruby"
    case "perl":
      return "perl"
    default:
      return "javascript"
  }
}

function analyzeInlineScript(
  code: string,
  language: ScriptLanguage,
  options: AnalyzeCommandOptions
): SegmentResult | null {
  if (code.length > INLINE_LIMIT_BYTES || code.split("\n").length > INLINE_LIMIT_LINES) {
    return {
      segment: code,
      reason: REASON_INLINE_SCRIPT,
      ruleId: "core.inline.too-large",
      severity: "WARNING",
    }
  }

  if (!INLINE_TRIGGER.test(code)) return null

  if (language === "shell") {
    return analyzeCommand(code, options)
  }

  const literals = extractStringLiterals(code, language)
  for (const literal of literals) {
    if (!INLINE_TRIGGER.test(literal)) continue
    const result = analyzeCommand(literal, options)
    if (result) return result
  }

  return {
    segment: code,
    reason: REASON_INLINE_SCRIPT,
    ruleId: "core.inline.opaque",
    severity: "WARNING",
  }
}

function analyzeHeredocs(command: string, options: AnalyzeCommandOptions): SegmentResult | null {
  if (!INLINE_TRIGGER.test(command)) return null

  const bodies = extractHeredocBodies(command)
  const hereStrings = extractHereStrings(command)
  const payloads = [...bodies, ...hereStrings]
  if (payloads.length > INLINE_LIMIT_PAYLOADS) {
    return {
      segment: command,
      reason: REASON_INLINE_SCRIPT,
      ruleId: "core.inline.too-many",
      severity: "WARNING",
    }
  }

  for (const payload of payloads) {
    if (payload.length > INLINE_LIMIT_BYTES || payload.split("\n").length > INLINE_LIMIT_LINES) {
      return {
        segment: command,
        reason: REASON_INLINE_SCRIPT,
        ruleId: "core.inline.too-large",
        severity: "WARNING",
      }
    }
    if (!INLINE_TRIGGER.test(payload)) continue
    const result = analyzeCommand(payload, options)
    if (result) return result
  }

  return payloads.length > 0
    ? {
        segment: command,
        reason: REASON_INLINE_SCRIPT,
        ruleId: "core.inline.opaque",
        severity: "WARNING",
      }
    : null
}

function analyzeSegment(
  segment: string,
  depth: number,
  cwd: string | undefined,
  strict: boolean,
  paranoidRm: boolean,
  paranoidInterpreters: boolean,
  allowTmp: boolean,
  allowCwdRm: boolean
): SegmentResult | null {
  if (depth > MAX_RECURSION_DEPTH) return null

  const tokens = shlexSplit(segment)
  if (tokens === null) {
    if (strict) {
      return { segment, reason: `Unparseable command${STRICT_SUFFIX}` }
    }
    return null
  }

  const strippedTokens = stripWrappers(tokens)
  if (strippedTokens.length === 0) return null

  const allowTmpdirVar = true
  const head = normalizeCmdToken(strippedTokens[0])

  if (SHELLS.has(head)) {
    const inner = extractDashCArg(strippedTokens)
    if (inner) {
      const result = analyzeCommand(inner, {
        depth: depth + 1,
        cwd,
        strict,
        paranoidRm,
        paranoidInterpreters,
        allowTmp,
        allowCwdRm,
      })
      if (result) return result
    }

    if (hasShellDashC(strippedTokens) && !inner) {
      if (strict) {
        return {
          segment,
          reason: `Unable to extract -c argument${STRICT_SUFFIX}`,
          ruleId: "core.shell.extract-dash-c",
          severity: "WARNING",
        }
      }
      return null
    }
  }

  if (INTERPRETERS.has(head)) {
    const code = extractPythonishCodeArg(strippedTokens)
    if (code) {
      if (paranoidInterpreters) {
        return {
          segment,
          reason: REASON_INTERPRETER_ONE_LINER + PARANOID_INTERPRETERS_SUFFIX,
          ruleId: "core.inline.paranoid",
          severity: "WARNING",
        }
      }

      const inlineResult = analyzeInlineScript(code, interpreterLanguage(head), {
        depth: depth + 1,
        cwd,
        strict,
        paranoidRm,
        paranoidInterpreters,
        allowTmp,
        allowCwdRm,
      })
      if (inlineResult) return { ...inlineResult, segment }
    }
  }

  if (head === "xargs") {
    const child = extractXargsChildCommand(strippedTokens)
    if (child) {
      const childHead = child.length > 0 ? normalizeCmdToken(child[0]) : null
      if (childHead === "rm" && rmHasRecursiveForce(child)) {
        return { segment, reason: REASON_XARGS_RM_RF, ruleId: "core.xargs.rm-rf", severity: "WARNING" }
      }
      if (childHead && SHELLS.has(childHead) && hasShellDashC(child)) {
        return {
          segment,
          reason: "xargs with shell -c can execute arbitrary commands.",
          ruleId: "core.xargs.shell-dash-c",
          severity: "WARNING",
        }
      }
    }
  }

  if (head === "parallel") {
    const child = extractParallelChildCommand(strippedTokens)
    if (child) {
      const childHead = child.length > 0 ? normalizeCmdToken(child[0]) : null
      if (childHead === "rm" && rmHasRecursiveForce(child)) {
        return { segment, reason: REASON_PARALLEL_RM_RF, ruleId: "core.parallel.rm-rf", severity: "WARNING" }
      }
      if (childHead && SHELLS.has(childHead) && hasShellDashC(child)) {
        return {
          segment,
          reason: "parallel with shell -c can execute arbitrary commands.",
          ruleId: "core.parallel.shell-dash-c",
          severity: "WARNING",
        }
      }
    }
  }

  if (head === "git") {
    const reason = analyzeGit(["git", ...strippedTokens.slice(1)])
    if (reason) return { segment, ...reason }
  }

  if (head === "rm") {
    const reason = analyzeRm(["rm", ...strippedTokens.slice(1)], {
      allowTmpdirVar,
      allowTmp,
      cwd,
      paranoid: paranoidRm,
      allowCwdRm,
    })
    if (reason) return { segment, ...reason }
  }

  if (head === "find" && findHasDelete(strippedTokens.slice(1))) {
    return { segment, reason: REASON_FIND_DELETE, ruleId: "core.find.delete", severity: "WARNING" }
  }

  for (let idx = 1; idx < strippedTokens.length; idx++) {
    const cmd = normalizeCmdToken(strippedTokens[idx])

    if (cmd === "rm") {
      const reason = analyzeRm(["rm", ...strippedTokens.slice(idx + 1)], {
        allowTmpdirVar,
        allowTmp,
        cwd,
        paranoid: paranoidRm,
        allowCwdRm,
      })
      if (reason) return { segment, ...reason }
    }

    if (cmd === "git") {
      const reason = analyzeGit(["git", ...strippedTokens.slice(idx + 1)])
      if (reason) return { segment, ...reason }
    }

    if (cmd === "find" && findHasDelete(strippedTokens.slice(idx + 1))) {
      return { segment, reason: REASON_FIND_DELETE, ruleId: "core.find.delete", severity: "WARNING" }
    }
  }

  const heredocResult = analyzeHeredocs(segment, {
    depth: depth + 1,
    cwd,
    strict,
    paranoidRm,
    paranoidInterpreters,
    allowTmp,
    allowCwdRm,
  })
  if (heredocResult) return heredocResult

  const danger = dangerousInText(segment)
  if (danger) return { segment, ...danger }

  return null
}

function segmentChangesCwd(segment: string): boolean {
  const tokens = shlexSplit(segment)
  if (tokens) {
    let working = [...tokens]
    while (working.length > 0 && ["{", "(", "$("].includes(working[0])) {
      working.shift()
    }
    working = stripWrappers(working)
    if (working.length > 0 && working[0].toLowerCase() === "builtin") {
      working.shift()
    }

    if (working.length > 0) {
      return ["cd", "pushd", "popd"].includes(normalizeCmdToken(working[0]))
    }
  }

  return /^\s*(?:\$\(\s*)?[({]*\s*(?:command\s+|builtin\s+)?(?:cd|pushd|popd)(?:\s|$)/i.test(segment)
}

interface AnalyzeCommandOptions {
  depth?: number
  cwd?: string
  strict?: boolean
  paranoidRm?: boolean
  paranoidInterpreters?: boolean
  allowTmp?: boolean
  allowCwdRm?: boolean
}

function analyzeCommand(command: string, options: AnalyzeCommandOptions = {}): SegmentResult | null {
  const {
    depth = 0,
    strict = false,
    paranoidRm = false,
    paranoidInterpreters = false,
    allowTmp = true,
    allowCwdRm = false,
  } = options

  let effectiveCwd = options.cwd

  for (const segment of splitShellCommands(command)) {
    const result = analyzeSegment(
      segment,
      depth,
      effectiveCwd,
      strict,
      paranoidRm,
      paranoidInterpreters,
      allowTmp,
      allowCwdRm
    )
    if (result) return result

    if (effectiveCwd && segmentChangesCwd(segment)) {
      effectiveCwd = undefined
    }
  }

  return null
}

// Secret redaction

function redactSecrets(text: string): string {
  const patterns = [
    /(password|passwd|pwd|secret|token|api[_-]?key|auth)[\s:=]+\S+/gi,
    /bearer\s+\S+/gi,
    /ghp_[a-zA-Z0-9]{36}/g,
    /gho_[a-zA-Z0-9]{36}/g,
    /github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}/g,
    /sk-[a-zA-Z0-9]{48}/g,
    /xox[baprs]-[a-zA-Z0-9-]+/g,
  ]

  let result = text
  for (const pattern of patterns) {
    result = result.replace(pattern, "[REDACTED]")
  }
  return result
}

export function formatBlockMessage(command: string, segment: string, reason: string, ruleId?: string): string {
  const safeCommand = redactSecrets(command).slice(0, 300)
  const safeSegment = redactSecrets(segment).slice(0, 300)
  const ruleLine = ruleId ? `Rule: ${ruleId}\n\n` : ""

  return `Safety Net: BLOCKED

Reason: ${reason}

${ruleLine}Command: ${safeCommand}

Segment: ${safeSegment}

If this operation is truly needed, ask the user for explicit permission and have them run the command manually.`
}

// Environment helpers

function envTruthy(name: string): boolean {
  const val = (process.env[name] || "").trim().toLowerCase()
  return ["1", "true", "yes", "on"].includes(val)
}

function envFalsy(name: string): boolean {
  const val = (process.env[name] || "").trim().toLowerCase()
  return ["0", "false", "no", "off"].includes(val)
}

export function getOptionsFromEnv(): AnalysisOptions {
  const paranoid = envTruthy("SAFETY_NET_PARANOID")
  return {
    strict: envTruthy("SAFETY_NET_STRICT"),
    paranoidRm: !envFalsy("SAFETY_NET_PARANOID_RM") || paranoid,
    paranoidInterpreters: paranoid || envTruthy("SAFETY_NET_PARANOID_INTERPRETERS"),
    allowTmp: !envFalsy("SAFETY_NET_ALLOW_TMP_RM"),
    allowCwdRm: envTruthy("SAFETY_NET_ALLOW_CWD_RM"),
  }
}

/**
 * Main analysis function - checks if a command should be blocked.
 */
export function analyze(command: string, options: AnalysisOptions = {}): AnalysisResult {
  const envOptions = getOptionsFromEnv()
  const mergedOptions = { ...envOptions, ...options }

  const result = analyzeCommand(command, {
    depth: 0,
    cwd: mergedOptions.cwd,
    strict: mergedOptions.strict,
    paranoidRm: mergedOptions.paranoidRm,
    paranoidInterpreters: mergedOptions.paranoidInterpreters,
    allowTmp: mergedOptions.allowTmp,
    allowCwdRm: mergedOptions.allowCwdRm,
  })

  if (result) {
    return {
      blocked: true,
      segment: result.segment,
      reason: result.reason,
      ruleId: result.ruleId,
      severity: result.severity,
    }
  }

  return { blocked: false }
}
