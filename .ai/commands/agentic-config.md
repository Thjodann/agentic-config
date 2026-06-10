---
name: agentic-config
description: Conversationally manage the shared agentic config. Use this when the user wants to add a shared rule, command, skill, or agent; adopt native IDE config; reconcile repo/global duplicates; bootstrap projections after clone; check sync health; or clean generated output without remembering CLI arguments.
argument-hint: "[what you want to do]"
---

# /agentic-config

Handle the user's request conversationally. Do not require them to know
`agentic-config` or `sync-agentic.sh` arguments.

1. Use the `agentic-config-maintainer` skill.
2. Run `agentic-config doctor` unless the request is purely explanatory.
3. Infer the action: init, stealth init, add, adopt, reconcile, bootstrap, clean, doctor, sync, or check.
4. Ask only if the asset type, target file, or conflict winner is genuinely ambiguous.
5. Prefer canonical `.ai/` edits over generated IDE files.
6. After changes, run `agentic-config sync` and `agentic-config check`.
7. If `agentic-config` is unavailable but `./sync-agentic.sh` exists, use the wrapper.
