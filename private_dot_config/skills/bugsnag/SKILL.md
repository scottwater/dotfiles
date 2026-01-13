---
name: bugsnag
description: 'Interact with BugSnag for error monitoring and debugging. Use when asked to analyze errors, view stack traces, check error trends, or debug issues across projects.'
metadata:
  version: '1'
---

# BugSnag Skill

Error monitoring and debugging with BugSnag.

## Project Selection

**First, check for `BUGSNAG_PROJECT_ID` environment variable:**

1. If `BUGSNAG_PROJECT_ID` is set, use that project ID and inform the user which project you're using
2. If not set, call `bugsnag_list_projects` first to discover available projects and show the user the project names and IDs found

## BugSnag Release Stages

Common release stages across projects:
- `production` - Production environment
- `demo` - Demo/staging environment  
- `review` - Review apps (PR environments)

## BugSnag Quick Reference

### Filtering by Release Stage

The filter field for release stage is `app.release_stage` (not `release_stage`):

```json
{
  "projectId": "<project_id>",
  "filters": {
    "app.release_stage": [{"type": "eq", "value": "demo"}],
    "event.since": [{"type": "eq", "value": "7d"}],
    "error.status": [{"type": "eq", "value": "open"}]
  }
}
```

### Common Filter Examples

**Errors by release stage (last 7 days):**
```json
{
  "projectId": "<project_id>",
  "filters": {
    "app.release_stage": [{"type": "eq", "value": "demo"}],
    "event.since": [{"type": "eq", "value": "7d"}]
  }
}
```

**Production errors (last 24 hours):**
```json
{
  "projectId": "<project_id>",
  "filters": {
    "app.release_stage": [{"type": "eq", "value": "production"}],
    "event.since": [{"type": "eq", "value": "24h"}]
  }
}
```

**Errors affecting a specific user:**
```json
{
  "filters": {
    "user.email": [{"type": "eq", "value": "user@example.com"}]
  }
}
```

### Time Filter Formats

- Relative: `7d`, `24h`, `30d`, `1h`
- ISO 8601: `2024-01-15T00:00:00Z`

## Available Tools

- Analyze error events and stack traces
- View organization and project details
- Debug issues with context and breadcrumbs
- Filter errors by release stage, time, user, and status

## Common Workflows

### Analyze an Error
```
Get event details from BugSnag, analyze stack trace and breadcrumbs
```

### Check Recent Errors
```
List errors for a project filtered by release stage and time range
```

### Debug User-Reported Issue
```
Filter errors by user email to find related events
```

## Setup

Requires environment variables:
- `BUGSNAG_ACCESS_TOKEN` - BugSnag API access token
- `BUGSNAG_PROJECT_ID` (optional) - Default project ID to use
