---
name: inertia-navigation
description: "Links, navigation, partial reloads, scroll, and cache control."
metadata:
  version: "2"
---

# Links and Navigation

Use when wiring navigation, reloads, or cache invalidation.

## Prefer Link for internal nav
```tsx
import { Link } from "@inertiajs/react"
import { listsPath } from "@/routes"

<Link href={listsPath()} prefetch>All Tasks</Link>
```

## Programmatic visits
```tsx
import { router } from "@inertiajs/react"

router.post("/lists", { name: "Inbox" }, { preserveScroll: true })
router.delete("/lists/1", { preserveScroll: true })
```

## Partial reloads
- Use `only` or `except` to limit props.
- This app uses partial reloads for Action Cable updates.

```tsx
router.reload({ only: ["tasks", "list"] })
```

## Scroll and state
- Use `preserveScroll` for inline updates.
- Use `preserveState` when staying on the same component with new params.

```tsx
router.get("/lists", { status: "completed" }, { preserveScroll: true, preserveState: true })
```

## Prefetch + cache invalidation
- Links commonly use `prefetch` for snappy nav.
- After mutations, flush cached pages.

```tsx
import { router } from "@inertiajs/react"

router.flush("/lists")
router.flushAll()
```

## Request headers
This app adds the browser timezone before every visit.

```tsx
router.on("before", (event) => {
  event.detail.visit.headers["X-Browser-Timezone"] =
    Intl.DateTimeFormat().resolvedOptions().timeZone
})
```
