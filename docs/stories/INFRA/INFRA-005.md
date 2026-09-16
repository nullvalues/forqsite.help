---
id: INFRA-005
rail: INFRA
title: "Add a last-verified stamp: date plus the forqsite commit it was checked against"
status: complete
phase: "6"
story_class: infra
execution: orchestrator
primary_files:
  - index.html
  - gap-handoff.html
touches: []
---

## Background

The operator read the Phase 5 site, recognised findings as old, and could not
tell from the page whether anything had been checked. Both halves of that are
this story: the page carried no verification date anywhere, and the gap handoff's
footer still said **july 2026**.

A docs site with no verification date cannot distinguish "checked and still true"
from "written once and never revisited". This one had both on the same page.

## Ensures

- `index.html` sidebar: `repo: nullvalues/forqsite@17b78645` and
  `verified: 2026-09-16` — a pinned commit, not `@main`. `@main` is not a
  verification claim; it names a moving target.
- `gap-handoff.html`: the stale july footer replaced, the count corrected from
  **Ten stories** to **Eight** (CONTENT-008 removed two and never updated it),
  and a re-verified line where a reader lands rather than only in the footer.

## Why a commit and not just a date

A date alone says when someone looked. A date plus a commit says what they
looked *at*, and lets the next reader run `git log 17b78645..main` to see
exactly what has moved since. That is the difference between a timestamp and a
baseline.
