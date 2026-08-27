#!/usr/bin/env bash
set -euo pipefail

if [ "${CHEZMOI_OS:-}" != "linux" ] && [ "${CHEZMOI_OS:-}" != "darwin" ]; then
  echo "Unsupported OS: ${CHEZMOI_OS:-unknown}" >&2
  exit 1
fi

# chezmoi run scripts do not execute inside your interactive shell, so make sure
# we can detect tools installed into user-local locations on repeat applies.
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.atuin/bin:$PATH"

has_command() {
  command -v "$1" >/dev/null 2>&1
}

install_atuin() {
  if ! has_command atuin; then
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive
  elif ! atuin doctor >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive
  fi
}

install_mise() {
  if ! has_command mise; then
    curl https://mise.run | sh
  fi
}

install_mise_runtimes() {
  if ! has_command mise; then
    return
  fi

  local missing_runtimes=()

  if ! node -v >/dev/null 2>&1; then
    missing_runtimes+=("node@24")
  fi

  if ! ruby -v >/dev/null 2>&1; then
    # Use precompiled Ruby binaries when available, falling back to ruby-build only
    # when mise cannot find a matching binary for the platform/version.
    mise settings ruby.compile=false
    missing_runtimes+=("ruby@latest")
  fi

  if [ "${#missing_runtimes[@]}" -gt 0 ]; then
    mise use -g --pin -y "${missing_runtimes[@]}"
  fi
}

install_uv() {
  if ! has_command uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
}

# Homebrew is macOS-only: casks and a few libs (libpq etc). Linux gets
# everything from mise + apt.
install_homebrew() {
  if [ "${CHEZMOI_OS:-}" != "darwin" ]; then
    return
  fi

  if has_command brew; then
    return
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Install all tools declared in ~/.config/mise/config.toml (chezmoi-managed).
install_mise_tools() {
  if has_command mise; then
    mise install -y
  fi
}

install_fnox() {
  if ! has_command mise; then
    return
  fi

  if ! mise registry fnox >/dev/null 2>&1; then
    mise self-update -y || true
  fi

  if mise registry fnox >/dev/null 2>&1; then
    mise use -g fnox
  else
    mise use -g --remove fnox || true
    mise use -g github:jdx/fnox
  fi
}

install_herdr() {
  if ! has_command mise; then
    return
  fi

  if ! mise registry herdr >/dev/null 2>&1; then
    mise self-update -y || true
  fi

  if mise registry herdr >/dev/null 2>&1; then
    mise use -g herdr
    # "latest" is resolved once at install; herdr self-updates, so a stale
    # mise-pinned version can lag behind. Force it forward on every run.
    mise upgrade herdr || true
  else
    mise use -g --remove herdr || true
    mise use -g github:ogulcancelik/herdr
  fi
}

install_atuin
install_mise
install_mise_runtimes
install_mise_tools
install_uv
install_homebrew
install_fnox
install_herdr
