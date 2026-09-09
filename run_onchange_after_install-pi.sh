#!/usr/bin/env bash
# Install the three coding harnesses used on every development machine.
#
# Pi and Codex are installed into ~/.local through npm so their executables are
# user-owned and take precedence over exe.dev's bundled binaries. Claude Code
# uses exe.dev's supported updater there, its own updater when already present,
# and the upstream installer as a fresh-install fallback.
#
# BB workers instead use an isolated prefix and a dedicated tooling Node.
# This is bootstrap logic. Ongoing manual updates use update-ai-tools.
set -euo pipefail

PREFIX="${HOME}/.local"
export PATH="${PREFIX}/bin:${HOME}/.local/share/mise/shims:${PATH}"

CHEZMOI_ROLE="workstation"
if command -v chezmoi >/dev/null 2>&1; then
  CHEZMOI_ROLE="$(chezmoi execute-template '{{ get . "role" | default "workstation" }}')" || exit 1
fi

HARNESS_BIN="${PREFIX}/bin"
if [ "$CHEZMOI_ROLE" = "bb-worker" ]; then
  PREFIX="$HOME/.local/share/orbi/agents"
  TOOLING_BIN="$HOME/.local/share/orbi/tooling-node/bin"
  # mise wraps bin/npm in Bash for reshim; Node must execute npm's JS entry.
  npm_command=(env "PATH=$TOOLING_BIN:$PATH" "$TOOLING_BIN/node" "$TOOLING_BIN/../lib/node_modules/npm/bin/npm-cli.js")
elif command -v npm >/dev/null 2>&1; then
  npm_command=(npm)
elif command -v mise >/dev/null 2>&1; then
  npm_command=(mise exec node -- npm)
elif [ -x "${HOME}/.local/bin/mise" ]; then
  npm_command=("${HOME}/.local/bin/mise" exec node -- npm)
else
  echo "Cannot install coding harnesses: npm and mise are unavailable." >&2
  exit 1
fi

mkdir -p "${PREFIX}/bin" "${HARNESS_BIN}"

install_npm_harness() {
  local name="$1"
  local executable="$2"
  local package="$3"
  shift 3

  local bin="${PREFIX}/bin/${executable}"
  local backup=""
  if [ -e "${bin}" ] || [ -L "${bin}" ]; then
    backup="$(mktemp "${PREFIX}/bin/.${executable}.pre-npm.XXXXXX")"
    rm -f "${backup}"
    mv "${bin}" "${backup}"
  fi

  echo "Installing the latest ${name} under ${PREFIX}..."
  if "${npm_command[@]}" --prefix "${PREFIX}" install -g "$@" "${package}"; then
    [ -z "${backup}" ] || rm -f "${backup}"
    return 0
  else
    local status=$?
    rm -f "${bin}"
    if [ -n "${backup}" ]; then
      mv "${backup}" "${bin}"
    fi
    return "${status}"
  fi
}

install_npm_harness \
  "Pi" \
  "pi" \
  "@earendil-works/pi-coding-agent" \
  --ignore-scripts \
  --min-release-age=0
rm -rf "${PREFIX}/pi"

install_npm_harness \
  "Codex" \
  "codex" \
  "@openai/codex"

install_claude() {
  if command -v exeuntu >/dev/null 2>&1; then
    echo "Updating Claude Code through exeuntu..."
    sudo exeuntu update claude
    return
  fi

  if command -v claude >/dev/null 2>&1 && claude update; then
    return
  fi

  echo "Installing Claude Code with the upstream installer..."
  curl --proto '=https' --tlsv1.2 -fsSL https://claude.ai/install.sh | bash
}

install_claude

if [ "$CHEZMOI_ROLE" = "bb-worker" ]; then
  for executable in pi codex; do
    # Remove old npm symlinks before writing; never overwrite their targets.
    rm -f "${HARNESS_BIN}/${executable}"
    cat > "${HARNESS_BIN}/${executable}" <<EOF
#!/usr/bin/env bash
exec "\$HOME/.local/share/orbi/tooling-node/bin/node" "\$HOME/.local/share/orbi/agents/bin/${executable}" "\$@"
EOF
    chmod +x "${HARNESS_BIN}/${executable}"
  done
fi

# Managed Pi package URLs are already present in settings.json when after
# scripts run. Fetch/update those extensions now so a fresh machine is ready.
if [ "$CHEZMOI_ROLE" = "bb-worker" ]; then
  env "PATH=$TOOLING_BIN:$PATH" "${HARNESS_BIN}/pi" update --all
else
  "${HARNESS_BIN}/pi" update --all
fi

printf 'Installed coding harnesses:\n'
printf '  %s\n' "$("${HARNESS_BIN}/pi" --version 2>/dev/null | tail -1)"
printf '  %s\n' "$("${HARNESS_BIN}/codex" --version 2>/dev/null | tail -1)"
printf '  %s\n' "$(claude --version 2>/dev/null | tail -1)"
