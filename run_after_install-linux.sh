#!/usr/bin/env bash
set -euo pipefail

if [ "${CHEZMOI_OS:-}" != "linux" ]; then
  exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "apt-get not available. Skipping Linux package installs." >&2
  exit 0
fi
sudo apt-get update
tmp_log="$(mktemp)"
trap 'rm -f "$tmp_log"' EXIT
set +e
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  -o DPkg::Post-Invoke::= \
  -o DPkg::Post-Invoke-Success::= \
  -o APT::Update::Post-Invoke::= \
  -o APT::Update::Post-Invoke-Success::= \
  bat \
  fd-find \
  fzf \
  git \
  jq \
  libyaml-dev \
  libffi-dev \
  neovim \
  poppler-utils \
  ripgrep \
  tmux \
  wget \
  zsh \
  zsh-syntax-highlighting 2>&1 | tee "$tmp_log"
apt_status=${PIPESTATUS[0]}
set -e
if [ "$apt_status" -ne 0 ]; then
  if grep -Fq "Failed to retrieve available kernel versions." "$tmp_log"; then
    echo "needrestart failed to read kernel versions; continuing." >&2
  else
    exit "$apt_status"
  fi
fi

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

if [ "$SHELL" != "$(which zsh)" ]; then
  sudo chsh -s "$(which zsh)" "$USER"
fi

brew_cmd=""
if command -v brew >/dev/null 2>&1; then
  brew_cmd="brew"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  brew_cmd="/home/linuxbrew/.linuxbrew/bin/brew"
elif [ -x /opt/homebrew/bin/brew ]; then
  brew_cmd="/opt/homebrew/bin/brew"
elif [ -x /usr/local/bin/brew ]; then
  brew_cmd="/usr/local/bin/brew"
fi

if [ -n "$brew_cmd" ]; then
  "$brew_cmd" bundle
else
  echo "Homebrew not on PATH yet. Remember to run: brew bundle" >&2
fi
