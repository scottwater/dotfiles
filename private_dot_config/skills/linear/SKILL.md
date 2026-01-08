---
name: linear
description: 'Manage Linear issues, projects, and workflows. Use when asked to create issues, update tickets, list tasks, manage projects, or interact with Linear in any way.'
metadata:
  version: '1'
---

# Linear Skill

Manage issues, projects, and workflows in Linear.

## Available Tools

- `list_issues` - List and search issues
- `get_issue` - Get issue details
- `create_issue` - Create new issues
- `update_issue` - Update existing issues
- `list_projects` - List projects
- `get_project` - Get project details
- `list_teams` - List teams
- `get_user` - Get user details
- `list_comments` - List issue comments
- `create_comment` - Add comments to issues

## Common Workflows

### Create an Issue
```
create_issue with title, team, and optional description/assignee
```

### Find My Issues
```
list_issues with assignee: "me"
```

### Update Issue Status
```
update_issue with id and state (e.g., "In Progress", "Done")
```

## Tips

- Use "me" as assignee to filter your own issues
- Issue states vary by team workflow
- Projects group related issues together
