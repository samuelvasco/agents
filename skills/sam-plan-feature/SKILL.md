---
name: sam-plan-feature
description: >-
  Clarify feature requirements with the user, then produce a minimal, granular
  implementation plan (ordered todos with how-to) validated for simplicity, repo
  patterns, and scope. Use before coding when the user wants to plan a feature,
  spec a change, or design the smallest safe approach.
---

**Arguments:** feature idea, ticket, or requirements text.

**Plan only — no code, no PR.** After the user approves the plan, use `sam-implement` to build it.

**Input:** $ARGUMENTS

## Rules

- **Simplest correct plan** — smallest change that meets stated requirements and stays safe.
- **Repo-native** — read `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, and skim for one exemplar of the same kind of work before proposing structure.
- **No scope creep** — do not add migrations, analytics, i18n, permissions, backwards compat, or “nice to haves” unless the user required them.
- **No fantasy edge cases** — ignore hypotheticals that are unlikely or impossible here unless they have **material** impact (data loss, security, money, broken invariants). Defer the rest explicitly or omit them.
- **Batch questions** — when clarifying, ask several focused questions at once; do not drip one question per turn.
- **Granular todos** — the plan is the execution checklist: every step the implementer must do, in order, with **how** (file, pattern, API, command), not just **what**.

---

## Phase 1: Requirements (loop with user)

1. Restate **goal**, **acceptance criteria**, and **non-goals** in your own words.
2. List **open questions** (ambiguity, missing AC, contradictions, unknown constraints).
3. If anything is open → ask the user; **stop and wait**. Do not plan yet.
4. When the user answers, update the restatement and repeat until **no material open questions** remain.

**Done when:** acceptance criteria are testable, non-goals are explicit, and you could hand this to someone else without guessing intent.

---

## Phase 2: Minimal plan (draft)

Skim the codebase only enough to name real files, reuse points, and the pattern to follow (grep + targeted reads — stay lean).

The **Implementation todos** section is the main deliverable: exhaustive, ordered, checkable. Split work until each todo is one concrete action (roughly one file or one logical unit). Vague bullets like “wire up UI” are not allowed — decompose them.

Each todo uses this shape:

```markdown
- [ ] **T{n}:** [Outcome in one line]
  - **How:** [Exact approach — which file(s), what to copy from exemplar `path`, which function/type/hook to extend, naming to match, commands to run]
  - **Done when:** [Observable check — test passes, AC slice met, lint clean on touched files, etc.]
```

Write the plan using this template:

```markdown
## Feature plan: [short title]

### Requirements (locked)
- Goal: …
- Acceptance criteria: …
- Non-goals: …
- Deferred / out of scope: …

### Reuse & pattern
- Exemplar: `[path]` — mirror its structure for …
- Reuse as-is: …

### Implementation todos (ordered — execute top to bottom)

- [ ] **T1:** …
  - **How:** …
  - **Done when:** …
- [ ] **T2:** …
  - **How:** …
  - **Done when:** …
- … (every step through AC + required tests + repo gate commands)

### Safety (only what matters here)
- Which todos address it: T… — …

### Risks / open items
- … (only if any remain)
```

---

## Phase 3: Self-critique (loop until clean)

Review the draft plan **yourself**. If any check fails, revise the plan and run all checks again.

| Check | Question |
|-------|----------|
| Simplest | Is there a smaller plan that still meets AC and is correct? Cut it. |
| Patterns | Does this match how this repo already does this? Name the exemplar. Flag `[WARNING-PATTERN-DRIFT]` only with concrete evidence it cannot be followed. |
| Scope creep | Did you add anything not required by AC or safety? Remove it. |
| Hypotheticals | Did you design for “what if” scenarios with no material impact? Drop them or move to Deferred. |
| Granularity | Could an implementer execute without inventing steps? Every AC item and required test should map to at least one todo; merge vague todos or split coarse ones. |

Repeat until all four pass.

---

## Phase 4: User approval

Present the final plan and ask: **“Approve this plan, or what should change?”**

Do not implement until the user approves (or gives explicit edits — then re-run Phase 3 if the requirements changed materially).

On approval, **`sam-implement`** should execute **Implementation todos** in order, checking each box and honoring each **How** / **Done when** unless the codebase proves the plan wrong (then stop and reconcile with the user).
