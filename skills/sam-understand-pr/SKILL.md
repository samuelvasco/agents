---
name: "sam-understand-pr"
description: "Deeply understand a PR — its real motivation, what it does, whether it fixes the root cause, and its risks."
---

You are reviewing a pull request. Your job is NOT to rubber-stamp it — it's to understand it as deeply as a senior engineer who has full context on the codebase, the team's history, and the incident/product landscape. Be skeptical by default. Assume every PR could be a patch masquerading as a fix until proven otherwise.

## Target

PR: $ARGUMENTS
(If no PR is given, use the PR for the current branch / most recently opened PR.)

## Step 1 — Read the code

- Pull the full diff, not just the summary. Read every changed file in the context of the surrounding file, not in isolation.
- Trace the change through the codebase: what calls this code, what does it call, what breaks if this is wrong.
- Check git blame / history on the changed lines — has this area churned a lot? Is this the 3rd patch to the same bug?
- Note any tests added/removed/changed and whether they actually cover the claimed fix.

## Step 2 — Gather context (only what's needed — don't boil the ocean)

Search in this order, stop early if you already have a clear answer:

1. **The PR description, commits, and linked issues** — the first and best source of truth.
2. **Linear** — find the linked ticket or search by keywords from the PR title/files. Pull the original problem statement, acceptance criteria, and any comments debating the approach.
3. **Sentry** — search for errors/exceptions tied to the affected files or feature. Is this PR fixing a real production error? Check frequency, first-seen date, and whether it's still occurring.
4. **PostHog** — check for relevant usage data, feature flags, or funnels touching this area. Does the data support the stated motivation (e.g. "users are dropping off here")?
5. **Slack** — search for discussion threads referencing the ticket, the feature, or the author's name around the PR's creation date. Look specifically for disagreement or "let's just ship X for now" language.
6. Only pull in other sources (Notion, Confluence, past PRs) if the above leaves a real gap.

Cite what you find plainly (e.g. "Linear ENG-482: ..." / "Sentry: 340 events since June 2"). If a source has nothing relevant, say so in one line and move on — don't pad the report.

## Step 3 — Produce the report

Keep it lean. Bullet points over paragraphs. No filler, no restating the diff line-by-line.
```markdown
# PR Understanding: <title>

## TL;DR
One or two sentences: what this does and whether it's the right fix.

## Why it exists
- The actual problem (cite Linear/Sentry/PostHog/Slack)
- Who's affected and how badly
- Any conflicting signals across sources (e.g. Linear ticket says X, but Slack thread wanted Y)

## What it does
- Bullet-point walkthrough of the change, grouped by concern (not by file)
- Key code snippets (only the lines that matter, with just enough surrounding context)
- A simple diagram (mermaid) if the change affects flow/architecture/state — skip if not useful

## Root cause vs. patch — the verdict
Answer directly: **Root-cause fix / Reasonable patch / Band-aid**
- What the root cause actually is, if different from what's being fixed
- If it's a patch: what the "clean" fix would look like, and why it's more effort/risk/scope
- Is the extra effort actually justified right now, or is the patch fine as an interim step?

## Fit with existing code
- Does this follow existing patterns, or introduce a new one? If new, is that intentional/documented?
- Any duplicated logic, dead code left behind, or inconsistency introduced?

## Risk analysis
- **Security**: new attack surface, auth/permission changes, secrets/data exposure, injection risk
- **Performance**: hot path? N+1s, added latency, memory, bundle size
- **Reliability**: error handling, edge cases, rollback safety, feature-flag coverage
- **Maintainability**: readability, test coverage, documentation debt introduced

## Open questions for the author
- The 2-4 sharpest questions that would reveal whether this was thought through
```

## Ground rules

- Be concrete. "Could have performance issues" is not useful; "this runs inside a loop over N users, was O(1) before, now O(n) DB calls" is.
- If you can't verify a claim (e.g. no Sentry data, no Linear ticket linked), say so explicitly instead of assuming good faith.
- Prefer diagrams only when they clarify flow/state/architecture — don't diagram a one-line change.
- Total output should be scannable in under 2 minutes. Cut anything that doesn't change the reader's judgment of the PR.
