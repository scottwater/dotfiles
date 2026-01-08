---
name: kapture
description: 'Browser automation and web interaction using Kapture. Use when asked to interact with web pages, take screenshots, click elements, fill forms, navigate browsers, or automate browser tasks.'
metadata:
  version: '1'
---

# Kapture Browser Automation Skill

Control browser tabs and interact with web pages using Kapture MCP.

## Available Tools

- `list_tabs` - List all connected browser tabs
- `new_tab` - Open a new browser tab
- `navigate` - Navigate to a URL
- `screenshot` - Capture a screenshot of the page or element
- `click` - Click on page elements
- `fill` - Fill input fields
- `keypress` - Send keyboard events
- `dom` - Get page HTML content
- `elements` - Query elements on the page
- `console_logs` - Get browser console logs

## Workflow

1. **List tabs** using `list_tabs` to see connected browsers
2. **Navigate** to target URL using `navigate`
3. **Interact** with elements using `click`, `fill`, `keypress`
4. **Screenshot** for visual verification using `screenshot`
5. **Analyze** with `look_at` tool for visual analysis

## Tips

- Open a new tab with `new_tab` if no tabs are connected
- Use `elements` to find interactive elements on the page
- Use `dom` to inspect page structure
- Check `console_logs` for JavaScript errors
- The Kapture DevTools panel must be open in the browser for best performance
