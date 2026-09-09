"""Render/contract checks only: never execute installation or update scripts."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHEZMOI = shutil.which("chezmoi")


def source(name):
    return (ROOT / name).read_text()


class WorkerToolingTests(unittest.TestCase):
    def render(self, name, role, system="linux"):
        if not CHEZMOI:
            self.skipTest("chezmoi is required for template rendering")
        with tempfile.TemporaryDirectory() as temp:
            config = Path(temp) / "chezmoi.toml"
            config.write_text("")
            data = {"chezmoi": {"os": system}}
            if role is not None:
                data["role"] = role
            return subprocess.run(
                [CHEZMOI, "--config", str(config), "--source", temp,
                 "--destination", temp, "--persistent-state", str(Path(temp) / "state.boltdb"),
                 "--override-data", json.dumps(data), "execute-template"],
                input=source(name), text=True, capture_output=True, check=True,
            ).stdout

    def test_global_runtimes_are_workstation_only(self):
        for role in ("bb-worker", "workstation", None):
            for system in ("linux", "darwin"):
                with self.subTest(role=role, system=system):
                    rendered = self.render("private_dot_config/mise/config.toml.tmpl", role, system)
                    self.assertEqual('node = "24.19.0"' in rendered, role != "bb-worker")
                    self.assertEqual('ruby = "4.0.6"' in rendered, role != "bb-worker")
                    self.assertNotIn('php =', rendered)
                    for tool in ("fnox", "herdr", "neovim", "overmind", "gh", "yazi"):
                        self.assertIn(f'{tool} = "latest"', rendered)

    def test_core_runtime_is_explicit_not_global(self):
        for role in ("bb-worker", "workstation", None):
            rendered = self.render("run_after_install-core.sh.tmpl", role)
            self.assertIn(f'CHEZMOI_ROLE="{role or "workstation"}"', rendered)
            subprocess.run(["bash", "-n"], input=rendered, text=True, check=True)
        core = source("run_after_install-core.sh.tmpl")
        block = core.split("install_tooling_node() {", 1)[1].split("\n}\n", 1)[0]
        self.assertIn('if [ "$CHEZMOI_ROLE" != "bb-worker" ]; then\n    return', block)
        self.assertIn("mise install -y node@24.19.0", block)
        self.assertIn('runtime="$(mise where node@24.19.0)"', block)
        self.assertNotIn("mise use", block)
        self.assertIn('ln -sfn "$runtime" "$HOME/.local/share/orbi/tooling-node"', block)
        self.assertIn("install_mise_tools\ninstall_tooling_node", core)

    def test_initial_links_preserve_app_paths_including_dangling_links(self):
        # Execute only the link loop, not the installer function or script.
        core = source("run_after_install-core.sh.tmpl")
        loop = core.split("  for executable in node npm npx; do", 1)[1].split("\n  done", 1)[0]
        loop = "for executable in node npm npx; do" + loop + "\ndone\n"
        with tempfile.TemporaryDirectory() as temp:
            bins = Path(temp) / ".local/bin"
            bins.mkdir(parents=True)
            (bins / "node").write_text("app node")
            (bins / "npm").symlink_to("/nonexistent/app/npm")
            for _ in range(2):
                subprocess.run(["bash", "-eu"], input=loop, text=True,
                               env={**os.environ, "HOME": temp}, check=True)
                self.assertEqual((bins / "node").read_text(), "app node")
                self.assertEqual(os.readlink(bins / "npm"), "/nonexistent/app/npm")
                self.assertEqual(os.readlink(bins / "npx"), f"{temp}/.local/share/orbi/tooling-node/bin/npx")

    def test_install_and_update_use_isolated_npm_and_role_data(self):
        install = source("run_onchange_after_install-pi.sh")
        update = source("dot_local/bin/executable_update-ai-tools")
        for script in (install, update):
            self.assertIn('chezmoi execute-template', script)
            self.assertIn('get . "role" | default "workstation"', script)
            self.assertIn('"$CHEZMOI_ROLE" = "bb-worker"', script)
            self.assertIn('$HOME/.local/share/orbi/agents', script)
            self.assertIn('env "PATH=$TOOLING_BIN:$PATH" "$TOOLING_BIN/node" "$TOOLING_BIN/../lib/node_modules/npm/bin/npm-cli.js"', script)
            self.assertIn('@earendil-works/pi-coding-agent', script)
            self.assertIn('@openai/codex', script)
            subprocess.run(["bash", "-n"], input=script, text=True, check=True)
        self.assertIn('exec "\\$HOME/.local/share/orbi/tooling-node/bin/node" "\\$HOME/.local/share/orbi/agents/bin/${executable}" "\\$@"', install)
        self.assertIn('rm -f "${HARNESS_BIN}/${executable}"', install)
        self.assertNotIn('rm -f', update)  # npm must not replace local/bin wrappers
        self.assertIn('npm --prefix "$HOME/.local" install -g @openai/codex', update)

    @unittest.skipUnless(shutil.which("node"), "node is required for launcher execution")
    def test_worker_npm_executes_js_entry_not_mise_shell_wrapper(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            tooling = home / "tooling"
            bins = tooling / "bin"
            bins.mkdir(parents=True)
            (bins / "node").symlink_to(shutil.which("node"))
            (bins / "npm").write_text('#!/usr/bin/env bash\nset -euo pipefail\nexit 97\n')
            (bins / "npm").chmod(0o755)
            cli = tooling / "lib/node_modules/npm/bin/npm-cli.js"
            cli.parent.mkdir(parents=True)
            cli.write_text('console.log(JSON.stringify(process.argv.slice(2)));\n')
            app_bins = home / "app/bin"
            app_bins.mkdir(parents=True)
            (app_bins / "node").write_text('#!/bin/sh\nexit 98\n')
            (app_bins / "node").chmod(0o755)
            for name in ("run_onchange_after_install-pi.sh", "dot_local/bin/executable_update-ai-tools"):
                with self.subTest(script=name):
                    assignment = next(line for line in source(name).splitlines() if "npm_command=(env" in line)
                    result = subprocess.run(
                        ["bash", "-eu"], input=assignment + '\n"${npm_command[@]}" --version\n',
                        env={**os.environ, "HOME": temp, "TOOLING_BIN": str(bins), "PATH": f"{app_bins}:{os.environ['PATH']}"},
                        text=True, capture_output=True,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    expected = ["--version"]
                    if name.endswith("executable_update-ai-tools"):
                        expected = ["--prefix", f"{temp}/.local/share/orbi/agents", "--version"]
                    self.assertEqual(json.loads(result.stdout), expected)

    def test_worker_linux_omits_app_build_dependencies(self):
        script = source("run_after_install-linux.sh")
        setup = script.split("app_build_deps=()", 1)[1].split("sudo apt-get update", 1)[0]
        for role in ("bb-worker", "workstation"):
            result = subprocess.run(
                # macOS Bash 3 treats empty arrays as unset with -u; Linux Bash does not.
                ["bash", "-e"], input='app_build_deps=()\n' + setup + '\nprintf "%s\\n" "${app_build_deps[@]}"',
                env={**os.environ, "CHEZMOI_ROLE": role}, text=True, capture_output=True, check=True,
            )
            self.assertEqual("libpq-dev" in result.stdout, role == "workstation")
            self.assertEqual("libyaml-dev" in result.stdout, role == "workstation")
        self.assertIn('  "${app_build_deps[@]}" \\', script)
        self.assertIn('  build-essential \\', script)
        self.assertIn('  sqlite3 \\', script)
        subprocess.run(["bash", "-n"], input=script, text=True, check=True)


if __name__ == "__main__":
    unittest.main()
