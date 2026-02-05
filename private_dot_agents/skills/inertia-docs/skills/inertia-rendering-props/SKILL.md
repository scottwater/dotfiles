---
name: inertia-rendering-props
description: "Render Inertia responses, shared data, and lazy or deferred props."
metadata:
  version: "2"
---

# Rendering and Props

Use when deciding how to render pages, share data, or optimize props.

## Render a page
Use `render inertia:` in this codebase. If you see `inertia_render` in older examples, treat it as `render inertia:` here.

```ruby
# app/controllers/lists_controller.rb
class ListsController < InertiaController
  def show
    render inertia: "Lists/Show", props: {
      list: { id: @list.id, name: @list.name },
      tasks: @list.ordered_active_tasks.map { |task| TaskSerializer.basic(task) }
    }
  end
end
```

## Shared data
- Global shared data lives in `ApplicationController` and `InertiaController`.
- Use lambdas so data is evaluated per-request and only for Inertia responses.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  inertia_share flash: -> { flash.to_hash },
    csrf_token: -> { form_authenticity_token }
end

# app/controllers/inertia_controller.rb
class InertiaController < ApplicationController
  inertia_share auth: -> {
    Current.user && {
      user: Current.user.as_json(only: %i[id name role], methods: %i[email staff?])
    }
  }
end
```

## Lazy props
- Prefer lambdas for expensive props.
- Combine with partial reloads so expensive props are only evaluated when requested.

```ruby
render inertia: "Dashboard", props: {
  vitals: -> { TaskSerializer.vitals_for_user(Current.user) },
  tasks: -> { Task.active_for_user(Current.user).map { |t| TaskSerializer.basic(t) } }
}
```

## Deferred props
Use `InertiaRails.defer` for non-critical data and render client-side with `<Deferred>`.

```ruby
render inertia: "Reports/Show", props: {
  report: @report.as_json,
  analytics: InertiaRails.defer { Analytics.for(@report) }
}
```

```tsx
import { Deferred } from "@inertiajs/react"

<Deferred data="analytics" fallback={<div>Loading...</div>}>
  {(analytics) => <AnalyticsPanel data={analytics} />}
</Deferred>
```

## Partial reload helpers
- Use `only` or `except` on visits and reloads.
- Mark props optional when they should only be evaluated on partial reloads.

```ruby
render inertia: "Lists/Show", props: {
  list: InertiaRails.optional { serialize_list(@list) },
  tasks: InertiaRails.always { serialize_tasks(@list) }
}
```

## Validation errors (server side)
Prefer consistent formatting with `inertia_errors`.

```ruby
# app/controllers/inertia_controller.rb
def inertia_errors(model, full_messages: true)
  { errors: model.errors.to_hash(full_messages).transform_values(&:to_sentence) }
end
```
