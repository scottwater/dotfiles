"""The fleet gateway hook and the Pi settings template, run against a
temporary home only; they never touch live settings."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHEZMOI = shutil.which("chezmoi")
HOOK = (ROOT / "run_after_configure-fleet-gateway.sh").read_text()
HELPER = (ROOT / "dot_local/bin/executable_orbie-gateway-key").read_text()
PI_SETTINGS = (ROOT / "dot_pi/private_agent/private_settings.json.tmpl").read_text()
URL = "https://fleet.example.ts.net"
KEY = "w1-0123456789abcdef0123456789abcdef"


class FleetGatewayHookTests(unittest.TestCase):
    def setUp(self):
        if not shutil.which("jq"):
            self.skipTest("jq is required by the hook")
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        helper = self.home / ".local/bin/orbie-gateway-key"
        helper.parent.mkdir(parents=True)
        helper.write_text(HELPER)
        helper.chmod(0o700)
        self.env = {**os.environ, "HOME": str(self.home)}

    def tearDown(self):
        self.temp.cleanup()

    def enrol(self, key=KEY):
        (self.home / ".config/orbie").mkdir(parents=True, exist_ok=True)
        (self.home / ".config/orbie/proxy.env").write_text(f"ORBIE_GATEWAY_URL={URL}/\nORBIE_GATEWAY_KEY={key}\nORBIE_MACHINE=w1\n")

    def run_hook(self, check=True):
        return subprocess.run(["bash"], input=HOOK, env=self.env, text=True, capture_output=True, check=check)

    def test_a_machine_without_proxy_env_is_left_alone(self):
        self.run_hook()
        self.assertFalse((self.home / ".claude").exists())
        self.assertFalse((self.home / ".codex").exists())
        self.assertFalse((self.home / ".pi").exists())

    def test_the_helper_prints_only_the_key(self):
        self.enrol()
        printed = subprocess.run([str(self.home / ".local/bin/orbie-gateway-key")], env=self.env, text=True, capture_output=True, check=True).stdout
        self.assertEqual(printed, KEY + "\n")

    def test_enrolment_configures_the_three_tools_without_writing_the_key(self):
        self.enrol()
        (self.home / ".claude").mkdir()
        (self.home / ".claude/settings.json").write_text(json.dumps({"hooks": {"PreToolUse": []}, "env": {"ANTHROPIC_AUTH_TOKEN": "old"}}))
        (self.home / ".codex").mkdir()
        (self.home / ".codex/config.toml").write_text('[features]\nhooks = true\n')
        result = self.run_hook()
        self.assertIn(f"gateway at {URL}", result.stdout)

        claude = json.loads((self.home / ".claude/settings.json").read_text())
        self.assertEqual(claude["env"], {"ANTHROPIC_BASE_URL": URL})
        self.assertEqual(claude["apiKeyHelper"], str(self.home / ".local/bin/orbie-gateway-key"))
        self.assertIn("hooks", claude)

        codex_text = (self.home / ".codex/config.toml").read_text()
        codex = tomllib.loads(codex_text)
        self.assertEqual(codex["model_provider"], "fleet")
        self.assertEqual(codex["features"], {"hooks": True})
        provider = codex["model_providers"]["fleet"]
        self.assertEqual(provider["base_url"], f"{URL}/v1")
        self.assertEqual(provider["wire_api"], "responses")
        self.assertEqual(provider["auth"]["command"], str(self.home / ".local/bin/orbie-gateway-key"))
        self.assertTrue(codex_text.startswith('model_provider = "fleet"\n'))

        pi = json.loads((self.home / ".pi/agent/models.json").read_text())
        providers = pi["providers"]
        self.assertEqual(set(providers), {"fleet-codex", "fleet-claude", "fleet"})
        self.assertEqual(providers["fleet-codex"]["api"], "openai-responses")
        self.assertEqual(providers["fleet-claude"]["api"], "anthropic-messages")
        self.assertEqual(providers["fleet"]["api"], "openai-completions")
        self.assertIn({"id": "go/glm-5.3", "reasoning": True, "contextWindow": 200000}, providers["fleet"]["models"])
        for provider in providers.values():
            self.assertTrue(provider["apiKey"].startswith("!"))

        for path in (".claude/settings.json", ".codex/config.toml", ".pi/agent/models.json"):
            self.assertNotIn(KEY, (self.home / path).read_text())
            self.assertEqual((self.home / path).stat().st_mode & 0o077, 0)

    def test_reruns_replace_the_fleet_block_instead_of_stacking_it(self):
        self.enrol()
        self.run_hook()
        self.enrol(key="w1-" + "f" * 32)
        self.run_hook()
        codex_text = (self.home / ".codex/config.toml").read_text()
        self.assertEqual(codex_text.count("[model_providers.fleet]"), 1)
        self.assertEqual(codex_text.count('model_provider = "fleet"'), 1)
        tomllib.loads(codex_text)

    def test_a_missing_key_or_url_fails_loudly(self):
        (self.home / ".config/orbie").mkdir(parents=True)
        (self.home / ".config/orbie/proxy.env").write_text(f"ORBIE_GATEWAY_URL={URL}\n")
        result = self.run_hook(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ORBIE_GATEWAY_KEY", result.stderr)
        (self.home / ".config/orbie/proxy.env").write_text(f"ORBIE_GATEWAY_KEY={KEY}\n")
        result = self.run_hook(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ORBIE_GATEWAY_URL", result.stderr)


class PiSettingsTemplateTests(unittest.TestCase):
    def render(self, enrolled):
        if not CHEZMOI:
            self.skipTest("chezmoi is required for template rendering")
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp) / "home"
            (home / ".config/orbie").mkdir(parents=True)
            if enrolled:
                (home / ".config/orbie/proxy.env").write_text("ORBIE_GATEWAY_URL=x\n")
            config = Path(temp) / "chezmoi.toml"
            config.write_text("")
            rendered = subprocess.run(
                [CHEZMOI, "--config", str(config), "--source", temp, "--destination", str(home),
                 "--persistent-state", str(Path(temp) / "state.boltdb"),
                 "--override-data", json.dumps({"chezmoi": {"homeDir": str(home)}}), "execute-template"],
                input=PI_SETTINGS, text=True, capture_output=True, check=True,
            ).stdout
        return json.loads(rendered)

    def test_enrolled_machines_use_the_gateway_providers(self):
        settings = self.render(enrolled=True)
        self.assertEqual(settings["defaultProvider"], "fleet-codex")
        # Pi matches these with minimatch, where "*" stops at a slash, so the
        # fleet provider's "go/..." ids need "**".
        self.assertEqual(settings["enabledModels"], ["fleet-codex/*", "fleet-claude/*", "fleet/**"])
        self.assertEqual(settings["defaultModel"], "gpt-6-astra")

    def test_other_machines_keep_their_own_providers(self):
        settings = self.render(enrolled=False)
        self.assertEqual(settings["defaultProvider"], "openai-codex")
        self.assertIn("openai-codex/gpt-6-astra", settings["enabledModels"])
        self.assertNotIn("fleet-codex/*", settings["enabledModels"])


if __name__ == "__main__":
    unittest.main()
