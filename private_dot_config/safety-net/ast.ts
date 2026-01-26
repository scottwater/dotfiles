export type ScriptLanguage = "shell" | "python" | "javascript" | "typescript" | "ruby" | "perl" | "go"

const JS_STRING = /(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)/g
const PY_STRING = /(?:"""[\s\S]*?"""|'''[\s\S]*?'''|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')/g
const RB_STRING = /(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')/g
const PERL_STRING = /(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')/g

const STRING_PATTERNS: Record<Exclude<ScriptLanguage, "shell">, RegExp> = {
  python: PY_STRING,
  javascript: JS_STRING,
  typescript: JS_STRING,
  ruby: RB_STRING,
  perl: PERL_STRING,
  go: RB_STRING,
}

function stripQuotes(text: string): string {
  const trimmed = text.trim()
  if (trimmed.length < 2) return trimmed

  const triple = (quote: string) =>
    trimmed.startsWith(quote.repeat(3)) && trimmed.endsWith(quote.repeat(3)) && trimmed.length >= 6

  if (triple("\"")) return trimmed.slice(3, -3)
  if (triple("'")) return trimmed.slice(3, -3)

  const start = trimmed[0]
  const end = trimmed[trimmed.length - 1]
  if ((start === "\"" || start === "'" || start === "`") && end === start) {
    return trimmed.slice(1, -1)
  }

  return trimmed
}

export function extractStringLiterals(code: string, language: Exclude<ScriptLanguage, "shell">): string[] {
  const pattern = STRING_PATTERNS[language]
  const matches = code.match(pattern) ?? []
  return matches.map(stripQuotes)
}

export function extractHeredocBodies(command: string): string[] {
  const lines = command.split("\n")
  const bodies: string[] = []
  const stack: Array<{ delimiter: string; allowTabs: boolean; buffer: string[] }> = []

  for (const line of lines) {
    if (stack.length > 0) {
      const current = stack[stack.length - 1]
      const candidate = current.allowTabs ? line.replace(/^\t+/, "") : line
      if (candidate.trim() === current.delimiter) {
        bodies.push(current.buffer.join("\n"))
        stack.pop()
        continue
      }
      current.buffer.push(line)
      continue
    }

    const heredocMatch = /<<-?\s*(["']?)([A-Za-z0-9_]+)\1/.exec(line)
    if (heredocMatch) {
      const allowTabs = heredocMatch[0].includes("<<-")
      stack.push({ delimiter: heredocMatch[2], allowTabs, buffer: [] })
    }
  }

  for (const pending of stack) {
    if (pending.buffer.length > 0) {
      bodies.push(pending.buffer.join("\n"))
    }
  }

  return bodies
}

export function extractHereStrings(command: string): string[] {
  const results: string[] = []
  const regex = /<<<\s*(?:"([^"]*)"|'([^']*)'|`([^`]*)`|([^\n;&|]+))/g
  let match: RegExpExecArray | null

  while ((match = regex.exec(command))) {
    const [, double, single, backtick, bare] = match
    const value = double ?? single ?? backtick ?? bare
    if (value) results.push(value.trim())
  }

  return results
}
