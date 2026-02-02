#!/usr/bin/env bash
set -euo pipefail

if [ "${CHEZMOI_OS:-}" != "linux" ] && [ "${CHEZMOI_OS:-}" != "darwin" ]; then
  echo "Unsupported OS: ${CHEZMOI_OS:-unknown}" >&2
  exit 1
fi

has_command() {
  command -v "$1" >/dev/null 2>&1
}

install_atuin() {
  if ! has_command atuin; then
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  fi
}

install_mise() {
  if ! has_command mise; then
    curl https://mise.run | sh
  fi
}

install_amp() {
  if ! has_command amp; then
    curl -fsSL https://ampcode.com/install.sh | bash
  fi
}

install_opencode() {
  if ! has_command opencode; then
    curl -fsSL https://opencode.ai/install | bash
  fi
}

install_uv() {
  if ! has_command uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
}

install_homebrew() {
  if has_command brew; then
    return
  fi

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ "${CHEZMOI_OS:-}" = "linux" ] && [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_atuin
install_mise
install_amp
install_opencode
install_uv
install_homebrew

if has_command mise; then
  mise use -g fnox
fi
