#!/bin/bash
# Rebuild bat's theme cache for managed and optional custom themes.

if command -v bat &> /dev/null; then
    bat cache --build > /dev/null 2>&1
fi
