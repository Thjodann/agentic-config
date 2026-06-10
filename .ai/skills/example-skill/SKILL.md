---
name: example-skill
description: Example skill template. Shows the SKILL.md format that every supported IDE understands. A skill packages reusable, on-demand instructions (and optional scripts/assets) that the agent invokes when the request matches this description. Replace or delete this when you add your own skills.
---

# Example Skill

This file demonstrates the canonical skill format. The `name` and `description` in the
frontmatter are required; the body below is free-form instructions the agent follows
when the skill is invoked.

## When to use

Describe the trigger precisely — the agent decides whether to invoke a skill based on the
`description`, so make it specific ("Use when converting CSV exports to the internal JSON
schema", not "data stuff").

## Steps

1. Lay out the procedure the agent should follow.
2. Reference any bundled helper files by relative path — e.g. `scripts/convert.py`.
   Put them alongside this `SKILL.md` (in `scripts/`, `references/`, or `assets/`); the
   generator copies the whole skill directory verbatim to every IDE that supports skills.

## Notes

- Reference other assets by **name** ("the example-code-reviewer agent"), never by an
  IDE-specific path — paths differ per IDE.
- Keep instructions self-contained; don't depend on machine-global files outside the repo.
