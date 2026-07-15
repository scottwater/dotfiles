#!/usr/bin/env bash
# Install destructive_command_guard and configure detected coding-agent hooks on macOS.
# Bump DCG_VERSION to trigger an upgrade on the next chezmoi apply.
set -euo pipefail

if [ "${CHEZMOI_OS:-}" != "darwin" ]; then
  exit 0
fi

DCG_VERSION="v0.6.7"
INSTALLER_URL="https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/${DCG_VERSION}/install.sh"

curl --proto '=https' --tlsv1.2 -fsSL "$INSTALLER_URL" |
  bash -s -- --version "$DCG_VERSION" --force --verify
