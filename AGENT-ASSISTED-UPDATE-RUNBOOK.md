# Agent- and OS-Agnostic Agentic Config Update Runbook

Use this runbook when a user asks an agentic IDE or coding assistant to install,
update, or verify Agentic Config for a repository. It is intentionally
model-agnostic and operating-system-agnostic: adapt command syntax to the user's
shell, but preserve the same decisions, safety checks, and verification order.

## Model Suitability Notice

Before executing, confirm that the current agent can inspect files, run or request
shell commands, translate command syntax for the active OS, preserve unrelated
user changes, reason about Git state, and stop safely on conflicts. If any of
those capabilities are missing or unreliable, tell the user this workflow should
be run with a stronger coding/reasoning model or an agent with filesystem and
shell access, then pause before making changes.

Prefer a stronger model or a more capable agent when:

- the repo has existing `.ai/` or `.agentic-config/.ai/` plus native IDE config;
- the user requires stealth/no tracked Git changes;
- shell syntax must be translated across POSIX, PowerShell, or Windows cmd;
- `doctor`, `check`, tests, or Git status produce unexpected output;
- conflicts, native-only assets, or IDE-specific canonical names appear;
- the agent cannot verify each command result itself.

## Goal

Bring the user's Agentic Config installation and target repository setup up to
the selected source, without accidentally copying dirty local work or changing
tracked repo files when the install is stealth.

Successful completion means:

- the source checkout comes from a stable GitHub Release, committed remote ref, clean
  tag, or explicitly approved clean local checkout;
- the user-level `agentic` and `agentic-config` CLIs plus bundled templates match that
  source;
- the target repo's canonical config is updated in the right location;
- generated projections are regenerated and verified;
- expected warnings are explained instead of blindly "fixed";
- a final status report lists exactly what changed and what remains.

## Agnostic Execution Rules

- Treat shell syntax as replaceable and process order as fixed.
- Prefer stable GitHub Releases for reproducible installs and updates.
- Use `agentic` when available. Use `agentic-config` when `agentic` is unavailable or when
  explicit naming is clearer. They are equivalent Agentic Config entrypoints.
- In command examples, `<agentic-cmd>` means the one Agentic Config command chosen for this run.
  Pick it once, then use it consistently so real command failures are not hidden
  by retrying through an alias.
- Never run angle-bracket placeholders literally. Replace values such as `<agentic-cmd>`,
  `<kit-source>`, `<target-repo>`, and `<temp-dir>` before executing a command.
- Use absolute paths for target repos, temp dirs, and local kit checkouts.
- If a command fails only because the shell syntax is wrong, translate it for the
  active shell and retry the same operation.
- If a tool is unavailable, use the documented alternative and report the
  substitution in the final status.
- Do not use model-specific tools, memories, plugins, browser state, or IDE-only
  features unless the user explicitly asks for that agent's local capability.

## Syntax Translation

The examples below use POSIX shell syntax. Translate only the shell mechanics when
running elsewhere:

- Command exists:
  - POSIX: `command -v agentic` or `command -v agentic-config`
  - PowerShell: `Get-Command agentic -ErrorAction SilentlyContinue`
  - Windows cmd: `where agentic`
- One-command environment variable:
  - POSIX: `NAME=value command`
  - PowerShell: `$env:NAME = "value"; command; Remove-Item Env:NAME`
  - Windows cmd: `set NAME=value` then run the command in the same terminal
- Directory exists:
  - POSIX: `test -d <path>`
  - PowerShell: `Test-Path <path> -PathType Container`
  - Windows cmd: `if exist <path>\NUL`
- Copy one file:
  - POSIX: `cp <source> <destination>`
  - PowerShell: `Copy-Item <source> <destination> -Force`
  - Windows cmd: `copy <source> <destination>`
- Copy one directory:
  - POSIX: `cp -R <source> <destination>`
  - PowerShell: `Copy-Item <source> <destination> -Recurse -Force`
  - Windows cmd: `xcopy <source> <destination> /E /I /Y`
