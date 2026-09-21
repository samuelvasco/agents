---
name: sam-implement
description: >-
  Implement a ticket with full context gathering, skeptical requirement validation, and
  repo-native patterns. Use before starting any feature, bug fix, or task.
---

**Arguments:** ticket description, Linear issue, or pasted requirements.

Implement the ticket below. Follow this workflow exactly.

**Ticket:** $ARGUMENTS

## Hard rules

1. **No code until context is complete** — orient, discover repo rules, gather context, validate claims.
2. **Be skeptical** — verify every path, API, and assumption in the ticket against the codebase. Push back with evidence when the spec is wrong.
3. **Ask or research** — research deeply first; ask the user only when blocked. Batch questions.
4. **Stay lean** — targeted reads and searches; don't load unnecessary files into context.
5. **Follow this repo** — read `AGENTS.md`, `CLAUDE.md`, `README.md`, `.cursor/rules/`, and relevant `.cursor/skills/` before implementing. Never assume patterns from another repo.
6. **Simple and correct** — smallest diff that meets acceptance criteria, using the simplest design that is actually correct. Reuse existing code. No over-engineering or over-defensive code. Prefer early returns / guard clauses over nested conditionals or deep branching. Simplicity is never an excuse for a hack: if the correct fix requires touching more files, adding a real abstraction, or a larger diff, do that — never patch around, special-case, or paper over a problem just to keep the change small.
7. **Follow existing patterns — drift only with hard evidence** — match how this repo already solves this kind of problem (naming, structure, error handling, state management, module boundaries). Don't introduce a new pattern, library, or approach because it's more familiar or "better" in the abstract. Only diverge when there is concrete evidence the existing pattern cannot work here (a real constraint you can point to — a type conflict, a broken invariant, a documented limitation) — not preference, not "this is cleaner." Every time you diverge, flag it to the user inline with `[WARNING-PATTERN-DRIFT]` followed by the pattern you didn't follow and the concrete evidence forcing the divergence. List every drift again in the Phase 5 handoff.
8. **Gate before done** — run the repo's lint, test, and audit commands; fix failures you introduced.
9. You must sync the PR to graphite and give the user the Graphite link instead of the Github one. If graphite is not installed, you must install it.

---

## Phase 0: Orient (no code yet)

1. **Read the ticket** — restate goal, acceptance criteria, and non-goals in your own words.
2. **Discover repo rules** — read before searching code:
    - `AGENTS.md`, `CLAUDE.md`, `README.md` (if present)
    - `.cursor/rules/` (all applicable rules)
    - `.cursor/skills/` (load only skills relevant to this ticket)
3. **Identify the repo** — follow that repo's conventions only.

Start by restating the ticket and listing what you need to verify before writing any code.

## Phase 1: Gather context (still no code)

| Question                               | How to answer                                                                                                                                                                                                                                             |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Where does this live?                  | Search for similar features, related modules, existing hooks/services                                                                                                                                                                                     |
| What already exists?                   | Reuse helpers, components, types, tests — don't reinvent                                                                                                                                                                                                  |
| What's the data flow?                  | Trace from entry → state → persistence → response                                                                                                                                                                                                         |
| What contracts apply?                  | API schemas, OpenAPI types, shared DTOs, DB models                                                                                                                                                                                                        |
| What could break?                      | Call sites, migrations, feature flags, auth, money paths                                                                                                                                                                                                  |
| How does this repo already solve this? | Find at least one existing instance of the same kind of problem (similar endpoint, similar component, similar state pattern) and treat it as the template. If none exists, say so explicitly — that's the only case where "no pattern to follow" is true. |

**Keep context lean:** read targeted files and grep for symbols — don't load entire directories. Summarize findings in a short bullet list before implementing.

### Stop and resolve gaps

If anything is unclear, missing, or contradictory:

1. **Research first** — codebase search, related PRs, schema/types, tests, docs
2. **Ask the user** — only when research can't answer it
3. **Push back** — if the ticket's approach is wrong, incomplete, or conflicts with the codebase, say so with evidence and propose a better path. Don't implement a flawed spec to be agreeable.

### Validate ticket claims (be skeptical)

Before implementing, verify:

- [ ] Stated file paths, function names, and APIs actually exist
- [ ] Proposed behavior matches existing patterns (or there's a good reason to diverge)
- [ ] Acceptance criteria are testable and complete
- [ ] Edge cases are addressed or explicitly deferred
- [ ] No hidden scope (migrations, i18n, analytics, permissions, backwards compat)

Surface mismatches to the user **before** coding.

## Phase 2: Plan (minimal, explicit)

Write a short plan (3–7 bullets):

1. Files to create or modify (and why)
2. What to reuse vs what to add
3. Which existing pattern this follows (name the exemplar file/module) — or, if drifting, the concrete evidence why it can't be followed, flagged as `[WARNING-PATTERN-DRIFT]`
4. Tests to add or update
5. Reviewers/skills to run after

**Scope discipline:** smallest correct diff — favor the design with the fewest moving parts, least branching, and fewest new abstractions that still solves the problem properly. No drive-by refactors, no speculative abstractions, no "while I'm here" changes. If achieving real simplicity means restructuring more than a first glance suggests (e.g. flattening a nested conditional into guard clauses, or fixing the actual root cause instead of a downstream symptom), include that in the plan — small-looking hacks are not simpler, they're technical debt.

## Phase 3: Implement

### Code principles

- **Simple** — the most straightforward correct solution; prefer early returns and guard clauses to exit fast on invalid/edge cases rather than wrapping the main logic in nested `if`s. Flatten branching where you reasonably can.
- **Decoupled** — clear module boundaries; no reaching across feature folders
- **Reuse** — extend existing code before adding parallel implementations
- **Pattern-faithful** — match the repo's existing solution to this class of problem by default. A different approach is a last resort, not a style choice — reach for it only once you have concrete evidence the existing pattern breaks, and mark the deviation `[WARNING-PATTERN-DRIFT]` with the evidence, right where it happens.
- **Robust** — handle real failure modes the ticket implies; not every theoretical edge
- **Secure** — auth, input validation, secrets, PII, and money paths get extra care
- **No shortcuts dressed as simplicity** — don't special-case, silently swallow errors, hardcode a value to sidestep a real problem, or bypass a check just to make the diff smaller or the tests pass. If the simple path and the correct path diverge, take the correct one and say why in the handoff.

### Anti-patterns (avoid)

- Over-engineering (premature abstraction, unnecessary indirection)
- Over-defensiveness (catch-all try/catch, redundant null checks on typed data)
- Deep nesting / arrow code — restructure with early returns instead of adding another indentation level
- Patching a symptom instead of fixing the underlying cause, even when the patch is a smaller diff
- Introducing a new pattern, library, or structure when an existing one already solves this class of problem — without hard evidence and a `[WARNING-PATTERN-DRIFT]` flag
- Duplicating logic that exists elsewhere
- Ignoring repo house rules
- Bloating context — don't read files you don't need

### During implementation

- Check off acceptance criteria as you go
- Re-read applicable skills/rules when touching their domain
- Match surrounding code style
- Prefer hooks/services over logic in components (when the repo does)
- When a function is accumulating nested conditionals, stop and restructure with early returns before continuing — don't bolt more branches onto an already-nested block

## Phase 4: Verify

Run the repo's standard gate commands (from `package.json`, `Makefile`, or `AGENTS.md`). Discover and run — don't assume npm vs pnpm vs poetry.

Fix failures introduced by your changes. Do not declare done while lint fails.

Run repo-specific reviewers if they exist (e.g. `/ts-review`, `/contract-review`, `/arch-review`). Reviewer → `/triage` (if available) → fix only approved items.

### Definition of done

- [ ] All acceptance criteria met
- [ ] No scope creep beyond the ticket
- [ ] Solution follows this repo's existing pattern for this class of problem; any divergence is backed by concrete evidence and flagged `[WARNING-PATTERN-DRIFT]`
- [ ] Solution is as simple as it can be while still being correct — no nested conditionals that could be early returns, no hacks or special-casing standing in for a real fix
- [ ] Tests pass; new behavior has meaningful coverage when the repo tests real behavior
- [ ] Lint/format/audit pass
- [ ] No secrets, debug logs, or commented-out code left behind

## Phase 5: Handoff

Summarize:

1. **What changed** — brief, file-level
2. **Why** — how it satisfies the ticket
3. **`[WARNING-PATTERN-DRIFT]` summary** — list every place the implementation diverged from an existing repo pattern, the pattern it diverged from, and the concrete evidence that forced it. If there were none, say so explicitly.
4. **Simplicity trade-offs** — anywhere you chose a larger/more correct change over a smaller/hackier one, or flattened nesting into early returns, note it briefly
5. **Gaps / decisions** — anything deferred, pushed back on, or needing input
6. **How to verify** — commands run + manual steps if UI
