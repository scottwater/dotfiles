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
  libyaml-dev \
  libffi-dev \
  neovim \
  poppler-utils \
  ripgrep \
  tmux \
  wget \
  zsh \
  zsh-syntax-highlighting

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

if [ "$SHELL" != "$(which zsh)" ]; then
  sudo chsh -s "$(which zsh)" "$USER"
fi

if [ -f "$HOME/.zshrc" ]; then
  # Ensure brew is on PATH without showing shell output.
  # shellcheck disable=SC1090
  source "$HOME/.zshrc" >/dev/null 2>&1
fi

if command -v brew >/dev/null 2>&1; then
  brew bundle
else
  echo "Homebrew not on PATH yet. Remember to run: brew bundle" >&2
fi
