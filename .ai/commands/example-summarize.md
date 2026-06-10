---
name: example-summarize
description: Example slash command. Summarizes the current uncommitted changes in a few bullets. Replace or delete this when you add your own commands.
argument-hint: "[base-branch]"
---

# /example-summarize

Summarize what has changed in the working tree (or vs. the optional base branch).

1. Run `git status` and `git diff` (or `git diff <base-branch>..HEAD` if a base was given).
2. Produce a tight summary:
   - **What changed** — 3–6 bullets grouped by feature/area, not by file.
   - **Risk / things to double-check** — anything that looks incomplete or risky.
3. Keep it scannable. Don't paste raw diffs.
