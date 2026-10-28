"""The fleet agent, against a fake fleetd and a temporary home. The agent file
is loaded as a module; nothing here reaches the real fleet."""
import http.server
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
AGENT = ROOT / "dot_local/bin/executable_orbie-agent"


def load_agent(home: Path):
    loader = importlib.machinery.SourceFileLoader("orbie_agent", str(AGENT))
    with mock.patch.dict(os.environ, {"HOME": str(home)}), mock.patch.object(Path, "home", return_value=home):
        spec = importlib.util.spec_from_loader("orbie_agent", loader)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
    return module


class FakeFleetd(http.server.BaseHTTPRequestHandler):
    answers: list[dict] = []
    received: list[tuple[str, dict]] = []

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        FakeFleetd.received.append((self.path, body))
        answer = FakeFleetd.answers.pop(0) if FakeFleetd.answers else {"ok": True}
        payload = json.dumps(answer).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, *args):
        pass


class AgentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)
        self.agent = load_agent(self.home)
        self.server = http.server.HTTPServer(("127.0.0.1", 0), FakeFleetd)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.shutdown)
        FakeFleetd.answers, FakeFleetd.received = [], []
        self.url = f"http://127.0.0.1:{self.server.server_address[1]}"

    def test_report_has_metrics_versions_and_no_key(self):
        report = self.agent.report()
        self.assertEqual(set(report["metrics"]), {"load1", "cpuPercent", "memoryPercent", "diskPercent", "diskFreeGb", "cpus"})
        self.assertGreater(report["metrics"]["diskPercent"], 0)
        self.assertEqual(set(report["versions"]), set(self.agent.TOOLS))
        self.assertEqual(report["keyFingerprint"], "")
        self.assertTrue(report["os"])
        self.assertNotIn("ORBIE_GATEWAY_KEY", json.dumps(report))

    def test_fleet_url_follows_proxy_env_then_the_default(self):
        self.assertEqual(self.agent.fleet_url(), self.agent.DEFAULT_FLEET_URL)
        self.agent.PROXY_ENV.parent.mkdir(parents=True)
        self.agent.PROXY_ENV.write_text("ORBIE_GATEWAY_URL=https://g.example.ts.net/\nORBIE_GATEWAY_KEY=k\n")
        self.assertEqual(self.agent.fleet_url(), "https://g.example.ts.net:9443")
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": "http://127.0.0.1:1/"}):
            self.assertEqual(self.agent.fleet_url(), "http://127.0.0.1:1")

    def test_version_parsing(self):
        with mock.patch.object(self.agent.shutil, "which", return_value="/bin/x"), \
                mock.patch.object(self.agent, "run") as run:
            run.return_value = subprocess.CompletedProcess([], 0, "2.1.310 (Claude Code)\n", "")
            self.assertEqual(self.agent.version_of("claude"), "2.1.310")
            run.return_value = subprocess.CompletedProcess([], 0, "t3 v0.0.46-nightly.20261012.3021\n", "")
            self.assertEqual(self.agent.version_of("t3"), "0.0.46-nightly.20261012.3021")
            run.return_value = subprocess.CompletedProcess([], 0, "hello\n", "")
            self.assertEqual(self.agent.version_of("muse"), "present")
        with mock.patch.object(self.agent.shutil, "which", return_value=None):
            self.assertIsNone(self.agent.version_of("grok"))

    def test_first_approved_report_writes_proxy_env_and_applies_dotfiles(self):
        FakeFleetd.answers = [{"status": "approved", "jobs": [], "key": "air-" + "b" * 32,
                               "gatewayUrl": "https://g.example.ts.net", "machine": "air"}]
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": self.url}), \
                mock.patch.object(self.agent, "run_job", return_value=(0, "")) as run_job:
            self.assertEqual(self.agent.main([]), 0)
        run_job.assert_called_once_with("apply-dotfiles")
        env = self.agent.PROXY_ENV.read_text()
        self.assertIn("ORBIE_GATEWAY_URL=https://g.example.ts.net\n", env)
        self.assertIn("ORBIE_GATEWAY_KEY=air-" + "b" * 32, env)
        self.assertIn("ORBIE_MACHINE=air\n", env)
        self.assertEqual(self.agent.PROXY_ENV.stat().st_mode & 0o777, 0o600)
        self.assertEqual(FakeFleetd.received[0][0], "/api/report")

    def test_jobs_run_from_the_allowlist_and_results_are_posted(self):
        FakeFleetd.answers = [{"status": "approved", "jobs": [{"id": 7, "kind": "update-agents"}, {"id": 8, "kind": "rotate-key"}]}]
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": self.url}), \
                mock.patch.object(self.agent, "run") as run:
            run.return_value = subprocess.CompletedProcess([], 0, "updated\n", "")
            self.assertEqual(self.agent.main([]), 0)
        self.assertEqual(run.call_args.args[0], ["update-ai-tools"])
        results = {path: body for path, body in FakeFleetd.received if "/jobs/" in path}
        self.assertEqual(results["/api/jobs/7/result"], {"exitCode": 0, "output": "updated\n"})
        self.assertEqual(results["/api/jobs/8/result"]["exitCode"], 2)
        self.assertIn("carried no key", results["/api/jobs/8/result"]["output"])

    def test_rotate_key_switches_only_after_the_gateway_accepts_the_new_key(self):
        self.agent.PROXY_ENV.parent.mkdir(parents=True)
        self.agent.PROXY_ENV.write_text("ORBIE_GATEWAY_URL=https://g.example.ts.net\nORBIE_GATEWAY_KEY=air-old\nORBIE_MACHINE=air\n")
        new_key = "air-" + "c" * 32
        args = {"key": new_key, "gatewayUrl": "https://g.example.ts.net", "machine": "air"}
        checked = []

        class Accepted:
            status = 200
            def __enter__(self): return self
            def __exit__(self, *a): return False

        def accept(request, timeout=0):
            checked.append((request.full_url, request.get_header("Authorization")))
            return Accepted()

        with mock.patch.object(self.agent.urllib.request, "urlopen", accept):
            self.assertEqual(self.agent.rotate_key(args), (0, "switched to key " + self.agent.hashlib.sha256(new_key.encode()).hexdigest()[:16] + "\n"))
        self.assertEqual(checked, [("https://g.example.ts.net/v1/models", f"Bearer {new_key}")])
        self.assertIn(f"ORBIE_GATEWAY_KEY={new_key}\n", self.agent.PROXY_ENV.read_text())

        def refuse(request, timeout=0):
            raise self.agent.urllib.error.HTTPError(request.full_url, 401, "Unauthorized", {}, None)

        with mock.patch.object(self.agent.urllib.request, "urlopen", refuse):
            code, output = self.agent.rotate_key({**args, "key": "air-refused"})
        self.assertEqual(code, 1)
        self.assertIn("refused", output)
        self.assertIn(f"ORBIE_GATEWAY_KEY={new_key}\n", self.agent.PROXY_ENV.read_text())  # unchanged

    def test_job_args_reach_the_job(self):
        FakeFleetd.answers = [{"status": "approved", "jobs": [{"id": 9, "kind": "rotate-key", "args": {"key": "air-x", "gatewayUrl": "http://127.0.0.1:9", "machine": "air"}}]}]
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": self.url}):
            self.assertEqual(self.agent.main([]), 0)
        results = {path: body for path, body in FakeFleetd.received if "/jobs/" in path}
        self.assertEqual(results["/api/jobs/9/result"]["exitCode"], 1)
        self.assertIn("refused the new key", results["/api/jobs/9/result"]["output"])

    def test_job_commands(self):
        self.assertEqual(self.agent.job_command("apply-dotfiles"), ["chezmoi", "update", "--force"])
        self.assertEqual(self.agent.job_command("sync-skills")[-6:], ["--skill", "*", "--agent", "universal", "claude-code", "--yes"])
        self.assertIsNone(self.agent.job_command("rotate-key"))
        self.assertIsNone(self.agent.job_command("rm"))

    def test_unreachable_fleetd_fails_without_touching_anything(self):
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": "http://127.0.0.1:9"}):
            self.assertEqual(self.agent.main([]), 1)
        self.assertFalse(self.agent.PROXY_ENV.exists())

    def test_dry_run_prints_the_report_and_sends_nothing(self):
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": self.url}), mock.patch("sys.stdout") as out:
            self.assertEqual(self.agent.main(["--dry-run"]), 0)
        self.assertTrue(out.write.called)
        self.assertEqual(FakeFleetd.received, [])


class UnitFileTests(unittest.TestCase):
    def test_timer_and_launchagent_point_at_the_agent(self):
        service = (ROOT / "private_dot_config/systemd/user/orbie-agent.service").read_text()
        timer = (ROOT / "private_dot_config/systemd/user/orbie-agent.timer").read_text()
        plist = (ROOT / "Library/LaunchAgents/com.orbie.agent.plist.tmpl").read_text()
        self.assertIn("ExecStart=%h/.local/bin/orbie-agent", service)
        self.assertIn("OnUnitActiveSec=5min", timer)
        self.assertIn("{{ .chezmoi.homeDir }}/.local/bin/orbie-agent", plist)
        self.assertIn("<integer>300</integer>", plist)
        subprocess.run(["bash", "-n"], input=(ROOT / "run_after_enable-orbie-agent.sh").read_text(), text=True, check=True)
        ignore = (ROOT / ".chezmoiignore.tmpl").read_text()
        self.assertIn('{{- if eq .chezmoi.os "darwin" }}\n.config/systemd/**', ignore)
        self.assertIn("Library/**", ignore)


if __name__ == "__main__":
    unittest.main()
