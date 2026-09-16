---
id: CONTENT-015
rail: CONTENT
title: "Re-point every cross-reference to the renamed document"
status: complete
phase: "7"
story_class: content
execution: orchestrator
primary_files:
  - index.html
  - README.md
touches: []
---

## Ensures

Nothing in the docs site refers to the old name or framing:

| Was | Now |
|---|---|
| sidebar "Gap handoff for Claude Code →" | "Known gaps →" |
| heading "Gap ledger" | "Known gaps" |
| "Take these to Claude Code." | "Each one is written up in full." |
| "The handoff doc formats every gap as a story with acceptance criteria, evidence, and proposed approach." | "What you will hit, where to look in the source, how to fix it, and how to tell when it is fixed." |
| button "Open gap handoff →" | "See the known gaps →" |
| inline anchor "gap handoff" | "known gaps" |

`README.md`'s file table entry is reworded the same way — it described the file
as "Claude Code work items … with evidence, proposed approach, and acceptance
criteria", which was accurate about the old framing and is now wrong about the
new one.

Also removed: a duplicated `GAP-003` in a single sentence on the process
supervision page, left by the rewrite of its closing clause.

## Verified

The render check greps the full rendered text of all 11 nav pages plus the gap
document for `Claude Code`, `cold-eyes`, `checkpoint`, `gap handoff`, `Gap
ledger` and the story vocabulary. All zero.
