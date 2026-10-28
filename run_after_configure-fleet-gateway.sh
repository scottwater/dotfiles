#!/usr/bin/env bash
# Point the coding agents at the fleet gateway on machines enrolled with it.
# Enrolment is ~/.config/orbie/proxy.env, written by `orbie` (see
# fleet/design.md in the orbie repository). Machines without it keep their own
# logins. Reruns on every apply so an updated gateway URL or key takes effect.
set -euo pipefail

env_file="$HOME/.config/orbie/proxy.env"
[ -f "$env_file" ] || exit 0

helper="$HOME/.local/bin/orbie-gateway-key"
url=$(sed -n 's/^ORBIE_GATEWAY_URL=//p' "$env_file")
url=${url%/}
[ -n "$url" ] || { echo "proxy.env has no ORBIE_GATEWAY_URL" >&2; exit 1; }
[ -x "$helper" ] && [ -n "$("$helper")" ] || { echo "proxy.env has no ORBIE_GATEWAY_KEY" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required to configure the fleet gateway" >&2; exit 1; }
umask 077
mkdir -p "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" "${CODEX_HOME:-$HOME/.codex}" "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

# Claude Code: base URL in settings, key from the helper (sent as x-api-key,
# which the gateway accepts). The helper outranks a claude.ai login.
settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
[ -s "$settings" ] || echo '{}' >"$settings"
jq --arg u "$url" --arg h "$helper" '
  .env = ((.env // {}) + {ANTHROPIC_BASE_URL: $u} | del(.ANTHROPIC_AUTH_TOKEN))
  | .apiKeyHelper = $h' "$settings" >"$settings.new"
mv "$settings.new" "$settings"

# Codex: a custom provider with a command-backed token. The top-level selector
# must precede the first table, since TOML scopes later keys to that table.
config="${CODEX_HOME:-$HOME/.codex}/config.toml"
touch "$config"
{
  echo 'model_provider = "fleet"'
  awk '
    /^model_provider = "fleet"$/ {next}
    /^\[model_providers\.fleet\]$/ {skip = 1; next}
    skip && /^\[/ {skip = 0}
    !skip {print}
  ' "$config"
  printf '\n[model_providers.fleet]\nname = "Orbie fleet gateway"\nbase_url = "%s/v1"\nwire_api = "responses"\nauth = { command = "%s" }\n' "$url" "$helper"
} >"$config.new"
mv "$config.new" "$config"

# Pi: gateway providers. The Codex models need the Responses API, Claude the
# Messages API, everything else chat completions. settings.json (managed by
# chezmoi) selects these providers when proxy.env exists.
jq -n --arg url "$url" --arg key "!$helper" '
  def big($id): {id: $id, reasoning: true, input: ["text", "image"], contextWindow: 400000, maxTokens: 128000};
  def claude($id): {id: $id, reasoning: true, input: ["text", "image"], contextWindow: 1000000, maxTokens: 64000};
  def chat($id; $context): {id: $id, reasoning: true, contextWindow: $context};
  {
    "$schema": "https://pi.dev/schemas/models.schema.json",
    providers: {
      "fleet-codex": {
        name: "Orbie fleet (Codex)", baseUrl: ($url + "/v1"), api: "openai-responses", apiKey: $key,
        models: [big("gpt-6-astra"), big("gpt-6.1-sol"), big("gpt-6-luna")]
      },
      "fleet-claude": {
        name: "Orbie fleet (Claude)", baseUrl: $url, api: "anthropic-messages", apiKey: $key,
        models: [claude("claude-opus-5-5"), claude("claude-sonnet-5-5"), claude("claude-fable-5-1")]
      },
      "fleet": {
        name: "Orbie fleet", baseUrl: ($url + "/v1"), api: "openai-completions", apiKey: $key,
        models: [
          chat("go/glm-5.3"; 200000), chat("go/glm-5.3-flash"; 200000),
          chat("go/kimi-k3"; 256000), chat("go/kimi-k3.1-pro"; 256000),
          chat("go/minimax-m3.1-flash"; 200000), chat("go/deepseek-v4.1-flash"; 128000),
          chat("grok-4.7"; 256000), chat("muse-spark-1.3"; 128000)
        ]
      }
    }
  }' >"${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/models.json"

echo "Coding agents use the fleet gateway at $url"
