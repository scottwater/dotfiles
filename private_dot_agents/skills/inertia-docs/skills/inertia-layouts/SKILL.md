---
name: inertia-layouts
description: "Persistent and nested layout patterns for Inertia pages."
metadata:
  version: "2"
---

# Layouts

Use when creating or modifying layout structure.

## Default layout (this app)
```tsx
// app/frontend/entrypoints/inertia.tsx
page.default.layout ??= [PersistentLayout]
```

`PersistentLayout` wires flash toasts, Action Cable, and bfcache reloads.

```tsx
// app/frontend/layouts/persistent-layout.tsx
export default function PersistentLayout({ children }: { children: ReactNode }) {
  useFlash()
  useBfcacheReload()
  useCable()
  return <TimeProvider>{children}<Toaster richColors /></TimeProvider>
}
```

## Page-specific layouts
Wrap layouts inside the page component for nested composition.

```tsx
import AppLayout from "@/layouts/app-layout"
import SettingsLayout from "@/layouts/settings/layout"

export default function Profile() {
  return (
    <AppLayout>
      <SettingsLayout>
        <ProfileForm />
      </SettingsLayout>
    </AppLayout>
  )
}
```

## Notes
- Keep layouts pure and persistent. Avoid per-page state in the default layout.
- Use `Head` in pages to set titles and meta.
