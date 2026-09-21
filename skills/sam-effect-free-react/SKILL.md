---
name: sam-effect-free-react
description: >-
  Audit, refactor, or write React / React Native code without unnecessary useEffect.
  Classifies every effect against the decision tree, blocks ref-guard patches and
  mount-time payment/API starts, and recommends the correct replacement (derive, key,
  handler, mutation callback, query, useSyncExternalStore, or legitimate external
  subscription). Use when reviewing hooks, refactoring data flows, or the user mentions
  useEffect, derived state, or side effects.
---

**Arguments:** `[audit | refactor | write — defaults to audit] [PR | branch | git range | file path — defaults to working diff]`

Apply **effect-free React** to this task. Read
**`.cursor/skills/effect-free-react/SKILL.md`** when it exists in the repo;
otherwise follow the decision tree and rules below (shareable for any React or
React Native project).

Mode: first token of **$ARGUMENTS** if it is `audit`, `refactor`, or `write`;
otherwise **`audit`**. Remaining args (or all args if no mode token) are the
target: PR number, branch, `A..B` range, file path, or omitted for
`git diff HEAD` + `git diff --cached` on `*.ts` / `*.tsx` / `*.jsx` / `*.js`.

## The one question

> Is this synchronizing with an **external** system, or can I solve it another way?

If another way exists, do not add or extend an effect.

## Decision tree (stop at first match)

| # | Situation | Solution | Effect? |
|---|-----------|----------|---------|
| 1 | Value from props/state/query | Derive inline; `useMemo` only if expensive | No |
| 2 | Reset local state when entity changes | `key` on child / remount screen | No |
| 3 | User tapped / submitted | Event handler | No |
| 4 | Toast, nav, analytics after mutation | `onSuccess` / `onError` on `mutate()` | No |
| 5 | Server data | Query hook (e.g. TanStack Query) or project fetch layer | No |
| 6 | Notify parent of child change | Callback in event handler | No |
| 7 | Parent ↔ child sync | Lift state or controlled component | No |
| 8 | Module-level or external store read | `useSyncExternalStore` | No |
| 9 | Subscription (AppState, keyboard, resize, …) | Named hook + cleanup | **Yes** |
| 10 | Third-party SDK setup | Named hook + cleanup | **Yes** |
| 11 | Timer / interval / focus on mount | Named hook + cleanup | **Yes** |
| 12 | Screen-view analytics (display-only) | Named hook, fire-and-forget | **Yes** |

Rows 9–12 are legitimate. Everything else is a smell.

## Non-negotiable rules

1. Derive at render — never `useState` + `useEffect` for computed values.
2. `key` resets — not an effect that clears form state on param change.
3. Handlers own user logic — not an effect watching a submitted flag.
4. Mutation callbacks — not `useEffect` on `isSuccess` / `isError`.
5. Query hooks for fetch — not `useEffect` + fetch + `useState`.
6. `useSyncExternalStore` for external stores — not an effect polling module state.
7. No effect cascades — A sets state → B runs → C runs.
8. **Banned:** ref guards (`hasRunRef`, `didInitRef`, …) to gate effects. Refactor via the tree, never patch.

**Payments / money paths (if applicable):** never start charges, transfers, or
terminal collection in `useEffect`. User commit → handler → `mutate()` /
`startPaymentFlow()`. Processing screens observe in-flight work; they do not
start it on mount. Idempotency keys: once on commit, reuse on retry — never in an effect.

## Mode behavior

### `audit` (default)

1. List every `useEffect` in the target (changed files + enough surrounding context).
2. Classify each: tree row, legitimate (9–12) or smell (1–8).
3. For smells: `file:line - problem -> fix (tree row #)`.
4. Flag ref guards, effect chains, mutation watchers, mount-time API/payment starts.
5. Surviving effects must live in **named hooks**, not raw in screen bodies.

Output:

- One-line summary (effect count, smell count).
- Findings: **CRITICAL** / **IMPORTANT** / **NIT** (`file:line - problem -> fix`).
- Per-effect table: `file:line | row # | legitimate? | recommendation`.
- Final line: `VERDICT: PASS` or `VERDICT: BLOCK` (BLOCK if any CRITICAL or new smell in touched code).

Report only; do not edit. Run `/triage` before fixing if other reviewers ran.

### `refactor`

1. Audit per above.
2. Replace every smell (rows 1–8) with the tree solution.
3. Encapsulate legitimate effects (9–12) in named hooks with cleanup.
4. Match project stack: TanStack Query for server state, zustand/context for client UI,
   router/navigation params for screen state — read sibling files before inventing patterns.
5. If repo has `.cursor/skills/effect-free-react/anti-patterns.md` and
   `modern-patterns.md`, use them for before/after and local examples.

### `write`

When adding or changing hooks/components: run the one question and tree **before**
writing `useEffect`. Default to no effect. Only add rows 9–12, in a named hook.

## Quick smell → fix

| Smell | Fix |
|-------|-----|
| `useEffect` + fetch + `useState` | Query hook |
| Effect watching `mutation.isSuccess` | `mutate(payload, { onSuccess })` |
| Effect deriving state | Inline or `useMemo` |
| Effect resetting on param change | `key={entityId}` |
| Effect syncing query → store | Read query in UI; sync in `onSuccess` |
| Effect on user action | `onPress` / `onSubmit` |
| Effect chain A → B → C | Single handler or promise chain |

Canonical source: [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect).
