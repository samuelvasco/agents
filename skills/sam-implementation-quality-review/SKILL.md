---
name: "sam-implementation-quality-review"
description: "Thorough implementation quality review across the Truss monorepo (react-native,
  web-app, api) — simplicity, clean architecture, no overengineering, no race
  conditions, effect-free React on frontends. Use when finishing a feature, before
  merge, or when the user asks for a quality pass. Read every touched file
  block-by-block; do not skim."
---

# Implementation Quality Review

## Principles

- Be thorough. Explore **every code block** in scope — no skimming, no assumptions.
- Prefer the **simplest correct** solution. Every line must earn its place.
- **Clean architecture over patches.** Refactor smells; do not add guards to mask them.
- Keep the review **lean**: findings only, grouped by severity — no filler prose.

## When to use

- Before declaring work done or opening a PR (any subrepo)
- After a non-trivial change where correctness and simplicity matter
- When the user asks "is this good enough?" or wants a quality pass

**Review-first:** do not implement fixes unless the user asks.

## Detect repo & load local rules

Determine the repository from the actual checkout. Read its applicable `AGENTS.md` files and follow their authoritative rule and skill locations; do not assume legacy `.cursor/` paths. Load only the relevant domain guidance, including effect-free React for frontend effects and the repository's coding and testing rules.

Do not duplicate full rule files — cite violations with `path:line`.

## Review workflow

```
Quality review:
- [ ] 1. Inventory — every touched file + callers/callees one level deep
- [ ] 2. Simplicity — delete-or-justify every abstraction, helper, branch
- [ ] 3. Side effects — effects/refs (frontends) or I/O boundaries (API)
- [ ] 4. Architecture — repo conventions; one way to do each thing
- [ ] 5. Concurrency — double-submit, parallel calls, stale data, races
- [ ] 6. Necessity — no overdefensive code for impossible states
- [ ] 7. Tests — behavior covered; no theater assertions
- [ ] 8. Verdict
```

### 1. Inventory

- List **every** file in the changeset (not diff-only hunks)
- Open each file; read full functions/classes touched
- Follow cross-file behavior one level up (caller) and down (callee)
- Include matching tests when behavior changed

### 2. Simplicity & necessity

Use this rubric during planning, implementation, and review:

- **Current necessity:** For each added field, option, branch, helper, and dependency, identify its present consumer, required behavior, or invariant. Remove speculative collection and duplicated logic; reuse the owning implementation.
- **Domain names:** Functions name an action or predicate and its subject; variables name their domain meaning, including private helpers and local values. A reader should follow the flow without reverse engineering it. Do not introduce opaque names such as `_identity`, `_family`, or `_local_family`; name the actual snapshot, related transactions, or check.
- **Reachable defenses:** Identify the reachable failure and check the actual upstream guarantee before adding validation, fallbacks, retries, or state comparisons. Type annotations alone do not validate runtime input. Validate untrusted input at its owning boundary; do not repeat checks already enforced there or invent impossible states. Preserve required authorization, payment, idempotency, and concurrency safeguards.
- **Useful separation:** A single-use helper can name a domain step, isolate I/O, or improve readability. Reject pass-through wrappers and premature generic utilities, not helpers based on call count. Trace actual imports and responsibilities before claiming coupling; split or combine only when it clarifies ownership or removes duplication.
- **Explained bounds:** Give non-obvious numeric limits, timeouts, and traversal caps a short nearby why-comment or source. State the real tradeoff when a value is a chosen default; do not invent a provider guarantee. Follow the repository's comment conventions.

For each finding, identify the unnecessary mechanism, the smallest useful alternative, and why required behavior and safeguards survive. PASS is valid when nothing needs changing; do not invent findings to fill a quota.

**Overengineering:** generic hooks/components with unnecessary configuration or indirection, unused options, parallel paths that could share one primitive, defensive `??` / `get()` chains for values already guaranteed upstream.

**Overdefensive:** checks after early return; catch-all handlers for impossible states; retry loops without a documented contract; fallback paths the router/guard already prevents.

### 3. Side effects

#### Frontends (react-native, web-app)

Classify each `useEffect` with the effect-free decision tree (project `effect-free-react` skill).

**Banned (always flag):**