- Temp directory:
  - POSIX/macOS/Linux: `${TMPDIR:-/tmp}`
  - PowerShell: `$env:TEMP`
  - Windows cmd: `%TEMP%`

Do not skip a verification step just because syntax translation is required.

## Inputs

Required:

- Target repository path.

Optional:

- Desired kit release, ref, tag, branch, or clean local checkout. Default to the
  latest stable GitHub Release.
- Install mode for the target repo:
  - normal mode: committed canonical `.ai/`;
  - stealth mode: local ignored `.agentic-config/.ai/`.
- Whether the user-level CLI should be updated.
- Whether a repo-specific runbook, README section, or changelog entry is needed.

If the target repo or install mode is unclear, inspect the repo before asking.

## Safety Rules

- Do not use a dirty working tree as the kit source unless the user explicitly
  says to include those uncommitted changes.
- Prefer a stable release archive. Use a clean clone, clean worktree, or local
  checkout only when the user asks for that source.
- In stealth mode, do not edit `.gitignore`; stealth uses `.git/info/exclude`.
- In stealth mode, do not modify tracked generated paths or tracked `AGENTS.md`.
- Do not hand-edit generated files with `AUTOGENERATED` markers.
- Preserve repo-specific canonical assets when updating kit engine files.
- Copy kit-owned helper files as complete files or directories; do not merge them
  line-by-line unless the user asks for a manual merge.
- Do not delete native IDE files, global user-level assets, or generated
  projections unless the user explicitly asks for cleanup.
- If `doctor` reports conflicts or same-name different-content assets, stop and
  report them instead of choosing a winner silently.

## Step 1: Inspect The Current State

In the target repo:

```bash
git status --short --branch
git rev-parse --show-toplevel
command -v agentic
command -v agentic-config
```

Treat a missing command as information, not as a workflow failure.

If neither `agentic` nor `agentic-config` is installed, install the user-level CLI in
Step 4 before running repo-level Agentic Config commands. If either command exists, choose
one as `<agentic-cmd>` and run:

```bash
<agentic-cmd> --version
<agentic-cmd> doctor
<agentic-cmd> check
```

Find the canonical source:

```bash
test -d .ai && echo "normal source: .ai"
test -d .agentic-config/.ai && echo "stealth source: .agentic-config/.ai"
```

Treat a missing directory as information, not as a workflow failure.

Interpretation:

- `.ai/` exists: update the repo's committed canonical source.
- `.agentic-config/.ai/` exists: update the local stealth canonical source.
- both exist: report both and ask which source should be canonical before editing.
- neither exists: initialize with `agentic init` or `agentic init --stealth` according to
  the user's requested mode.

## Step 2: Select A Reproducible Kit Source

Default to the latest stable GitHub Release:

```bash
<agentic-cmd> update --check
```

If the user asked for a specific release:

```bash
<agentic-cmd> update --check --version v0.1.0
```

If the CLI is not installed yet, the installer resolves the latest stable release:

```bash
curl -fsSL https://raw.githubusercontent.com/Thjodann/agentic-config-kit/main/install-agentic-config.sh | sh
```

Use a branch or local checkout only when the user requested it. For a branch or
remote ref, use a clean committed source:

```bash
git ls-remote <kit-remote-url> HEAD refs/heads/main
git clone --depth 1 --branch main <kit-remote-url> <temp-dir>/agentic-config-kit
git -C <temp-dir>/agentic-config-kit rev-parse HEAD
git -C <temp-dir>/agentic-config-kit status --short --branch
```

For a local checkout, verify it is clean first:

```bash
git -C <kit-checkout> status --short --branch
```

If it is dirty, either:

- ask whether those uncommitted changes are in scope; or
- create a clean worktree or clone from the committed remote ref.

Do not install from a dirty checkout by accident. If the chosen source is a
release archive or tag, record the tag. If it is a branch or ref, record the
commit SHA.

## Step 3: Verify The Kit Source

