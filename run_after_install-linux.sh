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
  trash-cli \
  wget \
  zsh 2>&1 | tee "$tmp_log"
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
