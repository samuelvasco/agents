---
name: sam-simplify
description: >-
  Iteratively simplify implemented code by cutting unnecessary abstractions,
  flattening control flow, tightening types, and clarifying domain naming while
  preserving correctness and repo patterns. Use after implementing a feature or
  fix, before opening a PR, or when asked to simplify, clean up, or declutter code.
---

# Simplify

Actively refactor the target code (default: current branch/uncommitted diff and touched functions); leave code outside it alone. Apply section 2 (Simplicity & necessity) of `../sam-implementation-quality-review/SKILL.md` throughout.

## Hard Guardrails

- **Never trade correctness or safety for fewer lines** — preserve real boundary validation, auth, idempotency, transaction locks (`select_for_update`), and documented concurrency guards.
- **Clarity beats brevity** — no nested ternaries, clever one-liners, or dense comprehensions that hurt readability.
- **Ask first** before changing public APIs, schemas, or migrations, or dropping a feature path.

## Iterative Loop

First read the intent (ticket, PR description, or plan). Then repeat **Pass → Refactor → Verify** until a pass makes zero changes, max 3 rounds. Verify means lint, typecheck, and tests on touched files; revert any change that breaks them.

1. **Necessity** — Delete anything without a current caller or required invariant. Match how the repo already solves the same problem and reuse its implementation instead of adding new or duplicate code.
2. **Control flow** — Guard clauses and early returns over nested `if`/`else`. Name arbitrary-looking conditionals as predicates that state _why_. One level of abstraction per function.
3. **Types & data shapes** — Replace untyped dicts, `Record<string, any>` / `dict[str, Any]` bags, and tuple soup with typed models, dataclasses, or interfaces. Drop defensive `??`, `.get()`, and `try/catch` for guarantees enforced upstream.
4. **Naming & bounds** — Rename vague identifiers (`data`, `res`, `item`, `temp`, `process`) to their domain role. Give non-obvious limits, timeouts, and caps a named constant or why-comment.

Finish with a summary of what each round simplified and anything kept on purpose.
