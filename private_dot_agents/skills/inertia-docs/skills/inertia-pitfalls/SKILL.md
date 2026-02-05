---
name: inertia-pitfalls
description: "Common Inertia Rails gotchas in this codebase."
metadata:
  version: "2"
---

# Common Pitfalls and Gotchas

Use when debugging weird behavior or reviewing PRs.

## Missing root element
The entrypoint throws when loaded on non-Inertia pages. Ensure `vite_typescript_tag "inertia.tsx"` is only in Inertia layouts.

## Page component mismatch
`inertia_config default_render: true` relies on naming. If you skip `render inertia:`, the component must exist at the inferred path.

## Error shape mismatch
- `errorValueType` is `string[]` in `app/frontend/types/global.d.ts`.
- Some controllers pass string errors. Prefer `inertia_errors` to normalize.

## Cache invalidation
Prefetching caches responses. After mutations, flush with `router.flush` or `router.flushAll`.

## Stale bfcache data
Back-forward cache restores old props. Use `useBfcacheReload` (already in `PersistentLayout`).

## Over-sharing props
Keep shared props minimal. Large shared data slows every response.

## SSR mismatches
If SSR is enabled, keep `use_script_element_for_initial_page` and `defaults.future.useScriptElementForInitialPage` aligned.
