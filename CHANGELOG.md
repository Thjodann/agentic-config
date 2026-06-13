# Changelog

All notable changes to Agentic Config are tracked here.

## Unreleased

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
