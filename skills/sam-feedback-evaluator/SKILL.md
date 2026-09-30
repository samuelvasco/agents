---
name: sam-feedback-evaluator
description: >-
  Validates PR comments and architectural suggestions against project patterns,
  rules, and implementation quality. Skeptical by default — separates actionable
  feedback from noise. When the PR is in a Graphite stack, evaluates against the
  whole stack (especially upstack PRs) so feedback is not re-litigated or fixed
  in the wrong layer. Use when reviewing PR threads, reviewer comments, or
  architectural suggestions before acting on them. Only evaluates open threads —
  skip resolved or outdated review comments. Validates merge readiness (up to date,
  no conflicts) once at the end — does not poll CI or subscribe to updates.
disable-model-invocation: true
---
 
# Feedback Evaluator
 
Filter technical feedback against **this repo's** rules, patterns, and implementation quality. **Review-first** — implement only what [Acting on verdicts](#acting-on-verdicts) permits.
 
## Constraints
 
- **Open threads only** — evaluate unresolved PR review comments only. Skip threads marked resolved or outdated. Do not re-litigate closed feedback. "Already addressed in the diff" applies to the **exact defect** (crash, missing field), including fixes that live only in **upstack** Graphite PRs — not to the product question that defect implied.
- Include the **whole comment** when referencing a thread.
- **Skeptical by default** — burden of proof is on the suggestion. Default verdict is [NO-ACTION] until the investigation below turns up concrete evidence otherwise.
- **Investigate before verdict** — never categorize from the comment text alone. Confirm against actual code (`path:line`) and repo patterns via the sub-agents, even when the suggestion sounds reasonable or the reviewer sounds confident.
- **Stay in scope** — default unit of work is **this PR's diff only**. A fix is the smallest change that resolves the comment, in files the PR already touches. New files, renames, refactors of untouched code, dependency changes, or edits outside the diff are out of scope: report them, don't do them. **Graphite stacks override scope for verdicts, not for drive-by edits:** if the same concern is already handled in an **upstack** PR, do not widen this PR to match — verdict [NO-ACTION] or defer with the upstack PR cited. If feedback belongs in a child PR (helper only used upstack, follow-on refactor), say so — don't over-engineer the current layer.
- Ambiguous context → ask the user; do not guess.
- Evidence only: rule path, `path:line`, or existing codebase pattern — not "best practice."
- **No open questions** — every comment must resolve to a definite answer. "Might be an issue," "worth checking," or "unclear if this matters" is not a verdict; keep investigating (re-run sub-agents, read more of the surrounding code, trace further call sites) until the question is actually settled. If something genuinely cannot be resolved from the repo, say precisely what's missing and ask the user — never hand the user an unresolved thread dressed up as a conclusion.
- **Write for a person, not a brief.** Short, natural sentences. Name the file and what it does in one clause, then say what that means for the comment — do not make the reader assemble the argument. No jargon without a plain-English gloss. No dumps of every file you opened. Repeat nothing the quote or verdict already said.
## Graphite stack (when applicable)

Before categorizing comments, determine whether the evaluated PR sits in a **Graphite stack**. If `gt` is available in the repo checkout, run `gt log short` (or `gt ls`) from that repo and map each branch to its GitHub PR (`gh pr view --json number,title,url,headRefName,baseRefName`). Read the repo's stacked-PR skill if present (e.g. `.cursor/skills/stacked-prs/SKILL.md`).

Treat **upstack** PRs (descendants above the current branch) as part of the evidence surface:

