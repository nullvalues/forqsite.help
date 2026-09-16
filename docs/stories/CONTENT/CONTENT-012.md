---
id: CONTENT-012
rail: CONTENT
title: "Narrow GAP-010 to what is still true; fix the priority chips"
status: complete
phase: "6"
story_class: content
execution: orchestrator
primary_files:
  - gap-handoff.html
touches: []
---

## GAP-010 was half-fixed

Re-checked against `docs/configuration.md`: `SMTP_HOST` **is** now documented, so
it is no longer part of the finding. `DEFAULT_ORG_FEATURES` is still missing, and
two keys the gap never named are missing too — `TRUSTED_PUBLISHERS` and
`REQUIRE_PACK_SIGNATURES`, which are the controls that turn signature enforcement
on. The pgvector drift (18 vs 15) and the `firstrun.sh` `db:bootstrap` mismatch
are both still real. Narrowed to exactly that.

GAP-003 through GAP-009 were re-verified line by line and every cited piece of
evidence still matches the source. None changed.

## A defect this story shipped in Phase 5 and had to come back for

The priority chips at the top of the gap handoff are **hardcoded in the markup**,
not computed from the items array. CONTENT-008 removed GAP-002 (the only P0) and
GAP-011 (a P2) without touching them, so the live page advertised:

- **P0 — BLOCKS FRESH CLONE × 1** for a priority with zero items, and a chip
  whose click handler resolved to an undefined anchor, so it scrolled nowhere.
- **P2 × 4** against three actual items.

The P0 chip is the worse half: it told every reader the project had an open
blocker preventing a fresh clone, which is the single most alarming thing the
page can say, and it was false — CONTENT-008 had just fixed that very item.

Phase 5's render check missed it because that check asserted on **gap IDs**, and
the chips contain none. The Phase 6 check now asserts chip text and counts
directly.

P0 chip removed; P2 corrected to 3.

## And one this story broke before catching it

The first attempt at narrowing GAP-010 sliced the `mk()` call to the next `',\n`
and swallowed an argument boundary, leaving `evidence` bound to a string. The
page died on load with `evidence.map is not a function` — **every gap invisible**,
not a cosmetic break.

Static validation passed it. The render caught it, which is twice now that
rendering has found what structure checking could not. The fix was to revert to
the committed file and replace only the quoted problem-string argument by its
exact bounds, honouring `\'` escapes, rather than slicing on a delimiter that
also appears inside the data.
