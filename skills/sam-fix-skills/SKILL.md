---
name: sam-fix-skills
description: >-
  Take user feedback and fix AI skills, rules, and context so agents do not repeat
  the mistake; address root cause and keep skills lean without dropping hard rules
  when consolidating. Use after bad agent behavior or repeated mistakes.
---

Take the feedback from the user and understand the problem. Fix the AI skills, rules, and context so that agents never repeat these mistakes again and the root cause is addressed. Keep the skills lean and optimized.

When the mistake is **breaking integrator or published API behavior**, update the relevant **domain skill** (e.g. `api/.cursor/skills/foundation-api/SKILL.md` for Foundation) with a short, general integrator-contract note—not a one-endpoint spec—and add a **cost–benefit check** to `sam-feedback-evaluator` if bots will keep suggesting the same “fix.” Do not duplicate long prose across many rules.

## Editing skills (avoid regressions)

- **Add, don’t absorb** — new flow (automation, defaults, stack context) gets its own short block. Do **not** fold existing **hard rules** (never reply, never widen scope, ask before API change) into a summary sentence; keep them as explicit bullets unless the user asked to delete them.
- **Before you finish** — scan the diff: every removed line must be dead or merged **without** weakening a constraint. If you merged definition-of-done items, confirm no dropped guard (human vs bot, out-of-diff, silent widen, cross-skill conflicts e.g. reckless `gt sync`).
- **Lean means shorter, not vaguer** — cut duplication and examples, not prohibitions or approval gates.