For a local kit source, run these checks from that source. Syntax-check each shell
script separately; `sh -n a.sh b.sh` checks only `a.sh` and passes `b.sh` as an
argument.

```bash
python3 -m py_compile .ai/sync.py agentic-config
sh -n install-agentic-config.sh
sh -n uninstall-agentic-config.sh
sh -n sync-agentic.sh
sh -n install.sh
python3 -m unittest discover -s tests
```

If Python bytecode cache permissions fail on macOS or locked-down systems, rerun
the compile check with an explicit temp cache:

```bash
PYTHONPYCACHEPREFIX=<temp-dir>/pycache python3 -m py_compile .ai/sync.py agentic-config
```

If the kit has no `tests/` directory in the selected release, state that unit
tests were unavailable and continue only after the syntax checks pass.

## Step 4: Update The User-Level CLI

When the user wants the installed CLI updated and Agentic Config is already installed, use
the release-aware self-update:

```bash
<agentic-cmd> update
```

For a specific release:

```bash
<agentic-cmd> update --version v0.1.0
```

If Agentic Config is not installed, install the latest stable release:

```bash
curl -fsSL https://raw.githubusercontent.com/Thjodann/agentic-config-kit/main/install-agentic-config.sh | sh
```

If the user explicitly requested a clean local source instead of a release, install
from that source:

```bash
AGENTIC_CONFIG_SOURCE_DIR=<clean-kit-source> sh <clean-kit-source>/install-agentic-config.sh
```

Then verify the installed entrypoints:

```bash
agentic --version
agentic-config --version
agentic --help
agentic-config --help
```

If the user requests a clean reinstall, preview the uninstall first:

```bash
agentic uninstall --dry-run
```

Then run `agentic uninstall` before the install step, or use the standalone
uninstaller when the installed command is unavailable:

```bash
curl -fsSL https://raw.githubusercontent.com/Thjodann/agentic-config-kit/main/uninstall-agentic-config.sh | sh
```

Uninstall removes only the user-level Agentic Config CLI install and bundled kit directory;
it does not clean initialized repo config or global IDE assets.

If a custom `AGENTIC_CONFIG_HOME` was used, verify that directory. Otherwise the
default install home is `$HOME/.local/share/agentic-config-kit` on POSIX-like
systems.

Set `<kit-source>` for the target repo update:

- release/curl/self-update path: use the installed kit home;
- clean local checkout path: use that clean local checkout.
- if the user-level CLI was not updated, use a clean release archive, clean clone,
  or explicitly approved clean local checkout as `<kit-source>` instead of
  assuming the existing install is current.

For a local-source install, compare bundled templates against the selected source:

```bash
diff -qr <kit-source>/.ai <installed-kit-home>/.ai
```

The help output should match the README for the selected source. For example, if
the README documents `update`, `demote`, `promote`, `adopt --all`, or
`clean --native-duplicates`, the installed help should list them too.

## Step 5: Update A Target Repo In Normal Mode

For a normal committed setup, update only kit-owned files and preserve project
assets. Create parent directories if the target repo is missing them:

```bash
mkdir -p .ai/commands .ai/skills/agentic-config-maintainer/agents
cp <kit-source>/.ai/sync.py .ai/sync.py
cp <kit-source>/.ai/README.md .ai/README.md
cp <kit-source>/.ai/INDEX.md .ai/INDEX.md
cp <kit-source>/.ai/commands/agentic-config.md .ai/commands/agentic-config.md
cp <kit-source>/.ai/skills/agentic-config-maintainer/SKILL.md .ai/skills/agentic-config-maintainer/SKILL.md
cp <kit-source>/.ai/skills/agentic-config-maintainer/agents/openai.yaml .ai/skills/agentic-config-maintainer/agents/openai.yaml
```

If the target repo uses the compatibility wrapper, update it too:

```bash
cp <kit-source>/sync-agentic.sh sync-agentic.sh
```

If the kit release changed other built-in assets, copy those specific assets only
after confirming they are kit-owned and not repo-specific.

