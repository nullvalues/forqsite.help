---
id: INFRA-004
rail: INFRA
title: "Correct Phase 3's status row and record the re-bundle procedure in the README"
status: complete
phase: "5"
story_class: infra
execution: orchestrator
primary_files:
  - docs/phases/index.md
  - README.md
touches: []
---

## Background

Two record corrections, neither touching site content.

## Phase 3's status row

Phase 3's index row said `planned` while its only story, CONTENT-005, is
`complete` — and Phase 4 was built and completed after it. The phase was done and
never had its row flipped.

Corrected to `complete` rather than reopened. Nothing was left unbuilt: the
manifest has one story and that story is closed. Under the phase-continuity rule
a phase cannot be checkpointed with silently abandoned planned stories; the
inverse — a closed phase still advertising itself as pending — misdirects the
resolver, which picks by row order and would have returned Phase 3 ahead of this
one.

## The re-bundle procedure

`README.md`'s "Updating" section explained the sync policy but not the mechanics,
and the mechanics are the part that will corrupt an artifact if guessed. It now
documents `scripts/bundle-template.py`, the verify-first workflow, and the
`/` escaping detail — specifically the reason it exists, since a future
editor who "simplifies" the encoder will produce a file that looks fine and
truncates at the first `</script>` in the content.
