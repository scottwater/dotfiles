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
sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y \
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
  set +e
  source "$HOME/.zshrc" >/dev/null 2>&1
  set -e
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
