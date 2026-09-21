---
name: sam-enhanced-debug-mode
description: Investigates bugs by tracing symptoms to their real root cause before proposing fixes. Uses multiple perspectives (data flow, state, timing, contracts, architecture) to distinguish systemic issues from local bugs. Rejects hacks and symptom patches. Use when debugging, investigating errors, triaging failures, fixing bugs, or when the user asks for root cause analysis.
disable-model-invocation: true
---

# Root-Cause Debugging

## Core mandate

Find the **real root cause**, not the symptom. Propose fixes that **eliminate the cause** — simple, robust, decoupled, and aligned with the repository's rules and conventions. **Never implement hacks, patches, or workarounds** that paper over bad state.

Be thorough. **Do not assume.** If a question can be answered by reading code, running a command, checking logs, or querying a system — **dig for it yourself**. Only ask the user when you are blocked by missing access, credentials, or reproduction steps you cannot obtain.

## When to use

- User reports a bug, error, unexpected behavior, or regression
- Before implementing any fix (investigate first unless the user explicitly asks for a blind patch)
- After a fix attempt failed or the issue recurred
- When stack traces, logs, or test failures point at a line but the *why* is unclear

For Sentry-specific production triage, also load `sam-root-cause-debugging`. This skill is the general framework; that skill adds Sentry MCP workflow.

---

## Phase 1 — Understand the failure (no hypotheses yet)

Collect facts before theorizing:

1. **Observed behavior** — what happened, what was expected, who/what is affected
2. **Reproduction** — exact steps, environment, version, flags, account/data shape
3. **Failure artifact** — stack trace, error message, log line, screenshot, test output
4. **Scope** — always broken, intermittent, new, or regressed? One user or many?
5. **Recent changes** — commits, deploys, config, dependencies near the failure window

Write a one-line **failure statement**: "When X under Y, Z happens instead of W."

Do not propose fixes in this phase.

---

## Phase 2 — Separate symptom from cause

| Symptom | Root cause |
|---------|------------|
| Where the error surfaces (throw site, UI glitch, failed assertion) | Why invalid state or missing precondition existed |
| Last frame in a stack trace | Earliest point your code allowed bad data or wrong branch |
| User-visible wrong output | Upstream logic, contract, or lifecycle that produced it |

Build a **causal chain** backward from the failure:

```
Failure → immediate trigger → contributing condition → root cause
```

Each link needs **evidence** (code path, log, test, query). If a link is unproven, mark it **unknown** and investigate that link next — do not skip to a fix.

**Five-whys discipline:** ask "why was this state possible?" until you hit a fixable design or logic gap, not "why did this line throw?"

---

## Phase 3 — Multiple perspectives

Inspect the same failure through each lens. Not every lens applies; use all that might.

### Data flow

- Where does the bad value originate? Trace caller → callee to the **source of truth**.
- Is data transformed, cached, or stale between source and failure?
- For API/client: does the payload match the contract (types, nullability, enums)?

### State and lifecycle

- Who owns this state? Is it duplicated in two places?
- Was state read before it was ready, or after it was cleared?
- Effect ordering, mount/unmount, navigation, background/foreground?

### Timing and concurrency

- Race between async operations? Missing await? Out-of-order callbacks?
- Retry or duplicate submission? Idempotency?
- Flaky test → suspect timing, shared mutable state, or external IO.

### Configuration and environment

- Feature flags, env vars, build flavor, OS version?
- Diff prod vs dev: data shape, permissions, network, third-party status?

### Contract and boundaries

- Serializer/API/schema mismatch? Version skew between services?
- Implicit assumptions at module boundaries (null vs empty, 0 vs undefined)?

### User input and edge cases

- Empty, null, boundary values, permissions, offline, partial success?

### Architecture vs local bug

After the lenses above, classify:

| Signal | Likely nature |
|--------|----------------|
| Same bug in multiple features sharing one pattern | **Architectural** — wrong abstraction, ownership, or coupling |
| Violates a stated invariant in one module | **Local** — fix logic in that module |
| Fix requires touching 5+ unrelated call sites | **Architectural** — missing primitive or wrong layer |
| Single wrong conditional / missing guard | **Local** — targeted fix |
| Recurring class of bugs (races, stale cache, double-submit) | **Architectural** — structural prevention |

