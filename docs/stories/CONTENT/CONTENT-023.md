---
id: CONTENT-023
rail: CONTENT
title: Bring the backlog's resolution-marker convention current so a finding can be closed without being deleted
status: draft
phase: "10"
story_class: doc
auth_gated: false
schema_introduces: false
touches:
  - docs/cer/backlog.md
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

`docs/cer/backlog.md`'s header predates the resolution-marker convention the build
harness now enforces. It says only that resolved findings "remain in place with a
resolution note", which names no marker keyword and no placement rule. Under that
wording a row has two states — present, or deleted — and every other story in this
phase would have to close its finding by removing it. The harness's checkpoint guard
(`cer.is_resolution_marked`, consumed by the `cer-do-now` check) already matches an
anchored, case-insensitive marker grammar; this story writes that grammar into the
header so a marker authored under it is actually recognised.

## Requires

None. This is the phase's first story.

## Ensures

`docs/cer/backlog.md`'s header names all three marker keywords (`RESOLVED`,
`SUPERSEDED`, `OBSOLETE`), states that a marker must begin its annotation segment
(start of the finding text, after a `|` cell boundary, after sentence-ending
punctuation plus whitespace, or inside a `**`/`(`/`[` opener) and is case-insensitive,
states that a keyword appearing mid-clause is not a marker, and names the checkpoint
guard that reads it — and the `## Tests` probe below returns True for every accepted
example the header gives and False for every rejected one. Every table row below the
header is byte-identical to its pre-story text, including ID, quadrant and ordering;
forbidden proxy: a header that merely mentions the word "RESOLVED" in prose without
stating placement, so a marker written under it is still missed by the guard.

## Instructions

1. Rewrite only the paragraph under the `# ... CER Backlog` title and
   `*Last updated:*` line in `docs/cer/backlog.md` (currently ending "remain in place
   with a resolution note"). Keep "Findings are not deleted" — that claim is the point
   of the phase; extend it with the marker convention.
2. State, in substance: the annotation form
   `**RESOLVED <phase or checkpoint> — <what landed>**`, and its `**SUPERSEDED by
   CER-NNN**` / `**OBSOLETE — <why it no longer applies>**` siblings; the
   segment-start placement rule and case-insensitivity; that a mid-clause keyword
   (`UNRESOLVED`, `should be resolved`) is never a marker, so an open finding cannot
   be waved past a checkpoint by accident; and that the `cer-do-now` checkpoint guard
   reads exactly this form via `cer.is_resolution_marked`.
3. Include at least one accepted example and one rejected example inline, since the
   `## Tests` probe is run against the examples the header itself gives.
4. Apply this phase's principle to what you write: name the guard and the convention,
   not our copy of the harness — no absolute cache path, version-pinned directory, or
   machine-local path in the header. (Adjustment noted per the ideology check: the
   header describes the convention's shape, which is also what makes it survive a
   harness upgrade.)
5. Change nothing else — no row text, no ID, no quadrant, no ordering, no
   `*Last updated:*` semantics beyond stamping today's date.

## Tests

```bash
PATH=$HOME/.local/bin:$PATH uv run --no-project --with click python - <<'PY'
import sys
sys.path.insert(0, f"{__import__('os').path.expanduser('~')}/flex-marketplace-cache/flex-0.4.7/skills/pairmode/scripts")
import cer
accepted = ["| CER-003 | text. **RESOLVED cp-10 — generalised** | s | d | 9 |",
            "**SUPERSEDED by CER-001**", "**OBSOLETE — disproved by reproduction**"]
rejected = ["UNRESOLVED naming gap", "this should be resolved before cp-10"]
assert all(cer.is_resolution_marked(s) for s in accepted), "accepted form not matched"
assert not any(cer.is_resolution_marked(s) for s in rejected), "rejected form matched"
print("OK")
PY
git diff --stat docs/cer/backlog.md
git diff docs/cer/backlog.md | grep -E '^[-+]\| CER-' || echo "no row changed"
```

Acceptance: the probe prints `OK` with every accepted/rejected string replaced by the
examples the reworked header actually gives; the diff touches only
`docs/cer/backlog.md`; and the row grep prints `no row changed`.

## Out of scope

- Marking any finding resolved. This story makes closure expressible; CONTENT-024
  through CONTENT-027 use it. The table must contain the same open rows after this
  story as before.
- Adopting the flex backlog template wholesale (the `gate:` token, the Do Never
  `Resolution` column, regenerating the file from the template). Only the header's
  resolution-marker wording is in scope.
- Defining the marker keywords anywhere in this repo. Spec-preflight warns that
  `RESOLVED`/`SUPERSEDED`/`OBSOLETE`/`UNRESOLVED` have no definition in this source
  tree; that is correct and intentional — they are the harness's keyword set, and
  this repo documents the convention rather than owning it.
- Any tooling that checks the backlog for staleness — explicitly excluded by the
  phase's "What is NOT in scope".