- `hasRunRef` / `didInitRef` / `userSetRef` gating when an effect runs
- User-commit flows (auth, pay, submit, send) started on mount
- `useEffect` watching `mutation.isSuccess` / `isError` — use `onSuccess` / `onError`
- Props/route → state sync via effect — derive or lazy `useState` initializer
- Effect chains (A → B → C)

**Refs — allowed only with a comment explaining why state is insufficient:**

| Pattern | OK when |
|---------|---------|
| Sync re-entry guard | Async `useState` cannot block same-frame double-tap before re-render |
| Post-success idempotency | Retry a later step without repeating an irreversible earlier step |
| DOM/SDK handles | Imperative API only — not business logic |

No ref without a documented concurrency reason → flag for refactor.

**Legitimate effects:** native/SDK subscriptions, timers with cleanup, screen-view analytics — in **named hooks**, not screen bodies.

#### API (Django)

**Banned (always flag):**

- Business logic in views/serializers that belongs in `operations/`
- N+1 queries fixable with `select_related` / `prefetch_related`
- Missing `select_for_update` + stale instance after lock (reassign query result)
- Side effects inside `transaction.atomic()` that should use synchronous analytics helpers when raising
- Silent early `return` on unexpected missing data without log (see `coding-pitfalls.mdc`)

### 4. Architecture

| Layer | Mobile / Web | API |
|-------|--------------|-----|
| Server state | React Query — never fetch-in-effect → zustand/context | Models + operations; views thin |
| Client UI state | zustand / route state — not server data | N/A |
| User actions | Handlers / mutations — not mount-driven | Explicit request entrypoints |
| Boundaries | Features don't reach into each other's internals | Serializers validate; operations orchestrate |
| Money / auth | Repo money-security + domain skills | Idempotency, ledger rules, auth skills |

Flag a **second way** of doing the same thing (competing patterns).

### 5. Concurrency & races

Trace **every async path** end-to-end:

| Concern | Frontends | API |
|---------|-----------|-----|
| Double-submit | Button guards, mutation `isPending`, sync refs where documented | Idempotency keys; status gates before side effects |
| Parallel calls | Overlapping mutations, stale session/token | `select_for_update`, unique constraints, dedupe gates |
| Stale reads | Cache invalidation order, optimistic rollback | Re-fetch after lock; `refresh_from_db()` |
| Ordering | Auth gate before company-scoped queries | Transaction boundaries; outbox/sync analytics |
| Waits | Promise waiters with timeout — no hung promises | No busy-wait; bounded retries only |

No unbounded loops. No retry storms.

### 6. Error handling proportionality

- Separate user error vs network vs unexpected — use existing helpers in the repo
- Observability: report unexpected/5xx; not expected validation or user mistakes
- **Mobile:** inline errors on owning control; toast only when no surface (house rule)
- **API:** structured validation errors; log unexpected early returns with context
- Never log secrets (passwords, tokens, PAN)

### 7. Tests

- Assert **behavior** (branches, gates, side effects), not implementation trivia
- Change in logic → matching test change or explicit gap called out
- No tests that only restate types or mock return values

## Output format

```markdown
## Implementation Quality Review

**Repo:** [react-native | web-app | api]
**Scope:** [files reviewed]

### Critical (must fix)
- `path:line` — issue → minimal fix

### Important (should fix)
- ...

### Clean (explicitly OK)
- Non-obvious patterns verified (e.g. legitimate ref, lock pattern)

**VERDICT:** PASS | BLOCK
```

- **BLOCK:** any Critical item, banned pattern, race without guard, or auth/payment started on mount (frontends)
- **PASS:** only after every scoped file was read block-by-block

## Quick smell table

| Smell | Prefer |
|-------|--------|
| Effect / mount starts user flow | Event handler → async |
| Ref gates effect | Refactor via effect-free tree |
| Derived state + effect | Derive at render |
| fetch + useState in effect | Query hook |
| Mutation success watcher | `mutate(_, { onSuccess })` |
| Pass-through wrapper without a domain or boundary purpose | Inline or reuse the owning implementation |
| try/catch for control flow | Early return + typed errors |
| View does orchestration | `operations/` function |
| Duplicate client/server rule | Single source (API contract + generated types) |

## Definition of done (reviewer)

1. Every file in scope opened and read (not diff-only)
2. Each `useEffect` / `useRef` (frontends) or lock/transaction (API) classified or flagged
3. Each async handler traced for double-submit / race
4. Verdict with `path:line` citations