**Do not default to architecture** for drama; **do not default to local** to avoid harder fixes. Let evidence decide.

---

## Phase 4 — Investigate deeply (anti-laziness rules)

- **Read the code** on every in-app stack frame — do not stop at the throw site.
- **Run things:** tests, repro scripts, linters, queries, curl — use the environment; do not guess output.
- **Search the codebase** for other call sites, similar patterns, and prior fixes for the same area.
- **Check git history** when regression or "used to work" is mentioned.
- **Validate hypotheses** with a minimal experiment before editing production logic.
- **Rule out alternatives** explicitly — list what you considered and why it is not the cause.

### Forbidden shortcuts

- Fixing only the throw site without explaining why bad state existed
- `try/catch` to swallow errors, null checks that hide upstream bugs, sleeps to fix races
- Copy-paste duplication instead of fixing the shared abstraction
- Disabling tests or linters to green CI
- "Probably" / "likely" without naming what evidence would confirm or refute
- Asking the user for information you can obtain with tools in this session

### When to ask the user

Only when blocked: no access, cannot reproduce after documented attempts, product decision needed, or missing secrets/credentials you cannot use.

---

## Phase 5 — Root cause statement

Before any fix, produce a concise root-cause summary:

```markdown
## Root cause
[1–2 sentences: the fixable gap — wrong assumption, missing invariant, bad ownership, etc.]

## Causal chain
1. [failure]
2. [immediate trigger] — evidence: …
3. [deeper condition] — evidence: …
4. [root cause] — evidence: …

## Classification
[Local bug | Architectural issue | Contract/env mismatch | Data/timing]

## Ruled out
- [hypothesis] — [why not]

## Confidence
[Confirmed | Likely — needs X to confirm]
```

If confidence is not **Confirmed**, continue investigating or run a targeted read-only diagnostic (script, query, log request) — do not implement a speculative fix.

---

## Phase 6 — Fix design (root cause only)

Fixes must **remove the condition that made the failure possible**, not hide the symptom.

### Fix quality bar

- **Simple** — smallest change that fully addresses the cause; no speculative refactors
- **Robust** — handles the edge case class, not just the one reported input
- **Decoupled** — fix at the right layer; do not spread special cases across call sites
- **Conventional** — match existing patterns in the repo; read surrounding code first
- **No hacks** — no TODO-without-ticket band-aids, feature-flag gating of broken behavior, or "works on my machine" env checks in business logic

### Architecture vs local fix

**Local fix** when: one module violated a clear invariant → add/fix guard, correct logic, or test at source.

**Architectural fix** when: the system design invites the bug → introduce or fix the owning abstraction (single source of truth, idempotency key, typed boundary, lifecycle hook). Prefer structural fixes over scattered guards when the pattern repeats.

If an architectural fix is too large for the current task, state that explicitly, implement the **minimal root-cause local fix** that does not foreclose the structural fix, and describe the follow-up — do not ship a hack instead.

### Before editing

1. State what will change and **which link in the causal chain it breaks**
2. Identify tests to add or update — reproduction test first when possible
3. Note blast radius (call sites, migrations, API changes)

---

## Phase 7 — Verify

After implementing:

1. **Reproduce the original failure** — confirm it no longer occurs
2. **Run affected tests** and project quality gates (lint, typecheck, etc.)
3. **Check adjacent paths** — similar code, same pattern elsewhere
4. **Confirm no new symptoms** — fixing one race or null path did not break another

If verification fails, return to Phase 2 — the first fix may have addressed a symptom.

---

## Output format (default)

Keep responses lean unless the user asks for depth:

```markdown
## Root cause
…

## Evidence
- …

## Fix approach
[what changes, at which layer, and why this is not a patch]

## Verification
- …
```

---

## Related skills

- Production errors with Sentry → `sam-root-cause-debugging`
- Implementing Sentry fixes after confirmation → `sentry-fix-issues`
- Project quality gates before finishing → project `code-quality-checks` or equivalent
