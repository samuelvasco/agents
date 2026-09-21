---
name: sam-triage-sentry-list
description: >-
  Read-only triage of every Sentry issue in the current view — verify each against real
  evidence (stack trace, source, logs, PostHog, Linear, Slack) and classify as Discard /
  Real Bug / Needs More Investigation. Use when asked to triage, sweep, or review a Sentry
  issue list or saved view.
disable-model-invocation: true
---

Triage every Sentry issue in the current view. Read-only — do not modify, resolve, or comment on any issue, and do not create tickets.

Rules:
- No assumptions. Every claim must be backed by evidence you actually pulled (stack trace, source line, logs, config, product data) — not inferred from the title.
- Be skeptical. Treat each issue's message as a hypothesis to verify, not a fact.
- No hallucinated file paths, line numbers, or causes. If you didn't open and confirm it, don't cite it.
- Default to "Needs more investigation" whenever evidence is incomplete or ambiguous.

Steps:
1. List every issue in the view — no skipping or sampling.
2. Pull full stack trace, frequency, first/last seen, release, tags, breadcrumbs for each.
3. Group issues sharing a trace ID or root cause; state the matching evidence.
4. Spawn one sub-agent per issue/group to independently gather evidence and trace root cause through the actual source code. Sub-agents report evidence, not just conclusions.
5. Pull supplementary context where it helps confirm or rule out a root cause, and cite it as evidence:
   - PostHog: user impact, session/replay count, feature flag state, funnel drop-off tied to the error.
   - Linear: existing issues/tickets referencing the same error, past fixes, known-issue status.
   - Slack: prior discussion in eng channels, known flaky services, deploy/incident context around when the error started.
   Only pull from these when Sentry data alone is insufficient — skip for issues already clearly resolved by stack trace + code.

Classify each issue/group into exactly one category:
- Discard / No Action — ONLY if you have direct confirming data (e.g. traced code shows the exception is caught/expected, PostHog shows zero user impact, Linear/Slack confirms it's a known non-issue, logs show it self-resolved as expected behavior). Never use this category on the basis of a title looking benign or an assumption that it's "probably noise."
- Real Bug — root cause proven via code + trace, include faulting snippet and proposed fix/mitigation (describe only, do not implement or ticket).
- Needs More Investigation — evidence is incomplete, inconclusive, or contradictory; state exactly what's missing to reach a verdict.

Output: one summary per group/issue — category, evidence (including any PostHog/Linear/Slack findings used), root cause + snippet (if Real Bug), and recommended next step.
