---
name: inertia-testing
description: "RSpec request testing for Inertia responses."
metadata:
  version: "2"
---

# Testing Inertia Responses (RSpec)

Use when adding or updating request specs for Inertia pages.

## RSpec setup (this app)
`spec/rails_helper.rb` already requires `inertia_rails/rspec`.

## Request spec pattern
```ruby
# spec/requests/lists_spec.rb
require "rails_helper"

RSpec.describe "Lists", type: :request do
  it "renders the Lists/Index component" do
    get lists_path

    expect(response).to have_http_status(:ok)
    expect(inertia.component).to eq("Lists/Index")
  end

  it "includes expected props" do
    list = create(:list)
    get lists_path

    expect(inertia.props[:lists]).to include(hash_including(id: list.id))
  end
end
```

## Error flow specs
When errors are sent via redirect, follow the redirect and then assert props.

```ruby
post settings_profile_path, params: { name: "" }
follow_redirect!
expect(inertia.props[:errors]).to be_present
```
