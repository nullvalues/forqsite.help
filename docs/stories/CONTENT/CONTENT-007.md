---
id: CONTENT-007
rail: CONTENT
title: "Document the SDK delivery contract and what a pack author builds against at 5.0.0"
status: complete
phase: "5"
story_class: content
execution: orchestrator
primary_files:
  - index.html
touches: []
---

## Background

The site described how a pack is installed and said nothing about where one comes
from or what its author was working against. With a partner pack about to be
ingested, the operator judging it needs both.

## Ensures

Two new sections on the provider lifecycle page: **Where a pack comes from** (the
delivery model) and **What a pack is built against** (the 5.0.0 contract).

## What is stated, and why each earns its place

- **Artifacts, not repository access.** An author receives three tarballs, a
  README and a sums file, and publishes nowhere. This is the fact that makes the
  rest coherent: there is no registry to check a pack against, which is why
  manual review carries the weight it does.
- **The verification limit, stated plainly.** The sums file is unsigned and
  travels with the tarballs, so the check catches corruption, omission and
  version confusion — not a channel adversary who rewrites the sums too. Left
  unsaid, an operator could reasonably read "verify the hash" as stronger than it
  is. The separate inbound pack-signing path is explicitly distinguished, because
  the two are easy to conflate and only one covers this bundle.
- **Peer, not dependency — with the consequence, not just the rule.** A pack that
  hard-depends on the SDK or React ships a second copy into the process. The page
  gives the observable symptom: duplicate validation libraries mean the
  platform's own error-type checks stop matching, and editors lose field-level
  save errors with nothing in the logs. A rule without its failure mode gets
  ignored.
- **Identity is issued, not chosen**, and the predicate alphabet omits `i`, `l`
  and `o`.
- **Render gets a narrow context.** Since 5.0.0 a render path cannot reach the
  database. This is the single most useful sentence on the page for someone
  assessing what a pack can do.
- **Media is resolved before render**, and holds the raw key on failure.
- **Source is a legal shipping format**, because the transpile list is derived
  from the manifest — and the validator refuses to run against a pack with no
  source, deliberately, since compiled output cannot be reviewed by a human.

## The point the section closes on

A clean validator run is **not** a review. The tool prints on every run which
checklist items it did not evaluate, and cross-tenant access and presigned-URL
leakage are on that list. An operator who reads "validator: clean" as "reviewed"
has skipped the only control that covers those.
