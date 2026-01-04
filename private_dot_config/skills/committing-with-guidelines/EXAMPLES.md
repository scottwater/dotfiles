# Git Commit Examples and Scenarios

This document provides detailed examples and workflows for applying the git commit guidelines.

## Good vs. Bad Commit Messages

### Example 1: Product Decision Focus

#### ✅ Good: Focused on product decision

```
Add team filtering to admin progress dashboard

- Filters support multiple teams, goals, and date ranges
- Default view shows all active teams from current quarter
- Filter state persists in URL for shareability
```

**Why it's good:** Focuses on product capabilities and user-facing decisions, not implementation details.

#### ❌ Bad: Task list instead of decisions

```
Add team filtering feature

- Added TeamFilterForm
- Created filter partial
- Updated controller to handle filters
- Added specs for filter form
- Updated team goals view
```

**Why it's bad:** Lists implementation tasks rather than explaining the product decision and architectural choices.

### Example 2: Simple, Self-Explanatory Changes

#### ✅ Good: Simple change with adequate summary

```
Update password reset email copy
```

**Why it's good:** The summary is completely self-explanatory; no body needed.

#### ❌ Bad: Including test details

```
Update user authentication flow

- Changed session expiry to 30 days
- Added remember me checkbox
- Added tests for session persistence
- Updated controller specs
```

**Why it's bad:** Includes test details (tests are expected) and mixes feature changes with test implementation.

### Example 3: Architecture Decision

#### ✅ Good: Architecture decision

```
Add event bus for cross-domain notifications

- Decouples notification generation from business logic
- Enables multiple subscribers for the same events
- Foundation for future audit logging and analytics
```

**Why it's good:** Explains the architectural pattern, its benefits, and future implications.

#### ❌ Bad: Implementation details only

```
Add event bus

- Created EventBus class
- Added publish and subscribe methods
- Updated notification services
- Added tests
```

**Why it's bad:** Focuses on what was coded rather than why this architecture was chosen.

## Planning Workflow Example

**Scenario:** You've modified 8 files to add a filtering feature

### Step 1 - Review changes

```bash
git status
# Shows:
# - db/migrate/xxx_add_filters_to_team_goals.rb
# - app/models/team_goal.rb
# - app/forms/kommand/team_goals/filter_form.rb
# - app/controllers/kommand/team_goals_controller.rb
# - app/views/kommand/team_goals/_filters.html.haml
# - app/views/kommand/team_goals/_team_goals.html.haml
# - spec/models/team_goal_spec.rb
# - spec/forms/kommand/team_goals/filter_form_spec.rb
```

### Step 2 - Plan the story

1. Database schema changes (migration)
2. Model updates to support filtering
3. Filter form and validation logic
4. Controller integration
5. UI components

### Step 3 - Stage and commit incrementally

```bash
# Commit 1: Add database schema
git add db/migrate/xxx_add_filters_to_team_goals.rb
git commit -m "Add database columns for team goal filtering"

# Commit 2: Update model
git add app/models/team_goal.rb spec/models/team_goal_spec.rb
git commit -m "Add filtering scopes to team goal model"

# Commit 3: Add filter form
git add app/forms/kommand/team_goals/filter_form.rb spec/forms/kommand/team_goals/filter_form_spec.rb
git commit -m "Add filter form with validation for team goals"

# Commit 4: Integrate into controller
git add app/controllers/kommand/team_goals_controller.rb
git commit -m "Add filtering support to team goals controller"

# Commit 5: Add UI
git add app/views/kommand/team_goals/_filters.html.haml app/views/kommand/team_goals/_team_goals.html.haml
git commit -m "Add filter UI to team goals dashboard"
```

## Rebase Examples

### Example 1: Rearranging for Better Story

**Before rebase (chronological order):**
```
1. Add team goals model
2. Add filtering UI components
3. Add database schema for team goals
4. Add team goals controller
5. Update team goals model with validations
6. Add filtering logic to controller
```

**After rebase (logical story order):**
```
1. Add database schema for team goals
2. Add team goals model with validations
3. Add team goals controller
4. Add filtering logic to controller
5. Add filtering UI components
```

**Commands used:**
```bash
git rebase -i HEAD~6
# In editor: reorder the lines to match logical sequence
# Save and exit
```

### Example 2: Squashing Related Changes

**Before:**
```
1. Add notification preferences model
2. Fix typo in notification preferences
3. Add notification preferences controller
4. Update notification preferences validation
```

**After:**
```
1. Add notification preferences model with validations
2. Add notification preferences controller
```

**Commands used:**
```bash
git rebase -i HEAD~4
# In editor:
# pick 1st commit
# fixup 2nd commit (fold typo fix)
# pick 3rd commit
# fixup 4th commit (fold validation update)
```

### Rebase Workflow Example

```bash
# Review your commits
git log --oneline -n 5

# Start interactive rebase (last 5 commits)
git rebase -i HEAD~5

# In the editor that opens:
# - Reorder lines to change commit order
# - Change 'pick' to 'fixup' to squash commits
# - Change 'pick' to 'reword' to edit message
# Save and exit

# If conflicts occur:
git status         # See conflicting files
# ... fix conflicts in your editor ...
git add .
git rebase --continue

# Test everything works
bundle exec rspec

# Push (use --force-with-lease if already pushed)
git push origin your-branch-name --force-with-lease
```

## Multi-Step Feature Example

When working on a multi-part feature, break it into a logical sequence:

```bash
# 1. Foundation
git commit -m "Add user authentication schema"

# 2. Core functionality
git commit -m "Add user authentication with bcrypt"

# 3. Integration
git commit -m "Add authentication to API endpoints"

# 4. User experience
git commit -m "Add login and logout UI components"

# 5. Polish
git commit -m "Add password reset flow"
```

Each commit tells one part of the story and builds logically on the previous one.

## Handling Unrelated Changes

If you discover unrelated changes mixed in your working directory:

```bash
# Use patch mode to selectively stage changes
git add -p

# For each hunk:
# - 'y' to stage this hunk
# - 'n' to skip this hunk
# - 's' to split into smaller hunks
# - 'q' to quit

# Commit the staged changes
git commit -m "Add feature X"

# Stage and commit the remaining unrelated changes
git add other_file.rb
git commit -m "Fix unrelated bug in other_file"
```

## Context-Rich Commit Bodies

### Example: Migration with Trade-offs

```
Update user authentication to use OAuth2

- Migrating from custom auth to OAuth2 for better security
- Maintains backward compatibility with existing sessions
- Users will be prompted to re-authenticate on next login
- Simplifies future integration with SSO providers
```

### Example: Performance Optimization

```
Add database indexes for team goal queries

- Indexed team_id, status, and created_at columns
- Reduces dashboard load time from 2.5s to 0.3s
- Trade-off: slightly slower writes (acceptable for read-heavy feature)
```

### Example: Breaking Change

```
Remove deprecated v1 API endpoints

- All clients have been migrated to v2 API
- Removes 3000+ lines of legacy code
- Simplifies maintenance and security patching
```

## Tips for Consistent Commit Messages

1. **Start with the verb:** Add, Update, Remove
2. **Be specific:** "Add team filtering" not "Add feature"
3. **Think product:** "Add password reset flow" not "Add PasswordResetController"
4. **Explain trade-offs:** If you made a choice, explain why
5. **One logical change:** If you're using "and" multiple times, consider splitting
6. **Tests are implied:** Don't mention test additions unless they're the primary change
7. **No AI attribution:** AI is a tool, you're the author
