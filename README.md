# Agentic Config Kit

![Agentic Config Kit banner](assets/agentic-config-kit-banner.png)

Author your AI **rules, agents, slash commands, and skills once** in a neutral
`.ai/` folder, or create them natively in a supported IDE and adopt them into that
shared source of truth.

The kit generates per-IDE config for **Claude Code, Cursor, Windsurf/Devin, Codex,
and Continue** so no teammate is limited by their preferred agentic IDE.

- **Zero dependencies** - Python 3.6+ standard library only.
- **Multi-origin** - native IDE assets can be adopted or reconciled into `.ai/`.
- **Deterministic** - `check` guards against stale committed output.
- **Safe deletes** - generated files and managed blocks are pruned without touching
  hand-written settings, MCP config, hooks, or local preferences.
- **Obsidian-compatible** - `.ai/` is plain Markdown; Obsidian is optional.

## What's in this kit

```
agentic-config-kit/
├── README.md
├── install.sh
├── sync-agentic.sh
├── assets/agentic-config-kit-banner.png
├── hooks/pre-commit
└── .ai/
    ├── INDEX.md
    ├── README.md
    ├── sync.py
    ├── rules/example-repo-guidance.md
    ├── agents/example-code-reviewer.md
    ├── commands/example-summarize.md
    └── skills/example-skill/SKILL.md
```

The `example-*` assets are starter templates. Keep them while learning the format, or
delete them and add your own.

## Install in a project

Requirement: `python3` 3.6+.

```bash
cd agentic-config-kit
./install.sh /path/to/your/repo
```

This copies `.ai/` and `sync-agentic.sh` into the target repo, runs the first sync,
  and offers to install the pre-commit guard. It refuses to overwrite an existing
`.ai/`.

Manual install:

```bash
cp -R agentic-config-kit/.ai /path/to/your/repo/.ai
cp agentic-config-kit/sync-agentic.sh /path/to/your/repo/sync-agentic.sh
cd /path/to/your/repo
chmod +x sync-agentic.sh
./sync-agentic.sh
```

## Easy mode: ask the installed skill

The easiest way to use the kit is to let your agentic IDE call the built-in
`agentic-config-maintainer` skill or `/agentic-config` command. These are canonical
`.ai/` assets, so running the installer/runbook and then `./sync-agentic.sh bootstrap`
projects them into the supported IDE folders automatically.

Instead of memorizing CLI arguments, ask your model for what you want:

```text
/agentic-config add a shared rule for our API handler conventions
/agentic-config adopt this Cursor rule into the shared config
/agentic-config reconcile duplicate skills across the repo
/agentic-config bootstrap this clone
```

Different IDEs expose the same helper differently: as a slash command, workflow,
prompt, or callable skill. In all cases, the maintainer helper should run
`./sync-agentic.sh doctor`, choose the safe workflow, edit canonical `.ai/` files,
and finish with `./sync-agentic.sh` plus `./sync-agentic.sh --check`.

Use the raw CLI when you are scripting, debugging CI, or want exact control. Use the
installed skill for everyday team contributions.

## Daily use

Canonical-first:

```bash
$EDITOR .ai/rules/service-style.md
./sync-agentic.sh
./sync-agentic.sh --check
```

Native-first:

```bash
# Example: a Cursor user created a project rule in the Cursor UI.
./sync-agentic.sh doctor
./sync-agentic.sh adopt cursor .cursor/rules/service-style.mdc
./sync-agentic.sh
```

Duplicate-first:

```bash
./sync-agentic.sh doctor
./sync-agentic.sh reconcile --all-exact
./sync-agentic.sh
```

Fresh clone:

```bash
./sync-agentic.sh bootstrap
```

Recommended source-only commit:

```bash
git add .ai .gitignore AGENTS.md sync-agentic.sh README.md hooks tests
git commit -m "Add shared agentic config"
```

## Where each IDE picks things up

| IDE | Generated surfaces |
| --- | --- |
| Claude Code | `.claude/rules`, `.claude/agents`, `.claude/commands`, `.claude/skills` |
| Cursor | `.cursor/rules`, `.cursor/agents`, `.cursor/commands`, `.cursor/skills` |
| Windsurf/Devin | `.devin/rules`, `.windsurf/workflows`, `.windsurf/skills` |
| Codex | `AGENTS.md`, `.agents/skills`, `.codex/agents` |
| Continue | `.continue/prompts` |

## Guardrails

- Run `./sync-agentic.sh doctor` before committing.
- Run `./sync-agentic.sh --check` in CI.
- Install `hooks/pre-commit` to block stale output and native-only IDE assets that
  have not been adopted.
- Use `./sync-agentic.sh clean` to remove generated local IDE projections.
- Use `./sync-agentic.sh clean --native-duplicates` only for exact native duplicates
  that are already represented in `.ai/`.
- Keep Codex `.codex/rules/*.rules` as Codex-only execution policy; these are not
  portable behavioral rules.
