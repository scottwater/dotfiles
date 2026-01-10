#!/bin/bash
# Rebuild bat's theme cache after installing custom themes

if command -v bat &> /dev/null; then
    bat cache --build > /dev/null 2>&1
fi
