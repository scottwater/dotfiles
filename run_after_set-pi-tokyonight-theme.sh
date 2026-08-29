#!/usr/bin/env bash
# Preserve Pi's user-managed settings while selecting the managed theme.
set -euo pipefail

settings="${HOME}/.pi/agent/settings.json"
if [ ! -f "${settings}" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Cannot set Pi theme: jq is unavailable." >&2
  exit 1
fi

if [ "$(jq -r '.theme // empty' "${settings}")" = "Tokyo Night" ]; then
  exit 0
fi

tmp="$(mktemp "${settings}.XXXXXX")"
trap 'trash "${tmp}" 2>/dev/null || true' EXIT
jq '.theme = "Tokyo Night"' "${settings}" > "${tmp}"
chmod 600 "${tmp}"
mv "${tmp}" "${settings}"
trap - EXIT
