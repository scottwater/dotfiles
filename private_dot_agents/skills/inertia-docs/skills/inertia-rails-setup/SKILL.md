---
name: inertia-rails-setup
description: "Set up and configure inertia_rails + React/Vite in this codebase."
metadata:
  version: "2"
---

# Inertia Rails Setup

Use when wiring Inertia Rails, adjusting config, or debugging boot issues.

## Checklist
- Gemfile includes `inertia_rails` and `vite_rails`.
- `config/initializers/inertia_rails.rb` defines version, history encryption, and parent controller.
- Layouts include `title inertia`, `vite_typescript_tag "inertia.tsx"`, and `inertia_ssr_head`.
- Client entrypoint `app/frontend/entrypoints/inertia.tsx` boots `createInertiaApp`.
- `InertiaController` is the base for Inertia pages.

## InertiaRails configuration (this app)
```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  config.encrypt_history = true
  config.parent_controller = "::InertiaController"
  config.always_include_errors_hash = true
  config.use_script_element_for_initial_page = true
end
```

## Layout wiring (this app)
```erb
<!-- app/views/layouts/application.html.erb -->
<title inertia><%= content_for(:title) || "ToDoOrDie" %></title>
<%= vite_typescript_tag "inertia.tsx" %>
<%= inertia_ssr_head %>
```

## Base controller (this app)
```ruby
# app/controllers/inertia_controller.rb
class InertiaController < ApplicationController
  inertia_config default_render: true
  inertia_share auth: -> { Current.user && { user: Current.user.as_json(only: %i[id name]) } }
end
```

## Notes
- `config.version` should track asset digests to force full reloads when assets change.
- `use_script_element_for_initial_page` pairs with `defaults.future.useScriptElementForInitialPage` in the entrypoint.
