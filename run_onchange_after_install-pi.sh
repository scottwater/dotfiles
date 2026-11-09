#!/usr/bin/env bash
# Install the three coding harnesses used on every development machine.
#
# Pi uses its managed installer and Codex is installed into ~/.local through
# npm, so their executables are user-owned and take precedence over exe.dev's
# bundled binaries. Claude Code uses exe.dev's supported updater there, its own
# updater when already present, and the upstream installer as a fresh-install
# fallback.
#
# This is bootstrap logic. Ongoing manual updates use update-ai-tools.
set -euo pipefail

PREFIX="${HOME}/.local"
export PATH="${PREFIX}/bin:${HOME}/.local/share/mise/shims:${PATH}"

HARNESS_BIN="${PREFIX}/bin"
if command -v npm >/dev/null 2>&1; then
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

# Workstations use Pi's managed installer, which pins dependencies. Remove any
# plain npm copy first so the installer can claim ~/.local/bin/pi. Copies left
# under older mise node versions keep a dead pi shim ahead of ~/.local/bin, so
# remove those too. The installer prompts through /dev/tty, which piping cannot
# silence; a new session without a controlling terminal makes it use defaults.
install_managed_pi() (
  set -o pipefail
  for node_bin in "$HOME"/.local/share/mise/installs/node/*/bin; do
    if [ -e "$node_bin/pi" ]; then
      env "PATH=$node_bin:$PATH" "$node_bin/npm" uninstall -g @earendil-works/pi-coding-agent || exit
    fi
  done
  if command -v mise >/dev/null 2>&1; then
    mise reshim
  fi
  "${npm_command[@]}" --prefix "${PREFIX}" uninstall -g @earendil-works/pi-coding-agent &&
    curl -fsSL https://pi.dev/install.sh | perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' sh
)

if [ ! -f "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/install/managed-install.json" ]; then
  install_managed_pi
fi
rm -rf "${PREFIX}/pi"

install_npm_harness \
  "Codex" \
  "codex" \
  "@openai/codex" \
  --include=optional

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

# Managed Pi package URLs are already present in settings.json when after
# scripts run. Fetch/update those extensions now so a fresh machine is ready.
"${HARNESS_BIN}/pi" update --all

printf 'Installed coding harnesses:\n'
printf '  %s\n' "$("${HARNESS_BIN}/pi" --version 2>/dev/null | tail -1)"
printf '  %s\n' "$("${HARNESS_BIN}/codex" --version 2>/dev/null | tail -1)"
printf '  %s\n' "$(claude --version 2>/dev/null | tail -1)"