- **Already handled?** (cost–benefit #4) — search this PR's diff **and** upstack PR diffs/commits for the named defect, guard, refactor, or test. A fix only in an upstack PR still counts as handled for this thread; say which PR and do not implement again here.
- **Scope / over-engineering** — reject feedback that would duplicate work already in upstack PRs, or that demands abstractions, helpers, or refactors that only exist for code introduced **above** this PR in the stack.
- **Still open on this PR** — if nothing upstack addresses the thread and the comment targets code this PR owns, evaluate normally; do not defer to a hypothetical follow-up.

When stack context matters, pull upstack diffs with `gh pr diff <number>` (or branch comparisons) and cite `path:line` from the PR that actually contains the fix. Mention stack position once in the opening **VERDICT** line (e.g. current PR #N, upstack #M–#K checked).

## Orchestration
 
Spawn **parallel** Task sub-agents before categorizing:
 
1. **Pattern Scanner** (`explore`) — how similar problems are solved today; return paths + snippets.
2. **Rule Checker** (`explore`) — relevant `.cursor/rules/` and domain skills for the topic.
3. **Coupling analyzer** (`explore`) — only when feedback proposes structural moves; trace imports/boundaries.
4. **Security reviewer** (`explore`) — always run. Check whether the current code or the suggested change introduces, removes, or leaves unaddressed a security risk: auth/authz, input validation, injection, secrets handling, permissions, data exposure. Cite `path:line` for any finding.
5. **Regression checker** (`explore`) — always run. Trace call sites, downstream consumers, and existing tests for the code the feedback targets; flag if accepting or dismissing the suggestion would break current behavior elsewhere.
6. **Stack scout** (`explore`) — run when `gt log short` shows more than one branch in the stack. For each **upstack** PR, summarize whether open review threads on the **current** PR are already addressed there; return PR numbers, titles, and `path:line` in the fixing PR.

Detect repo from paths (`react-native/`, `web-app/`, `api/`). For quality bar details, read [implementation-quality-review](../sam-implementation-quality-review/SKILL.md) — apply its criteria when judging whether feedback is valid.
 
**Depth requirement:** sub-agent output is a starting point, not the finish line. If a sub-agent's first pass is thin, contradicts itself, or leaves the actual question ("is this reachable," "is this already guarded," "does this pattern exist elsewhere") unanswered, re-dispatch it with a sharper prompt or read the files directly. A verdict is only ready to write once every claim in it — on both sides, the reviewer's and yours — has been checked against real code, not inferred from naming or intuition.

**Don't stop at the symptom.** A crash, null deref, or missing guard is the surface. After you confirm whether it still fires, ask what object hit that path and whether it belongs in this product flow (assignable, payable, listed, guest-visible). A new 422 that prevents the crash answers the crash only — verdict the domain question separately. If the repo cannot settle "should this object be here?", ask the user.
 
## Cost–benefit test (every item)
 
1. **Real problem?** Bug, security risk, regression, rule violation, race — vs speculation.
2. **Proportional severity?** Impact, not review tone.
3. **Material impact?** Cosmetic-only or theoretical → reject. A same-queryset `select_related` / `prefetch_related` (or equivalent free fetch) **is** material — the API N+1 lens. Accept as [SUGGESTION] when it adds no branching, files, or abstractions.
4. **Already handled?** Types, guards, existing patterns, or an **upstack stack PR** may cover the **named defect**. A guard that 422s a state does not answer whether that state should be in the flow.
5. **Justified by a current need?** Reject speculative future-proofing for scenarios that don't exist in this diff or codebase today.
6. **Integrator / published contract?** Stricter matching, validation, or side-effect ordering may satisfy a bot but break documented Foundation or external API behavior. Check OpenAPI `help_text`, domain skills (e.g. `foundation-api`), and existing external tests before accepting; prefer parity with established main-api flows over new edge cases.
## Categories
 
| Category         | When                                                                                                                                  |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **[CRITICAL]**   | Confirmed bug, security/data risk, banned pattern, or clear rule violation with real impact. Block merge.                             |
| **[SUGGESTION]** | Valid improvement aligned with conventions **and** passes cost–benefit. Same-queryset `select_related` / `prefetch_related` with no extra branching, files, or abstractions is always this — not [NO-ACTION]. Non-blocking.                                                 |
| **[NO-ACTION]**  | Preference, unproven theory, over-engineering, disproportionate effort, no material impact, or contradicts patterns. **Most common.** |
 
### Reject as [NO-ACTION] when feedback
 
- Invents problems without evidence
- Demands abstractions for one call site
- Confuses preference with correctness
- Over-DRY that increases coupling
- Drive-by large refactors on a small PR
- Defensive code for impossible states (types/router/guards already exclude). Does not apply to the product question behind that state (e.g. a 422 on walletless still leaves "should this object be assignable / payable?")
- Premature memoization without profiling
- Patches over smells (ref-gated effects, mount-started user flows) instead of refactor
- Extra layers, single-use utilities, or `??` chains for values guaranteed upstream
- No material or observable effect on behavior, risk, or maintainability — **not** a missing `select_related` / `prefetch_related` on a query this code already runs and then dereferences
- Speculative future-proofing with no concrete current use case
- Cosmetic reordering (e.g. alphabetizing an existing list) with no stated reason — it inflates the diff and review surface for no benefit; only accept if the comment justifies why order matters here (e.g. lookup performance, a lint rule, avoiding merge conflicts)
- Asks to fix or refactor in **this** PR when the same concern is already handled in an **upstack** Graphite PR, or asks to delete/move code that **upstack** PRs depend on
### Quality lenses (from implementation-quality-review)
 
When feedback touches these, verify against code — cite `path:line`:
 
- **Security** — weigh real, evidenced risk seriously (auth, injection, secrets, data exposure, permissions) and don't wave it through as "minor." But don't invent threat models either — a security claim needs a concrete exploitable path or a rule violation, same evidence bar as everything else. "Could theoretically be misused" without a reachable path is [NO-ACTION], not [CRITICAL].
- **Simplicity** — every abstraction must earn its place; inline if one call site
- **Effects/refs (frontends)** — flag ref-gated effects, mount-started auth/pay/submit, mutation `isSuccess` watchers; prefer handlers, derive-at-render, Query hooks
- **Architecture** — one way per concern (Query vs zustand, hooks vs screen logic, `operations/` vs views)
- **Concurrency** — double-submit, parallel mutations, stale reads; sync refs only with documented reason
- **API** — logic in `operations/`, `select_for_update` + reassign, N+1 (missing `select_related` / `prefetch_related` on a row you immediately dereference counts — not only for-loops), silent early returns
- **Tests** — behavior not trivia; no theater assertions
## Acting on verdicts
 
**Default (no human gate):** in-scope bot [CRITICAL] and accepted [SUGGESTION] fixes, [NO-ACTION] dismissals, and stack deferrals — implement (or reply-only), **push the branch**, reply on each thread, then resolve.

- **Human threads** — never reply, never resolve, never implement. Evaluate, and hand the verdict to the user to act on.

**Ask the user before implementing when** the fix would **materially expand scope** (files outside this PR's diff, new modules, refactors, deps/config), **change published/API or shared behavior** (see cost–benefit #6), or **diverge from repo patterns** without hard evidence the existing pattern cannot work. Routine in-diff fixes, N+1 fetches, guards, and convention-aligned tweaks: do not wait. Never silently widen the PR.

- **Bot threads** (CodeRabbit, Copilot, Cursor Bugbot, etc.) — apply fixes or reply (what changed, one-line dismiss, or defer to upstack PR #X); never resolve without replying.
- **Stack deferral** — no duplicate fix on this PR when upstack already has it; reply that it lives in PR #X, resolve. Do not delete or reshape code upstack PRs depend on — flag stack layering instead.
- **Push & merge readiness** — after any code change, commit and push. At **end of the run**, **once** (no polling, no waiting on checks, no live subscriptions): confirm the PR is **up to date with its base** and **mergeable** — no merge conflicts (`gh pr view --json mergeable,mergeStateStatus,baseRefName`; `mergeable` not `CONFLICTING`, not stuck `BEHIND` without updating). Rebase/merge onto the target as the repo normally does; on Graphite stacks, restack only per the repo stacked-PR skill — **do not** run stack-wide `gt sync` that force-pushes under active review without user approval. If still not mergeable after that, report what blocks (conflicts, base drift) — do not babysit CI.
## Output format
 
List only — **no tables**. One short block per **open** comment, in thread order. Omit resolved/outdated threads entirely.

Aim for **one short paragraph** after the verdict: what the reviewer is pointing at, what the code actually does (`path:line`), and therefore what we should do. Connect those three in the same breath. If a snippet helps, use **one** short real excerpt — not two, not a tour.

````markdown
## Feedback Evaluation
 
**VERDICT:** ADDRESS | OPTIONAL | DISMISS — [one line]
 
---
 
### 1. [CRITICAL | SUGGESTION | NO-ACTION]
 
> [full comment text]
 
**Verdict:** [Fix before merge | Worth doing | Dismiss]
 
[Plain paragraph. No Context/Why headers.]
 
```language
// only if it earns its place
```
 
**Action:** [done: pushed, thread resolved (bot) / deferred to upstack PR #N (bot) / **needs you:** scope, API/behavior, or pattern — Y / for you to decide (human reviewer) / none]
 
---
 
### 2. ...
````
 
- End with **VERDICT:** `ADDRESS` if any CRITICAL; `OPTIONAL` if only SUGGESTION; `DISMISS` if all NO-ACTION.
## Definition of done
 
1. Only **open** threads reviewed; resolved/outdated threads excluded
2. Every evaluated comment quoted in full
3. Each verdict backed by rule, pattern, or `path:line` — not opinion, and with no open question left dangling
4. Each block is easy to read in one pass: the paragraph already connects the comment to the code to the verdict — no leftover dots for the reader to join
5. Actionable items include minimal code, not drive-by refactors
6. Bot threads: in-scope fixes applied, each thread replied to and resolved. **Human threads:** evaluated only — never replied to, resolved, or implemented, regardless of verdict
7. In-scope bot work **pushed**; **one** merge check: PR **up to date with base**, **no merge conflicts**, `mergeable`/`mergeStateStatus` clean — or blockers reported. Nothing outside this PR's diff without user approval. No CI polling or live update subscriptions
8. Graphite stack: upstack checked before implementing here; no duplicate fixes on the wrong layer