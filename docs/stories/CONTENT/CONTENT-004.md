---
id: CONTENT-004
rail: CONTENT
title: Prose decluttering pass: reduce em-dash overuse and repetitive phrasing
status: draft
phase: "2"
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
  - gap-handoff.html
  - README.md
touches:  # If this story changes any documented architecture, add docs/architecture.md to this list.
---

## Requires

- Same bundle-format handling as CONTENT-001 for the two HTML files. `README.md` is
  plain markdown, no unpacking needed.
- Best run last among the CONTENT stories, since it edits prose across the whole
  document rather than isolated sections — running it before the factual fixes land
  means re-touching sentences that CONTENT-001/002 also change.

## Ensures

No stock LLM filler words present (delve, leverage, robust, seamless, "it's worth
noting") — a scan found none, so this is a non-goal; don't introduce any. The two real
issues to fix:

- Em-dash overuse: dashes that splice two independent sentences are replaced with a
  period; dashes introducing a consequence are replaced with "so" or a colon. Dashes
  used as inline glosses in table cells/diagram labels (e.g. "TCP only — no unix
  sockets") are left alone. Target: no more than one em dash per paragraph of running
  prose. Specific known instances (apply the same judgment to any others found by
  scanning for `—` in the unpacked text):
  - index, Overview: "The operator owns all infrastructure — there is no dependency on
    Vercel, Supabase, or any managed platform, and no billing code in the repo." → split
    into two sentences.
  - index, Overview (three-layer rule): "...deny list — but reviewers check it too." →
    "...deny list, and reviewers check it too."
  - index, Process supervision: "...refuses to boot against an unmigrated database — a
    feature, not a bug." → "...refuses to boot against an unmigrated database. This is
    intentional."
  - index, Process supervision: "...as long as both point at the same database — but one
    is all a single host needs." → "...same database. One is all a single host needs."
  - index, Backup intro: keep "A restorable forqsite installation is four assets, not
    one." and "A backup on the same disk as the database is a deferred outage, not a
    backup." as-is; rewrite "you do not have backups — you have files." plainly, e.g.
    "Keep at least one copy off the host."
  - index, Provider lifecycle: "There is no runtime plugin loading — by design." →
    "There is deliberately no runtime plugin loading."
  - index, Architecture: "...database and env — treat it as part of the deployable
    unit..." → "...database and env. Treat it as part of the deployable unit..."
  - index, Pipeline: "Amber flags mark where the current repo blocks or misleads — each
    maps to a work item in the gap handoff." → period instead of dash.
  - gap-handoff, GAP-006/GAP-011: both use a near-identical "exactly the case ... exists
    to catch/covers" construction — reword one of them.
- Word-tic "silently" (appears ~6 times across both files): keep it where silence is the
  actual failure mode (e.g. the scheduler-down email case, a pack that never loads);
  vary or drop it elsewhere — e.g. "silently loses every uploaded image" → "loses every
  uploaded image with no warning".
- index's Overview callout label "DEEP DIVE" is renamed to something plainer (e.g. "FULL
  REFERENCE").
- README.md's line "...no server, no database, no build step — so the docs stay
  available precisely when a forqsite instance is down and you need them most." is
  split/simplified to drop the rule-of-three-plus-"precisely...most" flourish while
  keeping the same meaning.

## Instructions

This is a prose-quality pass, not a content-accuracy pass — don't change facts here
(that's CONTENT-001/002's job). If a sentence you'd otherwise rewrite is also factually
wrong, flag it rather than fixing both at once, so the correction is traceable to the
right story.

## Tests

- JSON round-trip check on both HTML files after editing.
- Grep for `—` count in the decoded text before/after — should show a real reduction
  outside of table cells/diagram labels, not just the named examples above.
- Grep confirms "silently" no longer appears 6 times unchanged in the same six original
  spots.
