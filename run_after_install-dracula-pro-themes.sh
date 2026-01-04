#!/bin/bash
# Copy Dracula Pro themes from the nvim repo to other app theme directories

DRACULA_REPO="$HOME/.config/nvim/dracula_pro"

# OpenCode themes
if [ -d "$DRACULA_REPO/opencode-themes" ]; then
    mkdir -p "$HOME/.config/opencode/themes"
    cp "$DRACULA_REPO/opencode-themes/"*.json "$HOME/.config/opencode/themes/" 2>/dev/null
fi

# Zed themes
if [ -d "$DRACULA_REPO/zed-themes" ]; then
    mkdir -p "$HOME/.config/zed/themes"
    cp "$DRACULA_REPO/zed-themes/"*.json "$HOME/.config/zed/themes/" 2>/dev/null
fi
