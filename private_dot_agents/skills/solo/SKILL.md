---
name: solo
description: Use when the user asks to use Solo or the Solo MCP server to spawn coding agents, manage scratch pads, or manage todos.
metadata:
  trigger: Responding to requests to use Solo
---

# Solo

Solo is a desktop application for managing coding agents and project-scoped
coordination state. If the user asks Solo to do something, use the Solo MCP
server and its enabled feature tools. Do not defer to, check, or invoke a Solo
CLI.

## What Solo can do

The core MCP tools cover high-level project and process management:

- Select or inspect the effective Solo project, status, and stats.
- Discover local services, ports, processes, and terminal output.
- Start, stop, restart, rename, close, or send input to Solo-managed processes.
- Spawn terminals or coding agents, bind sessions, and check identity.
- Use project-scoped coordination locks and setup/support helpers.

Solo may also expose optional feature tools through the same MCP server:

- **Scratchpads:** list, read, write, rename, tag, append, clear, delete,
  archive, transfer, save, and load project scratchpads.
- **Todos:** create, list, read, update, tag, transfer, block/unblock,
  complete, lock/unlock, delete, and comment on project todos.
- **Timers:** create one-shot timers, create idle-triggered timers, cancel,
  pause, resume, and list timers.
- **Key-value storage:** read and write project-scoped JSON key-value data.

These feature tools are controlled by Solo settings. Scratchpads, todos, and
timers usually inherit MCP server enablement unless explicitly configured;
key-value tools may need to be enabled separately.

## Usage guidance

- Prefer Solo tools when the task is about Solo-managed agents, scratchpads,
  todos, timers, project coordination, or Solo process/output state.
- If exact tool names are unclear, inspect the MCP tool catalog rather than
  guessing.
- Most tools operate in the effective project scope. Select the project first
  when needed, or rely on Solo's session binding when launched by Solo.
- When spawning a new agent, monitor it for questions and permission requests.
  Approve requests only when they are safe and necessary.

