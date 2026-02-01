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
sudo apt-get install -y \
  bat \
  fd-find \
  fzf \
  git \
  jq \
  lazygit \
  neovim \
  poppler-utils \
  ripgrep \
  tmux \
  wget \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
