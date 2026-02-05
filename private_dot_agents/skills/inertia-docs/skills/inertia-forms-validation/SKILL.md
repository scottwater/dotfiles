---
name: inertia-forms-validation
description: "Inertia useForm patterns, custom Form helper, and validation errors."
metadata:
  version: "2"
---

# Forms and Validation

Use when building or updating forms and error handling.

## Distinction: two Form components
- **App Form**: `@/components/form` (custom wrapper + Radix UI). Preferred here.
- **Inertia Form**: `@inertiajs/react` `<Form>` component (uncontrolled HTML, no onChange needed).

## Default pattern (this app)
```tsx
import { useForm } from "@inertiajs/react"
import {
  Form,
  FormField,
  FormItem,
  FormLabel,
  FormControl,
  FormMessage,
} from "@/components/form"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"

const form = useForm({ name: "" })

<Form
  form={form}
  onSubmit={() => form.post("/lists", { preserveScroll: true })}
>
  <FormField
    name="name"
    render={({ field, error }) => (
      <FormItem>
        <FormLabel>Name</FormLabel>
        <FormControl>
          <Input {...field} />
        </FormControl>
        <FormMessage>{error?.[0]}</FormMessage>
      </FormItem>
    )}
  />

  <Button disabled={form.processing}>Save</Button>
</Form>
```

## Inertia `<Form>` component (uncontrolled)
No `onChange` required. Use `name` attributes; in React set `defaultValue`/`defaultChecked` for defaults.

```tsx
import { Form } from "@inertiajs/react"

<Form action="/users" method="post">
  <input type="text" name="name" defaultValue="Jane" />
  <input type="email" name="email" />
  <input type="checkbox" name="subscribe" value="1" defaultChecked />
  <button type="submit">Create</button>
</Form>
```

Nested data, arrays, files, dotted keys all supported:
```tsx
<Form action="/reports" method="post" transform={(data) => ({ ...data, user_id: 123 })}>
  <textarea name="report[description]"></textarea>
  <input type="text" name="report[tags][]" />
  <input type="file" name="documents" multiple />
  <input type="text" name="user.name" />
</Form>
```

Escape dots for literal names: `name="app\.name"`.

## Inertia `<Form>` render props
React render props expose state and helpers:
- `errors`, `hasErrors`, `processing`, `progress`
- `wasSuccessful`, `recentlySuccessful`
- `setError`, `clearErrors`, `resetAndClearErrors`
- `defaults`, `isDirty`, `reset`, `submit`
- `validate`, `invalid`, `valid`, `validating` (Precognition only)

```tsx
<Form action="/users" method="post">
  {({ errors, processing, wasSuccessful }) => (
    <>
      <input name="name" />
      {errors.name && <div>{errors.name}</div>}
      <button disabled={processing}>Save</button>
      {wasSuccessful && <div>Saved</div>}
    </>
  )}
</Form>
```

## Inertia `<Form>` props worth knowing
- `action`, `method`
- `transform`
- `errorBag`, `queryStringArrayFormat`, `headers`, `showProgress`
- `disableWhileProcessing` (sets `inert` on the form)
- `resetOnSuccess`, `resetOnError`, `setDefaultsOnSuccess`
- `withAllErrors` (keep error arrays)
- `validationTimeout`, `validateFiles` (Precognition)
- `options` (visit options: `preserveScroll`, `preserveState`, `replace`, `only`, `except`, `reset`, `preserveUrl`)

## `useForm` helper (this app uses heavily)
```tsx
import { useForm } from "@inertiajs/react"

const form = useForm({
  email: "",
  password: "",
  remember: false,
})

form.post("/login", {
  preserveScroll: true,
  onSuccess: () => form.reset("password"),
})
```

Common helpers:
- `data`, `setData`, `processing`, `progress`, `errors`
- `hasErrors`, `isDirty`, `wasSuccessful`, `recentlySuccessful`
- `post/get/put/patch/delete`, `submit`
- `setError`, `clearErrors`, `reset`, `resetAndClearErrors`
- `transform`, `defaults`, `cancel`

## Remembering form state in history
```tsx
const form = useForm("LoginForm", { email: "", password: "" })
form.dontRemember("password")
```

## Server-side validation (Rails)
Re-render the page with `errors`, or redirect with `inertia: { errors: ... }`.

```ruby
# app/controllers/settings/profiles_controller.rb
if @user.update(user_params)
  redirect_to settings_profile_path, notice: "Your profile has been updated"
else
  redirect_to settings_profile_path, inertia: inertia_errors(@user)
end
```

```ruby
# app/controllers/lists_controller.rb
render inertia: "Lists/New", props: {
  list: { name: @list.name },
  errors: @list.errors
}
```

## Error shape notes (this app)
- `errorValueType` is `string[]` in `app/frontend/types/global.d.ts`.
- Some controllers pass string errors. Prefer `inertia_errors` to normalize.
- If using Inertia `<Form>` and you want arrays, pass `withAllErrors`.

## Precognition
Precognition is Laravel-specific. Not wired for this Rails app. Avoid unless we add protocol support.
