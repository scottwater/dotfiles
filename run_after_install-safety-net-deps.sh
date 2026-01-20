#!/bin/bash
# Install bun dependencies for safety-net

SAFETY_NET_DIR="$HOME/.config/safety-net"

if command -v bun &> /dev/null && [ -f "$SAFETY_NET_DIR/package.json" ]; then
  cd "$SAFETY_NET_DIR" && bun install --silent
fi
