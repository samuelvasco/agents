---
name: sam-review-pr
description: >-
  Review a linked PR for motivation, minimal scope, pattern fit, and regressions.
  Use when the user wants a concise PR review with TLDR and actionable bullets.
---

Review the linked PR.

1. Understand the motivation behind the PR and what it does.
2. Check that the implementation is only the minimal required changes to properly address the requirements. It should prefer simplicity over complexity and have a tight scope.
3. Flag unnecessary deviations from patterns or scope.
4. Check whether there are any regressions or unintended consequences.
5. Flag defensive code that breaks this rule: Before you write defensive code, you need to understand the whole context and motivation behind the implementation and consider improving the architecture instead of adding the defensive condition. ANY DEFENSIVE CONDITIONAL MUST BE ACCOMPANIED BY A SIMPLE COMMENT EXPLAINING THE WHY AND THE NECESSARY CONTEXT

Your answer should be brief and simple to understand, giving context to the reader and using code snippets to explain the issues and the solutions.

Write a quick TLDR and a bullet point list of what needs to happen. Don't leave anything hanging; follow through with the explanation.
