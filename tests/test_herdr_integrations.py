"""Exercise local integration installers in a temporary home, never live settings."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest


@unittest.skipUnless(shutil.which("herdr"), "herdr is required for isolated integration checks")
class HerdrIntegrationTests(unittest.TestCase):
    def test_install_is_repeatable_and_preserves_unrelated_settings(self):
        binary = shutil.which("herdr")
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            # Integration commands edit files locally, without a Herdr server.
            # Remove inherited session routing and override all agent paths.
            env = {k: v for k, v in os.environ.items() if not k.startswith("HERDR_")}
            env.update(HOME=temp, XDG_CONFIG_HOME=str(home / ".config"),
                       HERDR_CONFIG_PATH=str(home / ".config/herdr/config.toml"),
                       PI_CODING_AGENT_DIR=str(home / ".pi/agent"),
                       CLAUDE_CONFIG_DIR=str(home / ".claude"), CODEX_HOME=str(home / ".codex"))
            for directory in (".pi/agent", ".claude", ".codex"):
                (home / directory).mkdir(parents=True)
            hooks = {"SessionStart": [{"hooks": [{"type": "command", "command": "echo keep"}]}]}
            settings = {"permissions": {"allow": ["Read"]}, "hooks": hooks}
            (home / ".claude/settings.json").write_text(json.dumps(settings))
            (home / ".codex/hooks.json").write_text(json.dumps({"hooks": hooks}))
            (home / ".codex/config.toml").write_text('model = "keep-model"\n[features]\nexisting = true\n')
            (home / ".pi/agent/settings.json").write_text('{"theme":"keep-theme"}')
            snapshots = []
            for _ in range(2):
                for agent in ("pi", "claude", "codex"):
                    subprocess.run([binary, "integration", "install", agent], env=env,
                                   text=True, capture_output=True, check=True, timeout=20)
                snapshots.append({str(p.relative_to(home)): p.read_bytes()
                                  for p in home.rglob("*") if p.is_file()})
            self.assertEqual(snapshots[0], snapshots[1])
            claude = json.loads((home / ".claude/settings.json").read_text())
            self.assertEqual(claude["permissions"], settings["permissions"])
            self.assertIn("echo keep", json.dumps(claude["hooks"]))
            codex = tomllib.loads((home / ".codex/config.toml").read_text())
            self.assertEqual(codex["model"], "keep-model")
            self.assertTrue(codex["features"]["existing"])
            self.assertIn("echo keep", (home / ".codex/hooks.json").read_text())
            self.assertEqual((home / ".pi/agent/settings.json").read_text(), '{"theme":"keep-theme"}')
            status = subprocess.run([binary, "integration", "status"], env=env, text=True,
                                    capture_output=True, check=True, timeout=20).stdout
            for agent in ("pi", "claude", "codex"):
                self.assertRegex(status, rf"(?m)^{agent}: current\b")
            self.assertRegex(status, r"(?m)^opencode: not installed\b")


if __name__ == "__main__":
    unittest.main()
