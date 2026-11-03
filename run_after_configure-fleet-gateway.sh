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
# fleetd, which serves the fleet's model list; the same port the agent uses.
fleet="${ORBIE_FLEET_URL:-$url:9443}"
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
# The catalog URL replaces Codex's model discovery, so it lists the fleet's
# model list rather than everything the gateway advertises.
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
  printf '\n[model_providers.fleet]\nname = "Orbie fleet gateway"\nbase_url = "%s/v1"\nwire_api = "responses"\nauth = { command = "%s" }\nmodel_catalog_url = "%s/catalogs/codex.json"\n' "$url" "$helper" "$fleet"
} >"$config.new"
mv "$config.new" "$config"

# Pi: gateway providers from the fleet's model list. fleetd serves the two
# providers with their models and limits; the URL and key command are this
# machine's. The Codex models need the Responses API, everything else chat
# completions. No Claude provider: the gateway serves claude-* from the
# Claude subscription logins, which Anthropic's terms reserve for Claude
# Code, and OpenCode Go has no Claude models. settings.json (managed by
# chezmoi) selects these providers when proxy.env exists. When fleetd does
# not answer, an existing models.json is kept, and a machine without one
# gets the fixed list below.
pi_models="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/models.json"
if catalog=$(curl -fsS --max-time 10 "$fleet/catalogs/pi.json") && [ -n "$catalog" ]; then
  jq --arg url "$url" --arg key "!$helper" '
    {
      "$schema": "https://pi.dev/schemas/models.schema.json",
      providers: (.providers | with_entries(.value += {
        name: (if .key == "fleet-codex" then "Orbie fleet (Codex)" else "Orbie fleet" end),
        baseUrl: ($url + "/v1"), apiKey: $key}))
    }' <<<"$catalog" >"$pi_models.new"
  mv "$pi_models.new" "$pi_models"
elif [ -s "$pi_models" ]; then
  echo "fleetd did not answer at $fleet; Pi keeps its current model list" >&2
else
  echo "fleetd did not answer at $fleet; Pi gets the fixed model list" >&2
  jq -n --arg url "$url" --arg key "!$helper" '
    def big($id): {id: $id, reasoning: true, input: ["text", "image"], contextWindow: 400000, maxTokens: 128000};
    def chat($id; $context): {id: $id, reasoning: true, contextWindow: $context};
    {
      "$schema": "https://pi.dev/schemas/models.schema.json",
      providers: {
        "fleet-codex": {
          name: "Orbie fleet (Codex)", baseUrl: ($url + "/v1"), api: "openai-responses", apiKey: $key,
          models: [big("gpt-6-astra"), big("gpt-6.1-sol"), big("gpt-6-luna")]
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
    }' >"$pi_models"
fi

echo "Coding agents use the fleet gateway at $url"