Run:

```bash
<agentic-cmd> sync
<agentic-cmd> check
<agentic-cmd> doctor
```

Commit only the intended source files and tracked managed files.

## Step 6: Update A Target Repo In Stealth Mode

For a stealth setup, update `.agentic-config/.ai/` rather than `.ai/`:

```bash
mkdir -p .agentic-config/.ai/commands .agentic-config/.ai/skills/agentic-config-maintainer/agents
cp <kit-source>/.ai/sync.py .agentic-config/.ai/sync.py
cp <kit-source>/.ai/README.md .agentic-config/.ai/README.md
cp <kit-source>/.ai/INDEX.md .agentic-config/.ai/INDEX.md
cp <kit-source>/.ai/commands/agentic-config.md .agentic-config/.ai/commands/agentic-config.md
cp <kit-source>/.ai/skills/agentic-config-maintainer/SKILL.md .agentic-config/.ai/skills/agentic-config-maintainer/SKILL.md
cp <kit-source>/.ai/skills/agentic-config-maintainer/agents/openai.yaml .agentic-config/.ai/skills/agentic-config-maintainer/agents/openai.yaml
```

Then run:

```bash
<agentic-cmd> sync
<agentic-cmd> check
<agentic-cmd> doctor
```

Expected stealth behavior:

- generated local projections may be created, updated, or pruned;
- `.gitignore` should not change;
- tracked generated paths are skipped and reported;
- ignored local files may change without appearing in normal `git status`.

Use these checks to prove tracked repo files did not morph:

```bash
git status --short
git status --ignored --short
git diff -- .gitignore
```

## Step 7: Resolve Naming Or Drift Issues

If the newer kit reports IDE-specific canonical names, rename the canonical source
to the neutral behavior name. Example:

```bash
mv .agentic-config/.ai/rules/cursor-runbook-naming.md .agentic-config/.ai/rules/runbook-naming.md
```

Then update the asset frontmatter from:

```yaml
name: cursor-runbook-naming
```

to:

```yaml
name: runbook-naming
```

Run sync/check/doctor again.

Treat these as blockers:

- `check` reports stale generated output;
- `doctor` reports repo-native-only assets that should have been adopted;
- `doctor` reports canonical conflicts;
- `doctor` reports IDE-specific canonical names;
- tracked files changed when the user requested stealth/no tracked changes.

Treat these as reportable warnings, not blockers, unless the user asks to clean
them:

- degraded mappings between IDEs;
- global user-level duplicates or overlaps;
- Cursor-visible overlap warnings;
- stealth skipped tracked outputs.

## Step 8: Final Report

Report:

- selected kit source ref or release;
- whether the user-level CLI was updated;
- target repo mode: normal or stealth;
- files or asset groups changed;
- verification commands and results;
- expected warnings still present;
- any blockers that need user choice.

For stealth installs, explicitly say whether tracked repo files changed.

## Minimal Agent Prompt

Paste this into any agentic IDE when asking a model to perform the workflow:

```text
Please update this repo's Agentic Config setup in a model- and OS-agnostic
way. Use the runbook's process order exactly, but translate shell syntax for this
environment when needed.

Prefer the latest stable GitHub Release. Do not install from a dirty working tree
unless I explicitly say those changes are in scope. Detect whether this target
repo uses normal `.ai/` or stealth `.agentic-config/.ai/`. Preserve repo-specific
assets. Update only kit-owned engine/docs/helper assets, then run sync, check, and
doctor with `agentic` or `agentic-config`, whichever is available.

If this is a stealth install, do not edit `.gitignore` or tracked generated files.
Report expected degraded mappings, global overlaps, Cursor-visible overlaps, and
stealth skipped tracked outputs as warnings, not failures. Stop on stale output,
canonical conflicts, repo-native-only assets that need adoption, or IDE-specific
canonical names. In the final report, list the selected release/ref, changed
files, verification results, warnings, and whether tracked repo files changed.
```
