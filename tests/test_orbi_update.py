import contextlib
import fcntl
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "dot_local/bin/executable_orbi-update"
NAMESPACE = runpy.run_path(str(SOURCE))
main = NAMESPACE["main"]
update = NAMESPACE["update"]
GLOBALS = main.__globals__


class UpdaterTests(unittest.TestCase):
    def quiet(self):
        stack = contextlib.ExitStack()
        stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
        stack.enter_context(contextlib.redirect_stderr(io.StringIO()))
        return stack

    def test_dry_run_does_not_run_commands(self):
        with self.quiet(), patch.dict(GLOBALS, run=lambda *a, **k: self.fail("unexpected command")):
            self.assertEqual(main(["--dry-run"]), 0)

    def test_requires_confirmation(self):
        with self.quiet(), patch("sys.stdin.isatty", return_value=False):
            self.assertEqual(main([]), 1)

    def test_role_guard(self):
        with self.quiet(), patch.dict(GLOBALS, run=lambda *a, **k: '{"role":"workstation"}', update=lambda c: self.fail("updated wrong role")):
            self.assertEqual(main(["--yes"]), 1)

    def test_order_selection_and_lock(self):
        with tempfile.TemporaryDirectory() as temp, self.quiet(), patch.dict(os.environ, HOME=temp):
            steps = []
            with patch.dict(GLOBALS, run=lambda *a, **k: '{"role":"bb-worker"}', update=steps.append):
                self.assertEqual(main(["--yes", "--component", "herdr", "--component", "agents", "--component", "agents"]), 0)
                self.assertEqual(steps, ["agents", "herdr"])
                steps.clear()
                with (Path(temp) / ".local/state/orbi-update/lock").open("a") as lock:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    self.assertEqual(main(["--yes"]), 1)
                self.assertEqual(steps, [])

    def test_failure_stops_later_components(self):
        steps = []
        def fail(component):
            steps.append(component)
            raise RuntimeError("failed")
        with tempfile.TemporaryDirectory() as temp, self.quiet(), patch.dict(os.environ, HOME=temp), patch.dict(GLOBALS, run=lambda *a, **k: '{"role":"bb-worker"}', update=fail):
            self.assertEqual(main(["--yes"]), 1)
        self.assertEqual(steps, ["chezmoi"])

    def test_dirty_source_does_not_update(self):
        calls = []
        def run(*args, **kwargs):
            calls.append(args)
            return "source" if args[0] == "chezmoi" else " M file"
        with patch.dict(GLOBALS, run=run), self.assertRaisesRegex(RuntimeError, "local changes"):
            update("chezmoi")
        self.assertNotIn(("chezmoi", "update"), calls)

    def test_bb_checks_without_restarting(self):
        with tempfile.TemporaryDirectory() as temp, self.quiet(), patch.dict(os.environ, HOME=temp):
            unit = Path(temp) / ".config/systemd/user/bb-host-daemon-test.service"
            unit.parent.mkdir(parents=True)
            unit.write_text("ExecStart=bb-app host-daemon --auto-update\n")
            calls = []
            with patch.dict(GLOBALS, run=lambda *a, **k: calls.append(a)):
                update("bb")
            self.assertEqual(calls, [("systemctl", "--user", "is-active", unit.name)])

    def test_self_replacement_only_affects_next_invocation(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            script = home / "orbi-update"
            script.write_text(SOURCE.read_text())
            bin_dir = home / ".local/bin"
            bin_dir.mkdir(parents=True)
            tools = {
                "chezmoi": '''case "$1" in
 data) printf '%s' '{"role":"bb-worker"}' ;;
 source-path) printf '%s' "$HOME" ;;
 update) printf '%s\\n' 'raise RuntimeError("new invocation")' > "$HOME/orbi-update" ;;
esac''',
                "git": "exit 0",
                "mise": 'echo mise >> "$HOME/calls"',
                "herdr": 'echo herdr >> "$HOME/calls"',
            }
            for name, body in tools.items():
                path = bin_dir / name
                path.write_text("#!/bin/sh\n" + body + "\n")
                path.chmod(0o755)
            result = subprocess.run([sys.executable, str(script), "--yes", "--component", "chezmoi", "--component", "herdr"], env={**os.environ, "HOME": temp}, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((home / "calls").read_text(), "mise\nherdr\n")
            self.assertIn("new invocation", script.read_text())


if __name__ == "__main__":
    unittest.main()
