"""The Pi settings modify template, applied into a temporary home only; it
never touches live settings."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHEZMOI = shutil.which("chezmoi")
PI_SETTINGS = ROOT / "dot_pi/private_agent/modify_private_settings.json"


class PiSettingsTemplateTests(unittest.TestCase):
    def render(self, current=None):
        """Apply the template into a temporary home and return the result. A
        real apply, not execute-template, so the modify template sees the file
        already there as .chezmoi.stdin."""
        if not CHEZMOI:
            self.skipTest("chezmoi is required for template rendering")
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp) / "home"
            target = home / ".pi/agent/settings.json"
            target.parent.mkdir(parents=True)
            if current is not None:
                target.write_text(json.dumps(current))
            source = Path(temp) / "source" / PI_SETTINGS.parent.relative_to(ROOT)
            source.mkdir(parents=True)
            shutil.copy(PI_SETTINGS, source / PI_SETTINGS.name)
            config = Path(temp) / "chezmoi.toml"
            config.write_text("")
            subprocess.run(
                [CHEZMOI, "--config", str(config), "--source", str(Path(temp) / "source"),
                 "--destination", str(home), "--persistent-state", str(Path(temp) / "state.boltdb"),
                 "--override-data", json.dumps({"chezmoi": {"homeDir": str(home)}}), "apply"],
                text=True, capture_output=True, check=True,
            )
            return json.loads(target.read_text())

    def test_a_new_machine_gets_its_own_providers(self):
        settings = self.render()
        self.assertEqual(settings["defaultProvider"], "openai-codex")
        self.assertIn("openai-codex/gpt-6-astra", settings["enabledModels"])
        self.assertEqual(settings["defaultModel"], "gpt-6-astra")
        self.assertEqual(settings["lastChangelogVersion"], "1.3.0")

    def test_the_fleet_clients_provider_choice_is_kept(self):
        # orbie-configure-gateway writes these on machines enrolled with the
        # fleet gateway; an apply must not put the direct providers back.
        current = {"defaultProvider": "fleet-codex", "enabledModels": ["fleet-codex/*", "fleet/**"]}
        settings = self.render(current)
        self.assertEqual(settings["defaultProvider"], "fleet-codex")
        self.assertEqual(settings["enabledModels"], ["fleet-codex/*", "fleet/**"])
        self.assertEqual(settings["theme"], "Tokyo Night")

    def test_the_changelog_version_pi_wrote_is_kept(self):
        settings = self.render({"lastChangelogVersion": "9.9.9"})
        self.assertEqual(settings["lastChangelogVersion"], "9.9.9")
        self.assertEqual(settings["defaultProvider"], "openai-codex")


if __name__ == "__main__":
    unittest.main()
