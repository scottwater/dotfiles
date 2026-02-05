---
name: inertia-reference
description: "Overview and project conventions for Inertia Rails + React in ToDoOrDie."
metadata:
  version: "2"
---

# Inertia Reference (ToDoOrDie)

Use this skill for orientation, file map, and baseline conventions before deeper edits.

## When to use
- Starting a new Inertia feature in this repo
- Unsure where shared props, layouts, or SSR are configured
- Need a quick map before editing a controller or page

## Project map
- `config/initializers/inertia_rails.rb`
- `app/controllers/application_controller.rb`
- `app/controllers/inertia_controller.rb`
- `app/views/layouts/application.html.erb`
- `app/views/layouts/public.html.erb`
- `app/frontend/entrypoints/inertia.tsx`
- `app/frontend/layouts/persistent-layout.tsx`
- `app/frontend/ssr/ssr.ts`

## Baseline conventions in this app
- Inertia controllers inherit `InertiaController`.
- `inertia_config default_render: true` is enabled.
- Shared props are lambdas in `ApplicationController` and `InertiaController`.
- Default layout is `PersistentLayout`.
- Client sets `X-Browser-Timezone` on every visit.
- Validation errors are passed as `ActiveModel::Errors` or via `inertia_errors`.

## Quick example
```ruby
# app/controllers/lists_controller.rb
class ListsController < InertiaController
  def index
    render inertia: "Lists/Index", props: {
      lists: Current.user.lists.order(:name).map { |l| { id: l.id, name: l.name } }
    }
  end
end
```

## Related skills
- `inertia-rails-setup`
- `inertia-rendering-props`
- `inertia-forms-validation`
- `inertia-navigation`
- `inertia-layouts`
- `inertia-ssr`
- `inertia-auth`
- `inertia-testing`
- `inertia-pitfalls`
