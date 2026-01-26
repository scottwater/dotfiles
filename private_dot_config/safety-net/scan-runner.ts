import { resolve } from "node:path"
import { analyze } from "./core"
import { extractCommandsFromFile, ScanFinding } from "./scan-utils"

function printFinding(finding: ScanFinding): void {
  const location = `${finding.file}:${finding.line}`
  const details = `${finding.ruleId} ${finding.severity}`
  const message = `${location} ${details}\n  Command: ${finding.command}\n  Reason: ${finding.reason}`
  console.log(message)
}

async function scanFile(path: string, root: string): Promise<ScanFinding[]> {
  const candidates = await extractCommandsFromFile(path)
  const findings: ScanFinding[] = []

  for (const candidate of candidates) {
    const result = analyze(candidate.command, { cwd: root })
    if (!result.blocked) continue

    findings.push({
      file: path,
      line: candidate.line,
      command: candidate.command,
      reason: result.reason ?? "Blocked",
      ruleId: result.ruleId ?? "core.unknown",
      severity: result.severity ?? "WARNING",
    })
  }

  return findings
}

async function scanDirectory(root: string): Promise<ScanFinding[]> {
  const entries = await Array.fromAsync(new Bun.Glob("**/*").scan({
    cwd: root,
    dot: true,
    onlyFiles: true,
    followSymlinks: false,
  }))

  const findings: ScanFinding[] = []
  for (const entry of entries) {
    const path = `${root}/${entry}`
    const fileFindings = await scanFile(path, root)
    findings.push(...fileFindings)
  }
  return findings
}

export async function runScan(args: string[]): Promise<number> {
  const root = args[0] ? resolve(process.cwd(), args[0]) : process.cwd()
  const findings = await scanDirectory(root)
  if (findings.length === 0) {
    console.log("Safety Net scan: no findings")
    return 0
  }

  for (const finding of findings) {
    printFinding(finding)
  }

  return 2
}
