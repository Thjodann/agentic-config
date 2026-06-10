import os
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYNC_SRC = os.path.join(ROOT, ".ai", "sync.py")
HOOK_SRC = os.path.join(ROOT, "hooks", "pre-commit")
GITIGNORE_SRC = os.path.join(ROOT, ".gitignore")
MAINTAINER_SKILL_SRC = os.path.join(
    ROOT, ".ai", "skills", "agentic-config-maintainer", "SKILL.md")
MAINTAINER_OPENAI_YAML_SRC = os.path.join(
    ROOT, ".ai", "skills", "agentic-config-maintainer", "agents", "openai.yaml")
MAINTAINER_COMMAND_SRC = os.path.join(
    ROOT, ".ai", "commands", "agentic-config.md")


def write(path, content):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


class SyncRepo(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="agentic-kit-test-")
        os.makedirs(os.path.join(self.tmp, ".ai"))
        shutil.copyfile(SYNC_SRC, os.path.join(self.tmp, ".ai", "sync.py"))
        self.env = dict(os.environ)
        self.env["PYTHONPYCACHEPREFIX"] = os.path.join(self.tmp, ".pycache")

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def run_sync(self, *args, check=True):
        cmd = [sys.executable, ".ai/sync.py"] + list(args)
        return subprocess.run(
            cmd, cwd=self.tmp, env=self.env, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=check)

    def path(self, *parts):
        return os.path.join(self.tmp, *parts)

    def add_rule(self, name="repo-guidance", activation="model_decision"):
        write(self.path(".ai", "rules", "%s.md" % name), """---
name: %s
description: Guidance for %s.
activation: %s
---

Use the shared rule.
""" % (name, name, activation))

    def add_command(self, name="summarize"):
        write(self.path(".ai", "commands", "%s.md" % name), """---
name: %s
description: Summarizes the current work.
argument-hint: "[base]"
---

Summarize the diff.
""" % name)

    def add_agent(self, name="reviewer"):
        write(self.path(".ai", "agents", "%s.md" % name), """---
name: %s
description: Reviews code for correctness.
tools: Read, Grep
---

Review like an owner.
""" % name)

    def add_skill(self, name="debugger"):
        write(self.path(".ai", "skills", name, "SKILL.md"), """---
name: %s
description: Debugs failures with logs and tests.
allowed-tools: Bash, Read
---

Debug the failure.
""" % name)
        write(self.path(".ai", "skills", name, "references", "notes.md"), "Notes\n")

    def add_native_skill(self, root, name="debugger", body="Debug the failure."):
        write(self.path(*root.split("/"), name, "SKILL.md"), """---
name: %s
description: Debugs failures with logs and tests.
allowed-tools: Bash, Read
---

%s
""" % (name, body))


