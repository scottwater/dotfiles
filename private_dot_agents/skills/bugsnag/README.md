# BugSnag Skill

This skill provides BugSnag error monitoring integration via the SmartBear MCP server.

## Required Environment Variables

### `BUGSNAG_ACCESS_TOKEN`

Your BugSnag API access token. Generate one from:
https://app.bugsnag.com/settings/smartbear-software/my-account/auth-tokens

Without this token, the skill cannot connect to BugSnag.

## Optional Environment Variables

### `BUGSNAG_PROJECT_ID`

The default BugSnag project ID to use for queries.

**If set:** The skill will use this project ID automatically and inform you which project is being used.

**If not set:** The skill will first call `bugsnag_list_projects` to discover available projects and display the project names and IDs found, allowing you to choose which project to query.

## Example Setup

```bash
export BUGSNAG_ACCESS_TOKEN="your-token-here"
export BUGSNAG_PROJECT_ID="your-project-id"  # optional
```
