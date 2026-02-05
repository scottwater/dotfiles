---
name: inertia-auth
description: "Authentication and authorization patterns with Inertia in this app."
metadata:
  version: "2"
---

# Authentication and Authorization

Use when sharing auth state, gating UI, or handling auth errors.

## Shared auth context
```ruby
# app/controllers/inertia_controller.rb
inertia_share auth: -> {
  Current.user && {
    user: Current.user.as_json(
      only: %i[id name role active verified_at],
      methods: %i[email staff?]
    )
  }
}
```

```tsx
import { usePage } from "@inertiajs/react"
import type { SharedData } from "@/types"

const { auth } = usePage<SharedData>().props
```

## Authorization flags
Send booleans, not rules. This app commonly uses `role` and `staff`.
```ruby
render inertia: "Admin/Dashboard", props: {
  isStaff: Current.user&.staff?
}
```

```tsx
{isStaff && <Link href="/jobs">Jobs</Link>}
```

## Auth errors
Use `inertia_errors` or explicit errors on redirect.

```ruby
redirect_to new_session_path, inertia: { errors: { email_address: "Invalid email" } }
```

## Clear history on logout
```ruby
redirect_to root_path, notice: "Logged out", inertia: { clear_history: true }
```

## Client cache cleanup
```tsx
import { router } from "@inertiajs/react"

router.flushAll()
```
