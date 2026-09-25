---
id: CONTENT-008
rail: CONTENT
title: "Prune GAP-002 and GAP-011; remove the build-machine path from the public repo"
status: complete
phase: "5"
story_class: content
execution: orchestrator
primary_files:
  - index.html
  - gap-handoff.html
  - README.md
touches: []
---

## Background

Two gap items are resolved, and one of them was also a disclosure: the ledger
printed a `file:` URL, an absolute path on the original build machine, in
a public repository.

## Verified before pruning, not assumed

- **GAP-002** — forqsite's `package.json` now has **no** `file:` or `link:`
  dependency of any kind, and neither of the two packages the gap named is
  present. Checked by parsing the manifest, not by reading a changelog.
- **GAP-011** — both registries are generated, carry `GENERATED FILE — do not
  edit by hand`, and `prebuild` runs the generator.

## Deliberately NOT pruned

GAP-003 through GAP-010 were re-checked against the source during this story and
**remain open**: no systemd units ship, there is still no `Dockerfile`,
`restore.sh` still names the legacy credential key, `backup.sh` still restores
tracing with a bare `set -x`. They stay.

An unverified prune would be worse than a stale ledger. A reader trusts a short
list more than a long one, so shortening it on assumption converts a
documentation lag into a false assurance.

## What changed

- The dev-setup page's `BLOCKED` callout — which told readers a fresh clone
  *cannot* complete the flow — is now a `FIXED` note saying it can, and naming
  what was wrong.
- Two pipeline steps flip from amber to green.
- Both ledger rows removed; both gap-handoff entries removed.
- Three `#gap-002` anchors would have dangled once the entry was gone. Repointed
  to the handoff document itself.
- `README.md`'s "GAP-002…011, 10 items" corrected to "GAP-003…010, 8 items".

## Cross-references checked by evaluation

The data arrays were extracted and executed, not eyeballed: 8 ledger rows, 6
pipeline amber flags, and **zero** flags pointing at a row that no longer exists.
