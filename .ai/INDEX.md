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
2. Run `./sync-agentic.sh doctor`.
3. If the asset is native-only, run the suggested `adopt` command.
4. If doctor reports exact duplicate groups, run `./sync-agentic.sh reconcile <kind> <name>` or `./sync-agentic.sh reconcile --all-exact`.
5. Run `./sync-agentic.sh`.
6. Commit `.ai/`, `AGENTS.md`, and toolkit files. Generated IDE folders can stay ignored.

## Bootstrap

After cloning a source-only repo:

```bash
./sync-agentic.sh bootstrap
```
