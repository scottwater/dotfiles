#!/bin/bash
# Optional Dracula Pro compatibility hook. Disabled while Tokyo Night Dark is active.

if [ "${DRACULA_PRO_THEMES_ENABLED:-0}" != "1" ]; then
    exit 0
fi

DRACULA_REPO="$HOME/.config/nvim/dracula_pro"

# Zed themes
if [ -d "$DRACULA_REPO/zed-themes" ]; then
    mkdir -p "$HOME/.config/zed/themes"
    cp "$DRACULA_REPO/zed-themes/"*.json "$HOME/.config/zed/themes/" 2>/dev/null
fi
