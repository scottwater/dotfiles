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

    def test_a_machine_with_its_own_dotfiles_runs_the_configure_script_instead(self):
        FakeFleetd.answers = [{"status": "approved", "jobs": [], "dotfiles": False, "key": "omarchy-" + "d" * 32,
                               "gatewayUrl": "https://g.example.ts.net", "machine": "omarchy"}]
        script = self.home / ".local/bin/orbie-configure-gateway"
        script.parent.mkdir(parents=True)
        script.write_text("#!/bin/sh\necho configured\n")
        script.chmod(0o755)
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": self.url}), \
                mock.patch.object(self.agent, "run_job") as run_job, mock.patch("sys.stdout") as out:
            self.assertEqual(self.agent.main([]), 0)
        run_job.assert_not_called()
        self.assertIn("exit 0", "".join(str(c.args[0]) for c in out.write.call_args_list))
        self.assertIn("ORBIE_GATEWAY_KEY=omarchy-", self.agent.PROXY_ENV.read_text())
        # Without chezmoi or the script, the failure is reported rather than hidden.
        script.unlink()
        with mock.patch.object(self.agent.shutil, "which", return_value=None):
            code, output = self.agent.configure_gateway(True)
        self.assertEqual(code, 127)
        self.assertIn("not configured", output)

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

    def test_sync_skills_runs_with_the_tooling_node_first_on_path(self):
        # The tooling npx is a script whose node comes from PATH; a mise shim
        # with no global node, as on the fleet VM, must not win.
        tooling = self.home / ".local/share/orbi/tooling-node/bin"
        tooling.mkdir(parents=True)
        for name in ("node", "npx"):
            (tooling / name).write_text("#!/bin/sh\ncommand -v node\necho \"job=${ORBIE_AGENT_JOB:-}\"\n")
            (tooling / name).chmod(0o755)
        shim = self.home / ".local/share/mise/shims"
        shim.mkdir(parents=True)
        (shim / "node").write_text("#!/bin/sh\necho 'mise ERROR No version is set for shim: node' 1>&2\nexit 1\n")
        (shim / "node").chmod(0o755)
        code, output = self.agent.run_job("sync-skills")
        self.assertEqual(code, 0)
        # Jobs also carry ORBIE_AGENT_JOB so the dotfiles hooks know their caller.
        self.assertEqual(output.strip().splitlines(), [str(tooling / "node"), "job=1"])

    def test_unreachable_fleetd_fails_without_touching_anything(self):
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": "http://127.0.0.1:9"}):
            self.assertEqual(self.agent.main([]), 1)
        self.assertFalse(self.agent.PROXY_ENV.exists())

    def test_dry_run_prints_the_report_and_sends_nothing(self):
        with mock.patch.dict(os.environ, {"ORBIE_FLEET_URL": self.url}), mock.patch("sys.stdout") as out:
            self.assertEqual(self.agent.main(["--dry-run"]), 0)
        self.assertTrue(out.write.called)
        self.assertEqual(FakeFleetd.received, [])


class AiDirectTests(unittest.TestCase):
    def test_ai_direct_overrides_only_for_one_session(self):
        script = ROOT / "dot_local/bin/executable_ai-direct"
        subprocess.run(["bash", "-n", str(script)], check=True)
        text = script.read_text()
        self.assertIn('"apiKeyHelper": ""', text)
        self.assertIn('"ANTHROPIC_BASE_URL": ""', text)
        self.assertIn("model_provider", text)
        result = subprocess.run(["bash", str(script)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("usage", result.stderr)


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

    def run_enable_script_on_fake_darwin(self, under_agent: bool) -> tuple[subprocess.CompletedProcess, list[str]]:
        """Runs the enable script with a fake uname (Darwin) and a fake
        launchctl that says the job is loaded and records its calls."""
        with tempfile.TemporaryDirectory() as temp:
            home, fake = Path(temp) / "home", Path(temp) / "fake"
            fake.mkdir()
            (home / "Library/LaunchAgents").mkdir(parents=True)
            (home / "Library/LaunchAgents/com.orbie.agent.plist").write_text("<plist/>")
            (fake / "uname").write_text("#!/bin/sh\necho Darwin\n")
            (fake / "launchctl").write_text("#!/bin/sh\necho \"$*\" >>\"$FAKE_LOG\"\nexit 0\n")
            for name in ("uname", "launchctl"):
                (fake / name).chmod(0o755)
            env = {"PATH": f"{fake}:/usr/bin:/bin", "HOME": str(home), "FAKE_LOG": str(Path(temp) / "calls")}
            if under_agent:
                env["ORBIE_AGENT_JOB"] = "1"
            result = subprocess.run(["bash", str(ROOT / "run_after_enable-orbie-agent.sh")], env=env, capture_output=True, text=True)
            calls = (Path(temp) / "calls").read_text().splitlines() if (Path(temp) / "calls").exists() else []
        return result, calls

    def test_the_enable_script_does_not_reload_the_launchagent_from_inside_the_agent(self):
        # Booting out the loaded job from the agent's own apply-dotfiles run
        # kills that agent before the bootstrap, leaving the Mac unloaded.
        result, calls = self.run_enable_script_on_fake_darwin(under_agent=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("not reloaded", result.stdout)
        self.assertFalse([c for c in calls if c.startswith("bootout") or c.startswith("bootstrap")], calls)

    def test_the_enable_script_reloads_the_launchagent_from_a_terminal(self):
        result, calls = self.run_enable_script_on_fake_darwin(under_agent=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([c.split()[0] for c in calls], ["print", "bootout", "bootstrap"])


if __name__ == "__main__":
    unittest.main()
