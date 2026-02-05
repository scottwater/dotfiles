---
name: inertia-ssr
description: "Server-side rendering setup for Inertia Rails + React."
metadata:
  version: "2"
---

# SSR Configuration

Use when enabling or debugging server-side rendering.

## Rails config
```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_enabled = false
  config.ssr_url = "http://localhost:13714"
end
```

## Layout hook
```erb
<%= inertia_ssr_head %>
```

## SSR entrypoint (this app)
```tsx
// app/frontend/ssr/ssr.ts
import createServer from "@inertiajs/react/server"

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      const pages = import.meta.glob("../pages/**/*.tsx", { eager: true })
      const pageModule = pages[`../pages/${name}.tsx`]
      pageModule.default.layout ??= (p) => createElement(PersistentLayout, null, p)
      return pageModule
    },
    setup: ({ App, props }) => createElement(App, props),
  })
)
```

## Client hydration hook
`app/frontend/entrypoints/inertia.tsx` includes a commented `hydrateRoot` block. Use it if SSR is enabled.

## Notes
- Keep `use_script_element_for_initial_page` aligned with `defaults.future.useScriptElementForInitialPage`.
- Run a Node SSR server and set `INERTIA_SSR_ENABLED` and `INERTIA_SSR_URL` when deploying.
