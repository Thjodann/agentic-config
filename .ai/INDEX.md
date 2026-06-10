# Agentic Config Index

Use this file as an Obsidian-friendly entrypoint. The repository does not require
Obsidian; these links are ordinary Markdown.

## Canonical Assets

- [Rules](rules/)
- [Agents](agents/)
- [Commands](commands/)
- [Skills](skills/)

## Daily Flow

1. Create or edit a native IDE asset or a canonical `.ai/` asset.
2. Run `agentic-config doctor`.
3. If the asset is native-only, run the suggested `adopt` command.
4. If doctor reports exact duplicate groups, run `agentic-config reconcile <kind> <name>` or `agentic-config reconcile --all-exact`.
5. If doctor reports global duplicates in `~/.cursor/`, `~/.codex/`, or another user-level IDE directory, treat them as user-level warnings and clean or adopt them only when the user explicitly asks.
6. Run `agentic-config sync`.
7. Commit `.ai/`, `AGENTS.md`, and toolkit files. Generated IDE folders can stay ignored.

## Bootstrap

After cloning a source-only repo:

```bash
agentic-config bootstrap
```
