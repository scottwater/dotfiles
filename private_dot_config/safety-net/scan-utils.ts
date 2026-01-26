import { parseDocument, visit, isPair, isScalar, isSeq } from "yaml"

export interface CommandCandidate {
  command: string
  line: number
}

export interface ScanFinding {
  file: string
  line: number
  command: string
  reason: string
  ruleId: string
  severity: "ERROR" | "WARNING"
}

const SHELL_EXTENSIONS = new Set([".sh", ".bash", ".zsh", ".fish", ".ksh"])

function isShellScript(path: string): boolean {
  return [...SHELL_EXTENSIONS].some((ext) => path.endsWith(ext))
}

function isDockerfile(path: string): boolean {
  return path.endsWith("Dockerfile") || path.endsWith(".dockerfile")
}

function isGitHubWorkflow(path: string): boolean {
  return path.includes("/.github/workflows/") && (path.endsWith(".yml") || path.endsWith(".yaml"))
}

function isGitLabCi(path: string): boolean {
  return path.endsWith(".gitlab-ci.yml") || path.endsWith(".gitlab-ci.yaml")
}

function isMakefile(path: string): boolean {
  const name = path.split("/").pop() ?? ""
  return name === "Makefile" || name === "makefile"
}

function isTerraform(path: string): boolean {
  return path.endsWith(".tf")
}

function isCompose(path: string): boolean {
  const name = path.split("/").pop() ?? ""
  return ["docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"].includes(name)
}

async function readText(path: string): Promise<string | null> {
  try {
    const file = Bun.file(path)
    if (!(await file.exists())) return null
    return await file.text()
  } catch {
    return null
  }
}

function lineNumberAtIndex(text: string, index: number): number {
  let line = 1
  let i = 0
  while (i < index) {
    const next = text.indexOf("\n", i)
    if (next === -1 || next >= index) break
    line++
    i = next + 1
  }
  return line
}

function extractShellCommands(text: string): CommandCandidate[] {
  const lines = text.split("\n")
  const commands: CommandCandidate[] = []
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue
    if (/^\w+\s*=/.test(trimmed)) continue
    commands.push({ command: trimmed, line: i + 1 })
  }
  return commands
}

function extractDockerfileCommands(text: string): CommandCandidate[] {
  const lines = text.split("\n")
  const commands: CommandCandidate[] = []
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    const match = /^\s*RUN\s+(.*)$/i.exec(line)
    if (!match) continue
    commands.push({ command: match[1].trim(), line: i + 1 })
  }
  return commands
}

function extractMakefileCommands(text: string): CommandCandidate[] {
  const lines = text.split("\n")
  const commands: CommandCandidate[] = []
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    if (!/^\t/.test(line)) continue
    const trimmed = line.trim()
    if (!trimmed) continue
    commands.push({ command: trimmed, line: i + 1 })
  }
  return commands
}

function extractYamlCommands(text: string, keys: string[]): CommandCandidate[] {
  const commands: CommandCandidate[] = []
  let doc
  try {
    doc = parseDocument(text)
  } catch {
    return commands
  }

  visit(doc, (key, node) => {
    if (!isPair(node)) return

    const keyNode = node.key
    if (!isScalar(keyNode) || typeof keyNode.value !== "string") return
    if (!keys.includes(keyNode.value)) return

    const valueNode = node.value
    if (!valueNode) return

    if (isSeq(valueNode)) {
      for (const item of valueNode.items) {
        if (isScalar(item) && typeof item.value === "string") {
          commands.push({ command: item.value, line: item.range ? lineNumberAtIndex(text, item.range[0]) : 1 })
        }
      }
      return
    }

    if (isScalar(valueNode) && typeof valueNode.value === "string") {
      commands.push({ command: valueNode.value, line: valueNode.range ? lineNumberAtIndex(text, valueNode.range[0]) : 1 })
    }
  })

  return commands
}

function extractTerraformCommands(text: string): CommandCandidate[] {
  const commands: CommandCandidate[] = []
  const regex = /\bprovisioner\s+"(local-exec|remote-exec)"\s*\{([\s\S]*?)\n\}/g
  let match: RegExpExecArray | null
  while ((match = regex.exec(text))) {
    const block = match[2]
    const cmdMatch = /\b(command|inline)\s*=\s*"([\s\S]*?)"/g
    let inner: RegExpExecArray | null
    while ((inner = cmdMatch.exec(block))) {
      commands.push({ command: inner[2], line: lineNumberAtIndex(text, match.index) })
    }
  }
  return commands
}

export async function extractCommandsFromFile(path: string): Promise<CommandCandidate[]> {
  const text = await readText(path)
  if (!text) return []

  if (isShellScript(path)) return extractShellCommands(text)
  if (isDockerfile(path)) return extractDockerfileCommands(text)
  if (isGitHubWorkflow(path)) return extractYamlCommands(text, ["run"])
  if (isGitLabCi(path)) return extractYamlCommands(text, ["script", "before_script", "after_script"])
  if (isMakefile(path)) return extractMakefileCommands(text)
  if (isTerraform(path)) return extractTerraformCommands(text)
  if (isCompose(path)) return extractYamlCommands(text, ["command", "entrypoint"])

  return []
}