class SyncTests(SyncRepo):
    def test_sync_all_four_kinds_and_check(self):
        self.add_rule()
        self.add_command()
        self.add_agent()
        self.add_skill()

        result = self.run_sync()
        self.assertIn("Synced 4 canonical assets", result.stdout)

        expected = [
            ".cursor/rules/repo-guidance.mdc",
            ".devin/rules/repo-guidance.md",
            ".claude/rules/repo-guidance.md",
            ".claude/commands/summarize.md",
            ".claude/skills/summarize/SKILL.md",
            ".cursor/commands/summarize.md",
            ".windsurf/workflows/summarize.md",
            ".agents/skills/command-summarize/SKILL.md",
            ".codex/agents/reviewer.toml",
            ".windsurf/skills/agent-reviewer/SKILL.md",
            ".agents/skills/debugger/SKILL.md",
            ".agents/skills/debugger/references/notes.md",
            ".continue/prompts/rule-repo-guidance.md",
            "AGENTS.md",
        ]
        for rel in expected:
            self.assertTrue(os.path.exists(self.path(*rel.split("/"))), rel)

        check = self.run_sync("check")
        self.assertIn("In sync", check.stdout)

    def test_adopt_cursor_rule(self):
        write(self.path(".cursor", "rules", "api.mdc"), """---
description: API route conventions.
globs: app/api/**/*.py
alwaysApply: false
---

Use service boundaries.
""")

        self.run_sync("adopt", "cursor", ".cursor/rules/api.mdc")
        canonical = read(self.path(".ai", "rules", "api.md"))
        self.assertIn("activation: glob", canonical)
        self.assertIn("globs: app/api/**/*.py", canonical)

    def test_adopt_windsurf_workflow(self):
        write(self.path(".windsurf", "workflows", "release.md"), """---
name: release
description: Runs release checks.
---

1. Run tests.
2. Summarize risk.
""")

        self.run_sync("adopt", "windsurf", ".windsurf/workflows/release.md")
        canonical = read(self.path(".ai", "commands", "release.md"))
        self.assertIn("description: Runs release checks.", canonical)
        self.assertIn("1. Run tests.", canonical)

    def test_adopt_codex_skill_and_agent(self):
        write(self.path(".agents", "skills", "mlasc-debug", "SKILL.md"), """---
name: mlasc-debug
description: Debugs ML-ASC startup.
---

Check Docker and health endpoints.
""")
        write(self.path(".codex", "agents", "reviewer.toml"), '''name = "reviewer"
description = "Reviews risky changes."
developer_instructions = "Review correctness and tests."
''')

        self.run_sync("adopt", "codex", ".agents/skills/mlasc-debug/SKILL.md")
        self.run_sync("adopt", "codex", ".codex/agents/reviewer.toml")
        self.assertTrue(os.path.exists(self.path(".ai", "skills", "mlasc-debug", "SKILL.md")))
        self.assertTrue(os.path.exists(self.path(".ai", "agents", "reviewer.md")))

    def test_managed_agents_md_preserves_handwritten_content(self):
        self.add_rule("root-rule", "always_on")
        write(self.path("AGENTS.md"), "# Existing\n\nKeep me.\n")

        self.run_sync()
        content = read(self.path("AGENTS.md"))
        self.assertIn("# Existing", content)
        self.assertIn("BEGIN AGENTIC-CONFIG-KIT: rules", content)
        self.assertIn("root-rule", content)

        os.remove(self.path(".ai", "rules", "root-rule.md"))
        self.run_sync()
        content = read(self.path("AGENTS.md"))
        self.assertIn("# Existing", content)
        self.assertNotIn("BEGIN AGENTIC-CONFIG-KIT: rules", content)

    def test_manifest_v1_prunes_old_outputs_and_writes_v2(self):
        write(self.path(".cursor", "commands", "old.md"),
              "<!-- AUTOGENERATED from .ai/commands/old.md by ./sync-agentic.sh; do not edit. -->\n\nold\n")
        write(self.path(".ai", ".manifest.json"), """{
  "version": 1,
  "outputs": [".cursor/commands/old.md"]
}
""")
        self.add_command("new")
        self.run_sync()
        self.assertFalse(os.path.exists(self.path(".cursor", "commands", "old.md")))
        manifest = read(self.path(".ai", ".manifest.json"))
        self.assertIn('"version": 2', manifest)
        self.assertIn(".cursor/commands/new.md", manifest)

    def test_doctor_reports_native_only_stale_and_degraded(self):
        self.add_agent("reviewer")
        write(self.path(".cursor", "rules", "native.mdc"), """---
description: Native only.
---

Native rule.
""")

        result = self.run_sync("doctor", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("native-only", result.stdout)
        self.assertIn("Generated but stale", result.stdout)
        self.assertIn("Degraded mappings", result.stdout)

    def test_codex_rules_are_reported_as_policy_not_portable_rules(self):
        write(self.path(".codex", "rules", "default.rules"), "prefix_rule(pattern=[\"git\"], decision=\"prompt\")\n")
        result = self.run_sync("doctor", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Codex execution policy", result.stdout)

    def test_doctor_detects_exact_duplicate_native_skills(self):
        for root in [".cursor/skills", ".agents/skills", ".claude/skills", ".windsurf/skills"]:
            self.add_native_skill(root, "shared-debug")

        result = self.run_sync("doctor", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Exact duplicate native groups", result.stdout)
        self.assertIn("./sync-agentic.sh reconcile skill shared-debug", result.stdout)

    def test_reconcile_one_exact_duplicate_group(self):
        for root in [".cursor/skills", ".agents/skills", ".claude/skills"]:
            self.add_native_skill(root, "shared-debug")

        result = self.run_sync("reconcile", "skill", "shared-debug")
        self.assertIn("reconciled skill shared-debug", result.stdout)
        self.assertTrue(os.path.exists(self.path(".ai", "skills", "shared-debug", "SKILL.md")))

    def test_reconcile_all_exact_skips_same_name_different_content(self):
        self.add_native_skill(".cursor/skills", "shared-debug")
        self.add_native_skill(".agents/skills", "shared-debug")
        self.add_native_skill(".cursor/skills", "conflict", body="Debug one way.")
        self.add_native_skill(".claude/skills", "conflict", body="Debug another way.")

        result = self.run_sync("reconcile", "--all-exact")
        self.assertIn("Reconciled 1 exact duplicate groups.", result.stdout)
        self.assertTrue(os.path.exists(self.path(".ai", "skills", "shared-debug", "SKILL.md")))
        self.assertFalse(os.path.exists(self.path(".ai", "skills", "conflict", "SKILL.md")))

    def test_clean_removes_generated_projections_preserving_ai_and_agents_md(self):
        self.add_rule("root-rule", "always_on")
        self.add_skill("debugger")
        self.run_sync()
        self.assertTrue(os.path.exists(self.path(".cursor", "skills", "debugger", "SKILL.md")))
        self.assertTrue(os.path.exists(self.path("AGENTS.md")))

        self.run_sync("clean")
        self.assertFalse(os.path.exists(self.path(".cursor", "skills", "debugger", "SKILL.md")))
        self.assertTrue(os.path.exists(self.path(".ai", "skills", "debugger", "SKILL.md")))
        self.assertTrue(os.path.exists(self.path("AGENTS.md")))

    def test_sync_refuses_to_overwrite_markerless_native_file(self):
        self.add_skill("debugger")
        native_path = self.path(".cursor", "skills", "debugger", "SKILL.md")
        write(native_path, """---
name: debugger
description: Human native debugger.
---

Human body that should be adopted first.
""")

        result = self.run_sync(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refusing to overwrite markerless file", result.stdout)
        self.assertIn("Human body that should be adopted first.", read(native_path))
        self.assertFalse(os.path.exists(self.path(".agents", "skills", "debugger", "SKILL.md")))

    def test_clean_refuses_to_remove_markerless_replaced_projection(self):
        self.add_command("debug")
        self.run_sync()
        generated_path = self.path(".cursor", "commands", "debug.md")
        write(generated_path, "# Human native command\n\nNo marker.\n")

        result = self.run_sync("clean", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refusing to clean markerless file", result.stdout)
        self.assertTrue(os.path.exists(generated_path))
        self.assertEqual(read(generated_path), "# Human native command\n\nNo marker.\n")

    def test_clean_native_duplicates_removes_only_exact_unmanaged_duplicates(self):
        self.add_skill("debugger")
        self.add_native_skill(".cursor/skills", "debugger")
        write(self.path(".cursor", "skills", "debugger", "references", "notes.md"), "Notes\n")
        self.add_native_skill(".claude/skills", "different", body="Not canonical.")

        self.run_sync("clean", "--native-duplicates")
        self.assertFalse(os.path.exists(self.path(".cursor", "skills", "debugger", "SKILL.md")))
        self.assertTrue(os.path.exists(self.path(".claude", "skills", "different", "SKILL.md")))
        self.assertTrue(os.path.exists(self.path(".ai", "skills", "debugger", "SKILL.md")))

    def test_doctor_represents_exact_native_duplicates_without_blocking(self):
        write(self.path(".ai", "skills", "debugger", "SKILL.md"), """---
name: debugger
description: Debugs failures with logs and tests.
allowed-tools: Bash, Read
targets: codex
---

Debug the failure.
""")
        self.run_sync()
        write(self.path(".cursor", "skills", "debugger", "SKILL.md"), """---
name: debugger
description: Debugs failures with logs and tests.
allowed-tools: Bash, Read
---

Debug the failure.
""")

        result = self.run_sync("doctor", check=False)
        self.assertEqual(result.returncode, 0)
        self.assertIn("Native duplicates already represented in .ai/", result.stdout)

    def test_bootstrap_generates_local_projections(self):
        self.add_command("bootstrap-me")
        result = self.run_sync("bootstrap")
        self.assertIn("Bootstrap complete", result.stdout)
        self.assertTrue(os.path.exists(self.path(".cursor", "commands", "bootstrap-me.md")))

    def test_builtin_maintainer_assets_generate(self):
        write(self.path(".ai", "skills", "agentic-config-maintainer", "SKILL.md"),
              read(MAINTAINER_SKILL_SRC))
        write(self.path(".ai", "skills", "agentic-config-maintainer", "agents", "openai.yaml"),
              read(MAINTAINER_OPENAI_YAML_SRC))
        write(self.path(".ai", "commands", "agentic-config.md"),
              read(MAINTAINER_COMMAND_SRC))

        self.run_sync()
        self.assertTrue(os.path.exists(self.path(".agents", "skills", "agentic-config-maintainer", "SKILL.md")))
        self.assertTrue(os.path.exists(self.path(".agents", "skills", "agentic-config-maintainer", "agents", "openai.yaml")))
        self.assertTrue(os.path.exists(self.path(".cursor", "skills", "agentic-config-maintainer", "agents", "openai.yaml")))
        self.assertTrue(os.path.exists(self.path(".cursor", "commands", "agentic-config.md")))
        self.assertTrue(os.path.exists(self.path(".windsurf", "workflows", "agentic-config.md")))

    def test_source_only_gitignore_keeps_sources_trackable(self):
        if shutil.which("git") is None:
            self.skipTest("git is not available")
        write(self.path(".gitignore"), read(GITIGNORE_SRC))
        write(self.path(".ai", "sync.py"), "# source\n")
        write(self.path("sync-agentic.sh"), "#!/bin/bash\n")
        write(self.path("AGENTS.md"), "# Agents\n")
        write(self.path(".cursor", "rules", "generated.mdc"), "generated\n")
        subprocess.check_call(["git", "init"], cwd=self.tmp,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        ignored = subprocess.run(
            ["git", "check-ignore", ".cursor/rules/generated.mdc"],
            cwd=self.tmp, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        self.assertEqual(ignored.returncode, 0)
        write(self.path(".codex", "rules", "default.rules"), "policy\n")
        for rel in [".ai/sync.py", "sync-agentic.sh", "AGENTS.md", ".codex/rules/default.rules"]:
            result = subprocess.run(
                ["git", "check-ignore", rel],
                cwd=self.tmp, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertNotEqual(result.returncode, 0, rel)


class PreCommitTests(SyncRepo):
    def test_precommit_blocks_staged_native_only_asset(self):
        if shutil.which("git") is None:
            self.skipTest("git is not available")
        write(self.path("sync-agentic.sh"), """#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "%s" "$ROOT_DIR/.ai/sync.py" "$@"
""" % sys.executable)
        os.chmod(self.path("sync-agentic.sh"), 0o755)
        write(self.path("pre-commit"), read(HOOK_SRC))
        os.chmod(self.path("pre-commit"), 0o755)
        write(self.path(".cursor", "rules", "native.mdc"), """---
description: Native only.
---

Native rule.
""")
        subprocess.check_call(["git", "init"], cwd=self.tmp,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.check_call(["git", "add", ".cursor/rules/native.mdc"], cwd=self.tmp)

        result = subprocess.run(
            ["bash", "pre-commit"], cwd=self.tmp, env=self.env, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("native-only", result.stdout)


if __name__ == "__main__":
    unittest.main()
