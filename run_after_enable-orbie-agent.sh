#!/usr/bin/env bash
# Start the Orbie fleet agent's five-minute timer: a systemd user timer on
# Linux, a LaunchAgent on macOS. Reruns on every apply so a reinstalled or
# changed unit takes effect. The agent itself is ~/.local/bin/orbie-agent.
set -euo pipefail

mkdir -p "$HOME/.cache/orbie"
case "$(uname -s)" in
  Linux)
    if ! command -v systemctl >/dev/null 2>&1; then
      echo "No systemctl; the Orbie agent timer is not enabled." >&2
      exit 0
    fi
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if ! systemctl --user daemon-reload 2>/dev/null; then
      echo "No systemd user session; the Orbie agent timer is not enabled." >&2
      exit 0
    fi
    systemctl --user enable --now orbie-agent.timer
    # A changed service file applies on the timer's next run; the timer
    # itself is restarted so a changed interval takes effect now.
    systemctl --user restart orbie-agent.timer
    systemctl --user is-active --quiet orbie-agent.timer && echo "Orbie agent timer active"
    ;;
  Darwin)
    plist="$HOME/Library/LaunchAgents/com.orbie.agent.plist"
    domain="gui/$(id -u)"
    if launchctl print "$domain/com.orbie.agent" >/dev/null 2>&1; then
      # Reloading from inside the agent's own apply-dotfiles job would boot
      # out the agent running this script, and the LaunchAgent would stay
      # unloaded. The loaded job keeps running; a changed plist takes effect
      # on the next apply from a terminal or at the next login.
      if [ -n "${ORBIE_AGENT_JOB:-}" ]; then
        echo "Orbie agent LaunchAgent already loaded (not reloaded from inside the agent)"
        exit 0
      fi
      launchctl bootout "$domain/com.orbie.agent" 2>/dev/null || true
    fi
    launchctl bootstrap "$domain" "$plist"
    echo "Orbie agent LaunchAgent loaded"
    ;;
esac
