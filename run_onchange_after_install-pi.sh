#!/usr/bin/env bash
# Replace exe.dev's bundled Pi binary with a user-managed npm installation.
#
# exe.dev's preinstall and Pi's GitHub release archives are Bun-compiled
# binaries. Their code runs from /$bunfs, so Pi intentionally cannot determine
# a package-manager install to update. Installing under ~/.local with npm gives
# Pi a stable, writable prefix and lets `pi update` update itself normally.
#
# This is an initial bootstrap, not the ongoing updater. Chezmoi runs it again
# only when this file changes; after that, use `pi update`.
set -euo pipefail

# The SHELLEY_* variables are not available in every shell on an exe.dev VM,
# so use durable files from the VM image for detection.
if [ ! -x /usr/local/bin/shelley ] && [ ! -d /headless-shell ]; then
  echo "Not an exe.dev VM; skipping Pi npm bootstrap."
  exit 0
fi

PREFIX="${HOME}/.local"
BIN="${PREFIX}/bin/pi"
STANDALONE_DIR="${PREFIX}/pi"
PACKAGE="@earendil-works/pi-coding-agent"

# install-core runs earlier in Chezmoi's after phase and provisions Node.
# Run mise by absolute path because separate Chezmoi scripts do not share PATH changes.
if command -v npm >/dev/null 2>&1; then
  npm_command=(npm)
elif command -v mise >/dev/null 2>&1; then
  npm_command=(mise exec node -- npm)
elif [ -x "${HOME}/.local/bin/mise" ]; then
  npm_command=("${HOME}/.local/bin/mise" exec node -- npm)
else
  echo "Cannot install Pi: npm and mise are unavailable." >&2
  exit 1
fi

mkdir -p "${PREFIX}/bin"

# npm refuses to overwrite exe.dev's existing Pi symlink. Preserve it until
# the npm install succeeds so a network or registry failure does not remove Pi.
backup=""
if [ -e "${BIN}" ] || [ -L "${BIN}" ]; then
  backup="$(mktemp "${PREFIX}/bin/.pi.pre-npm.XXXXXX")"
  rm -f "${backup}"
  mv "${BIN}" "${backup}"
fi

restore_previous_pi() {
  status=$?
  if [ "${status}" -ne 0 ]; then
    rm -f "${BIN}"
    if [ -n "${backup}" ]; then
      mv "${backup}" "${BIN}"
      backup=""
    fi
  fi
  [ -z "${backup}" ] || rm -f "${backup}"
  exit "${status}"
}
trap restore_previous_pi EXIT

echo "Installing the latest Pi with npm under ${PREFIX}..."
"${npm_command[@]}" --prefix "${PREFIX}" install -g --ignore-scripts --min-release-age=0 "${PACKAGE}"

# The npm-managed executable now lives in ~/.local/bin and the old standalone
# archive is no longer needed.
rm -rf "${STANDALONE_DIR}"

echo "pi $(PATH="${PREFIX}/bin:${PATH}" "${BIN}" --version 2>/dev/null | tail -1) installed; future updates can use 'pi update'."
