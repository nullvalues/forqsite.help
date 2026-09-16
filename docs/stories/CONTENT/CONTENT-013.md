---
id: CONTENT-013
rail: CONTENT
title: "Reframe the gap document for a human self-hoster; retire the Claude Code framing"
status: complete
phase: "7"
story_class: content
execution: orchestrator
primary_files:
  - gap-handoff.html
touches: []
---

## Background

The document was addressed to a tool, in vocabulary only this project defines.
Title "dev → prod gap handoff", h1 "Work items for Claude Code", intro "Eight
stories … acceptance criteria in the repo's story format".

Three separate problems. "Gap handoff" is internal shorthand that names neither
party nor the thing handed over. Addressing a harness assumes the reader drives
one — they may, and it is a good way to do the work, but the document must not
presume it, and naming one specific tool in the title presumes it twice.
"Stories", "acceptance criteria" and "rails" describe how this project tracks
work; a self-hoster has none of those conventions.

## What it is, once you say it plainly

A list of the places where forqsite does not yet get a competent Linux admin
from clone to a running, recoverable production instance — with enough detail
to work around each or fix it.

| Element | Now |
|---|---|
| title / eyebrow | forqsite — known gaps · SELF-HOSTERS / KNOWN GAPS |
| h1 | What isn't ready yet |
| `PROPOSED APPROACH` | HOW TO FIX IT |
| `ACCEPTANCE CRITERIA` | DONE WHEN |
| `SUGGESTED SEQUENCING` | WHERE TO START |

The intro now says who it is for and what to do with it: read it **before**
committing to self-hosting; nothing here is a blocker; but supervision and media
backup shape the deployment and are cheaper to answer now than to retrofit.

The `GAP-0NN` identifiers stay — stable, cited from the pipeline diagram, and an
identifier is not jargon.

## Two dangling references, from Phase 5

"WHERE TO START" opened with *"002 first — nothing else is verifiable on a clean
machine until a fresh clone installs"* and routed around *"011 (registry
codegen)"*. **Both were removed in Phase 5** and the sequencing prose was never
updated, so the first thing a reader was told to do referred to an item that no
longer appeared anywhere on the page.

Phase 5's and Phase 6's checks both missed it for the same reason: they asserted
on IDs in the **items array**, and this was prose. The Phase 7 check greps the
rendered text.

Rewritten to the eight that exist, and the tail — "one story per conversation,
commit after each, cold-eyes review before calling the phase done" — replaced
with the one caution that actually generalises: 003, 004 and 005 change
operator-facing behaviour, so each needs the four operator documents updated with
it or the next person reads the old answer.

## Follow-up: the sequencing block became the TL;DR

The ordering advice sat at the bottom of the page as a wall of prose in a black
panel, after eight full write-ups — which is exactly where a reader who needs it
most will never reach. It is a summary, so it belongs where a summary goes.

Moved above the priority chips, relabelled **TL;DR**, and broken into bullets:
one per grouping (003+004+005, 007, 006/008, 009/010), with the
documentation-surface caution set off below a rule rather than buried in the
final clause of a paragraph.

Same content, same panel styling. It is now readable in about five seconds,
which is the only thing a TL;DR has to be.
