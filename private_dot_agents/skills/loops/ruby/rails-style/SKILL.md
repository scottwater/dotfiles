---
name: rails-style
description: Opinionated Ruby on Rails style guidance focused on simple Rails defaults, clear naming, RESTful design, and maintainable code.
---

# Rails Style

Use this skill when writing or refactoring Ruby/Rails code.

## Principles

- Prefer built-in Rails conventions over custom abstractions.
- Keep controllers thin and focused on HTTP flow.
- Keep domain behavior in models and cohesive POROs.
- Use RESTful resources and routes over custom action endpoints.
- Favor clarity over cleverness in naming and structure.

## Code Preferences

- Use strong params and explicit permitted attributes.
- Keep controller actions small and composable.
- Use expressive scopes and predicate methods.
- Avoid architecture layers that fight Rails conventions.
- Add tests for behavior changes and edge cases.

## Review Checklist

- Is this idiomatic Rails?
- Is the flow understandable in one read?
- Did we avoid unnecessary indirection?
- Are routes/actions REST-shaped?
- Are names precise and consistent?
