#!/usr/bin/env bash
# Install the Pi coding agent as a standalone binary (no node/npm required).
#
# WHY THIS EXISTS:
# exe.dev VMs ship a preinstalled standalone Pi at ~/.local/pi with a
# root-owned ~/.local/bin/pi symlink. That copy is a frozen bun bundle that
# refuses `pi update self`, and it collides with user-managed pi packages.
# This script takes ownership: it drops a user-owned standalone build in the
# same location and repoints the symlink, giving a normal, updatable install.
#
# Idempotent + non-interactive. chezmoi re-runs it whenever this file's hash
# changes, so bumping PI_VERSION below triggers an upgrade on next apply.
#
# Scoped to exe.dev VMs only (see guard below) — other machines don't have
# the conflicting preinstall, so we leave their pi management alone.
set -euo pipefail

# --- exe.dev guard -----------------------------------------------------------
# The SHELLEY_* env vars only exist inside the agent runtime, not in a plain
# `chezmoi apply` shell, so detect via the durable root-owned agent binary.
if [ ! -x /usr/local/bin/shelley ] && [ ! -d /headless-shell ]; then
  echo "Not an exe.dev VM; skipping Pi standalone install."
  exit 0
fi

PI_VERSION="0.78.1"           # pin; set to "latest" to always track newest
PREFIX="${HOME}/.local"
BIN="${PREFIX}/bin/pi"
DEST="${PREFIX}/pi"

# --- arch detection ----------------------------------------------------------
case "$(uname -m)" in
  x86_64)        arch=x64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac
asset="pi-linux-${arch}.tar.gz"

# --- skip if already at desired version --------------------------------------
if [ "${PI_VERSION}" != "latest" ] && [ -x "${DEST}/pi" ]; then
  cur="$("${DEST}/pi" --version 2>/dev/null | tail -1 | tr -d '[:space:]' || true)"
  if [ "${cur}" = "${PI_VERSION}" ] && [ "$(readlink -f "${BIN}" 2>/dev/null)" = "${DEST}/pi" ]; then
    echo "pi ${PI_VERSION} already installed."
    exit 0
  fi
fi

# --- download + extract ------------------------------------------------------
if [ "${PI_VERSION}" = "latest" ]; then
  url="https://github.com/earendil-works/pi/releases/latest/download/${asset}"
else
  url="https://github.com/earendil-works/pi/releases/download/v${PI_VERSION}/${asset}"
fi
tmp="$(mktemp -d)"; trap 'rm -rf "${tmp}"' EXIT
echo "Downloading pi ${PI_VERSION} (${asset})..."
curl -fsSL "${url}" -o "${tmp}/pi.tar.gz"
tar xzf "${tmp}/pi.tar.gz" -C "${tmp}"          # extracts to ${tmp}/pi/

# --- swap into place ---------------------------------------------------------
mkdir -p "${PREFIX}/bin"
rm -rf "${DEST}.new"
mv "${tmp}/pi" "${DEST}.new"
rm -rf "${DEST}.old"
[ -e "${DEST}" ] && mv "${DEST}" "${DEST}.old" || true
mv "${DEST}.new" "${DEST}"
rm -rf "${DEST}.old"

# --- (re)create command symlink ----------------------------------------------
# Replaces the preinstalled root-owned symlink; works without sudo because the
# parent directory (~/.local/bin) is user-owned.
ln -sfn "${DEST}/pi" "${BIN}"

# --- remove stray npm-based install from earlier attempts (best effort) ------
if command -v npm >/dev/null 2>&1; then
  npm ls -g --depth=0 @earendil-works/pi-coding-agent >/dev/null 2>&1 \
    && npm uninstall -g @earendil-works/pi-coding-agent >/dev/null 2>&1 || true
fi

echo "pi $("${DEST}/pi" --version 2>/dev/null | tail -1) installed at ${DEST}, linked from ${BIN}."
