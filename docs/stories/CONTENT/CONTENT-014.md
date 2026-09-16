---
id: CONTENT-014
rail: CONTENT
title: "Strip correction notices and comparative phrasing from the docs site"
status: complete
phase: "7"
story_class: content
execution: orchestrator
primary_files:
  - index.html
touches: []
---

## Background

Phases 5 and 6 corrected the facts and wrote the corrections into the page. The
site told readers what it used to say:

- "**CHANGED** — The manual step has been engineered out. Earlier versions of
  this page said the opposite, and named it GAP-011 — that gap has shipped."
- "**FIXED** — A fresh clone completes this flow. Earlier versions of this page
  reported it blocked…"

Neither is documentation. A reader arriving today does not care what the page
said last month; they care whether a fresh clone works and how a pack is
registered. Correction notices are a changelog, and git already holds one.

## What replaced them

The FIXED callout is **deleted outright**. A fresh clone working is the
unremarkable state and needs no announcement.

The CHANGED callout became a REGISTRATION note that states the mechanism and
nothing else: adding a manifest entry and rebuilding is the whole of it, both
registries are generated at prebuild, and a hand edit is discarded by the next
build. Same information, no reference to the page's own past.

## The subtler half

The same instinct produced comparative prose where plain description belonged —
each sentence measuring the present against a past the reader never saw:

| Was | Now |
|---|---|
| "Registration used to mean editing source; since the registries became generated it does not." | "None of the three touches source code." |
| "that constraint has not moved" | (dropped; the constraint is simply stated) |
| "What changed is who writes it." | "You do not write those entries." |

## Process leaks found while sweeping

Three places described *this project's* tooling to a reader who does not have it:
the layer boundary "enforced by agent config and the Claude Code deny list"; the
build gate requiring "the Claude Code cold-eyes review"; and a systemd note
telling the reader to "take them to Claude Code". All three now describe the
requirement rather than one contributor's way of meeting it — the rule is
enforced in review, the gate expects no critical or high findings, and the
systemd units point at GAP-003.
