# Changelog

All notable changes to Agentic Config are tracked here.

## Unreleased

## v0.1.2 - 2026-06-14

- Fix `agentic status --verbose` so truncated blocker and detail lists (conflicts,
  native-only assets, exact duplicate groups, stale outputs) print in full instead
  of stopping at eight items.
- Fix misleading status hints: default output now points to `status --verbose` only
  when lists were truncated, and optional diagnostics point to `agentic doctor`.
- Clarify README conflict drill to use `agentic status --verbose` before resolving
  divergent native files, and document that pre-tracked IDE folders can remain
  tracked even after Agentic Config adds ignore rules.
- Add runbook guidance for tracked-vs-ignored generated IDE folders as a manual Git
  cleanup decision, not an Agentic Config failure.

## v0.1.1 - 2026-06-14

- Add intent-level CLI commands: `agentic setup`, `agentic status`, and
  `agentic import`. Existing implementation commands remain available as
  advanced/backward-compatible commands.
- Reorder CLI help and docs around common workflows first, with advanced verbs
  (`doctor`, `check`, `adopt`, `reconcile`, `bootstrap`, `demote`, `promote`)
  retained for scripts and expert use.
- Add prioritized status output that separates Blocking, Needs update,
  Recommended cleanup, Optional/informational notes, and Next step.
- Fix `adopt --all` so one conflicting asset no longer aborts the whole run. It
  now adopts every unambiguous native asset, skips conflicts and
  already-represented surfaces with a per-file reason, and prints a summary that
  points to `doctor`.
- Fix the `adopt` -> `sync` round-trip: `sync` now refreshes a markerless native
  file in place when its content is already captured verbatim in `.ai/` (an
  adopted surface). Divergent or unrelated markerless files are still protected.
- Clarify docs: `adopt`/`adopt --all` only scan standard IDE asset directories,
  the example repo ships intentional cross-surface conflicts that need manual
  resolution, and the adopt/resolve/sync flow is documented end to end.
- Test harness: place the fake `HOME` outside the repo tree so user-level global
  asset detection is exercised correctly on non-symlinked `/tmp` (e.g. Linux CI).

## v0.1.0 - 2026-06-13

- Establish GitHub Releases as the distribution source.
- Add SemVer-based CLI version reporting and update checks.
- Add `agentic update`, with `agentic` as the primary CLI and `agentic-config` as compatibility.
