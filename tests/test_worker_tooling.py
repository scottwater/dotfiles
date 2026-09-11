"""Render/contract checks only: never execute installation or update scripts."""
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
                    self.assertEqual('"npm:yarn" = "1.22.22"' in rendered, role != "bb-worker")
                    self.assertNotIn('php =', rendered)
                    for tool in ("fnox", "herdr", "neovim", "overmind", "gh", "yazi"):
                        self.assertIn(f'{tool} = "latest"', rendered)
                    tools = tomllib.loads(rendered)["tools"]
                    self.assertEqual(tools.get("vfox:mise-plugins/vfox-1password"), "latest")
                    self.assertNotIn("aqua:1password/cli", tools)

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

    def test_core_never_exposes_generic_runtime_aliases(self):
        core = source("run_after_install-core.sh.tmpl")
        body = core.split("install_tooling_node() {", 1)[1].split("\n}\n", 1)[0]
        script = 'mise() { [ "$1" != where ] || printf "%s\\n" "$HOME/runtime"; }\n'
        script += "install_tooling_node() {" + body + "\n}\ninstall_tooling_node\n"
        for existing in (False, True):
            with self.subTest(existing=existing), tempfile.TemporaryDirectory() as temp:
                home = Path(temp)
                bins = home / ".local/bin"
                bins.mkdir(parents=True)
                if existing:
                    for name in ("node", "npm", "npx"):
                        (bins / name).symlink_to(f"/nonexistent/app/{name}")
                for _ in range(2):
                    subprocess.run(["bash", "-eu"], input=script, text=True,
                                   env={**os.environ, "HOME": temp, "CHEZMOI_ROLE": "bb-worker"}, check=True)
                    self.assertEqual(os.readlink(home / ".local/share/orbi/tooling-node"), f"{temp}/runtime")
                    for name in ("node", "npm", "npx"):
                        self.assertEqual(os.path.lexists(bins / name), existing)
                        if existing:
                            self.assertEqual(os.readlink(bins / name), f"/nonexistent/app/{name}")

    @unittest.skipUnless(shutil.which("zsh"), "zsh is required for shell PATH checks")
    def test_rendered_shell_runtime_path_order(self):
        for role in ("bb-worker", "workstation", None):
            with tempfile.TemporaryDirectory() as temp:
                home = Path(temp).resolve()
                bins = home / ".local/bin"
                shims = home / ".local/share/mise/shims"
                for directory, label in ((bins, "local"), (shims, "mise")):
                    directory.mkdir(parents=True)
                    for name in ("node", "npm", "npx"):
                        executable = directory / name
                        executable.write_text(f'#!/bin/sh\necho {label}\n')
                        executable.chmod(0o755)
                # Isolate shell initialization from installed tools and real user config.
                for name in ("mise", "atuin", "stooges", "fnox"):
                    executable = bins / name
                    executable.write_text('#!/bin/sh\nexit 0\n')
                    executable.chmod(0o755)
                for name in ("zshenv", "zprofile", "zshrc"):
                    (home / f".{name}").write_text(self.render(f"dot_{name}.tmpl", role))
                for login in (False, True):
                    for interactive in (False, True):
                        with self.subTest(role=role, login=login, interactive=interactive):
                            command = [shutil.which("zsh"), "-d"]
                            if login:
                                command.append("-l")
                            if interactive:
                                command.append("-i")
                            command += ["-c", 'printf "PATH_RESULT=%s\\n" "$PATH"; node; npm; npx']
                            env = {"HOME": str(home), "ZDOTDIR": str(home),
                                   "PATH": f"{bins}:/usr/bin:/bin", "TERM": "dumb"}
                            result = subprocess.run(command, env=env, cwd=home,
                                                    text=True, capture_output=True, check=True)
                            lines = result.stdout.splitlines()
                            path = next(line.removeprefix("PATH_RESULT=") for line in lines if line.startswith("PATH_RESULT="))
                            paths = path.split(":")
                            if role == "bb-worker":
                                self.assertLess(paths.index(str(shims)), paths.index(str(bins)))
                            else:
                                self.assertNotIn(str(shims), paths)
                            self.assertNotIn(str(home / ".local/share/orbi/tooling-node/bin"), paths)
                            self.assertEqual(lines[-3:], ["mise" if role == "bb-worker" else "local"] * 3)

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

    def test_herdr_preserves_default_cwd_and_worker_worktree_location(self):
        for role in ("bb-worker", "workstation", None):
            with self.subTest(role=role):
                config = tomllib.loads(self.render("private_dot_config/herdr/config.toml.tmpl", role))
                self.assertNotIn("new_cwd", config.get("terminal", {}))
                if role == "bb-worker":
                    self.assertEqual(config["worktrees"]["directory"], "~/code/herdr-worktrees")
                else:
                    self.assertNotIn("terminal", config)
                    self.assertNotIn("worktrees", config)
                self.assertEqual(config["theme"]["name"], "terminal")
                self.assertTrue(config["keys"]["command"])
                self.assertTrue(config["experimental"]["kitty_graphics"])

    def test_code_directory_is_worker_only_and_preserves_projects(self):
        core = source("run_after_install-core.sh.tmpl")
        body = core.split("install_worker_directories() {", 1)[1].split("\n}\n", 1)[0]
        script = "install_worker_directories() {" + body + "\n}\ninstall_worker_directories\n"
        self.assertIn("install_worker_directories\ninstall_atuin", core)
        for role in ("bb-worker", "workstation"):
            with self.subTest(role=role), tempfile.TemporaryDirectory() as temp:
                env = {**os.environ, "HOME": temp, "CHEZMOI_ROLE": role}
                subprocess.run(["bash", "-eu"], input=script, env=env, text=True, check=True)
                code = Path(temp) / "code"
                self.assertEqual(code.is_dir(), role == "bb-worker")
                if role == "bb-worker":
                    project = code / "project"
                    project.mkdir()
                    sentinel = project / "keep.txt"
                    sentinel.write_text("existing work")
                    subprocess.run(["bash", "-eu"], input=script, env=env, text=True, check=True)
                    self.assertEqual(sentinel.read_text(), "existing work")

    @unittest.skipUnless(shutil.which("zsh"), "zsh is required for login directory checks")
    def test_worker_login_defaults_to_code_without_changing_explicit_cwd(self):
        rendered = self.render("dot_zprofile.tmpl", "bb-worker")
        block = rendered.split("# Worker login directory:", 1)[1].split("\nfi", 1)[0]
        block = "# Worker login directory:" + block + '\nfi\nprintf "%s\\n" "$PWD"\n'
        for role in ("workstation", None):
            self.assertNotIn('"$HOME/code"', self.render("dot_zprofile.tmpl", role))
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp).resolve()
            code = home / "code"
            code.mkdir()
            project = code / "project"
            project.mkdir()
            for interactive, cwd, expected in ((True, home, code), (True, project, project), (False, home, home)):
                with self.subTest(interactive=interactive, cwd=cwd):
                    command = [shutil.which("zsh"), "-d", "-f", "-l"]
                    if interactive:
                        command.append("-i")
                    result = subprocess.run(command + ["-c", block], cwd=cwd, env={**os.environ, "HOME": str(home)}, text=True, capture_output=True, check=True)
                    self.assertEqual(result.stdout.strip(), str(expected))
            project.rmdir()
            code.rmdir()
            result = subprocess.run([shutil.which("zsh"), "-d", "-f", "-l", "-i", "-c", block], cwd=home, env={**os.environ, "HOME": str(home)}, text=True, capture_output=True, check=True)
            self.assertEqual(result.stdout.strip(), str(home))

    def test_worker_installs_only_requested_herdr_integrations_on_each_apply(self):
        name = "run_after_zz-install-herdr-integrations.sh.tmpl"
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            bins = home / ".local/bin"
            bins.mkdir(parents=True)
            for executable in ("herdr", "pi", "claude", "codex"):
                path = bins / executable
                body = '#!/bin/sh\nexit 0\n'
                if executable == "herdr":
                    body = '#!/bin/sh\nprintf "%s\\n" "$*" >> "$HOME/calls"\nif [ "$*" = "integration install ${FAIL_INTEGRATION:-none}" ]; then exit 1; fi\n'
                path.write_text(body)
                path.chmod(0o755)
            env = {**os.environ, "HOME": temp, "PATH": "/usr/bin:/bin", "PI_CODING_AGENT_DIR": str(home / ".pi/agent"), "CLAUDE_CONFIG_DIR": str(home / ".claude"), "CODEX_HOME": str(home / ".codex")}
            for role in ("workstation", None):
                subprocess.run(["bash", "-eu"], input=self.render(name, role), env=env, text=True, check=True)
                self.assertFalse((home / "calls").exists())
            worker = self.render(name, "bb-worker")
            expected = ["integration install pi", "integration install claude", "integration install codex", "integration status"]
            for attempt in (1, 2):
                subprocess.run(["bash", "-eu"], input=worker, env=env, text=True, check=True)
                self.assertEqual((home / "calls").read_text().splitlines(), expected * attempt)
                for directory in (".pi/agent", ".claude", ".codex"):
                    self.assertTrue((home / directory).is_dir())
            (home / "calls").unlink()
            result = subprocess.run(["bash", "-eu"], input=worker, env={**env, "FAIL_INTEGRATION": "claude"}, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual((home / "calls").read_text().splitlines(), expected[:2])
            (home / "calls").unlink()
            (bins / "codex").unlink()
            result = subprocess.run(["bash", "-eu"], input=worker, env=env, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("missing codex", result.stderr)
            self.assertFalse((home / "calls").exists())

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
