---
id: CONTENT-020
rail: CONTENT
title: Reconcile this repo's pairmode wiring with current flex convention, and record what was already fixed inline
status: draft
phase: "9"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - docs/pairmode-wiring-audit.md
touches:
  - .claude/agents/gate-worker.md
  - docs/phases/index.md
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->

## Context

Four pieces of this repo's pairmode wiring predate current flex (0.4.7) convention, and
each surfaced only when it broke something (phase-9 § "The pattern behind CONTENT-020").
Two were fixed inline during the Phase 8 build under an operator ruling and have no
written record; two remain open. This story is an **audit with a recording obligation**,
not a code change: it compares this repo's pairmode configuration against current flex
convention and leaves every divergence either fixed or recorded with a stated reason, in
a durable in-repo record — `docs/pairmode-wiring-audit.md` — so the next person meets the
finding in a document rather than in a broken gate. It runs first in the phase so
CONTENT-021 and CONTENT-022 do not re-litigate what is already settled.

## Requires

- Phase 8's inline fixes are already on `main`: `.gitignore` at commit `87a8ef7`, and
  `test_command` set to `true` in both `.companion/pairmode_context.json` and
  `CLAUDE.build.md`'s Build standards line. This story verifies and records them; it
  does not re-apply them.

## Ensures

`docs/pairmode-wiring-audit.md` exists and carries one entry per divergence for all four
known items plus every further divergence the sweep finds, each entry naming the
divergence, its current disposition (`already fixed inline` / `fixed by this story` /
`kept, with reason` / `reported to operator`) and the reason; `.claude/agents/gate-worker.md`
is deleted, so `dark_feature_scan.py --project-dir .` reports 0 findings (it reports
exactly 1 today, the GATE-WORKER narrative finding); `docs/phases/index.md` no longer
references a Do-Later / Do-Much-Later backlog that has no phase doc on disk — either the
backlog docs exist or the reference is gone, with the choice and its reason recorded in
the audit doc; and nothing under `~/flex-marketplace-cache/` is modified.

**Forbidden proxies.**
- Patching a flex-side divergence instead of reporting it. A finding in
  `~/flex-marketplace-cache/flex-0.4.7/` is another project's source: the correct
  signal is an entry in the audit doc with disposition `reported to operator`; the
  forbidden proxy is any edit, however small, under that tree. `git -C
  ~/flex-marketplace-cache/flex-0.4.7 status --porcelain` must be byte-identical
  before and after this story.
- Re-applying an already-fixed item instead of recording it. The correct signal is a
  verification (the ignore rules and `test_command=true` are present, and the audit
  doc says so); the forbidden proxy is a diff that touches `.gitignore` or
  `pairmode_context.json` again.
- Recording a divergence as "fixed" with no reason, or silently dropping one the sweep
  found. Every item ends with a disposition *and* a reason; an item with neither is the
  omission this story exists to prevent.

## Instructions

1. **Verify the two already-fixed items** (do not change them). Confirm `.gitignore`
   carries `.companion/`, `.pairmode-worktrees/`, `.pairmode-suggestions.md`,
   `.pairmode-review.lck`, `.pairmode-review-request`; confirm `test_command` is `true`
   in `.companion/pairmode_context.json` and in `CLAUDE.build.md`'s Build standards line.
   Record the consequence of the second: `git tag -l 'cp-*'` returns nothing — **no
   phase 1-7 was ever tagged**, because `next_action.py`'s `_run_build_gate_subprocess`
   shelled out the prose value and got `command not found`, exit 127, gate red, for the
   project's whole history. Put that sentence in the audit doc; it is the single most
   load-bearing fact here.
2. **Remove `.claude/agents/gate-worker.md`.** Flex retired the `spawn-gate-worker`
   dispatch in INFRA-422 and deleted the role's skill files in INFRA-448; nothing in
   this repo dispatches it (the only other mentions are CLAUDE.build.md's historical
   note and the phase doc). Keeping it is a dark feature. Record the removal and the
   reason so it is not resurrected.
3. **Resolve the backlog reference** in `docs/phases/index.md` § Backlog promotions —
   either create the Do-Later / Do-Much-Later phase docs (structure only; do not
   populate them with GAP-012, which phase-9 § "What is NOT in scope" holds for an
   operator ruling) or reword/remove the reference. Note in the audit doc that this
   line is verbatim flex template boilerplate
   (`skills/pairmode/templates/docs/phases/index.md.j2`), not a forqsite-authored
   claim — a flex-side observation, reported, never patched.
4. **Sweep for further divergence.** Compare this repo's `.claude/agents/`, `.companion/`
   layout, `docs/` structure and `CLAUDE.build.md` against what flex 0.4.7 expects —
   read `bootstrap.py`'s `*_FILES` destination lists, `skills/pairmode/templates/`, and
   `audit.py`'s agent-shell list. Two leads already found and worth confirming or
   dismissing: `docs/phases/index.md` links `phase-proposed-pairmode-030-migration-20260722-001.md`,
   which is not on disk; and CLAUDE.build.md's documented `dark_feature_scan.py`
   invocation fails with `ModuleNotFoundError: No module named 'click'` outside flex's
   own venv (`uv run --with click python …` works). Record each with a disposition.
   Editing `CLAUDE.build.md` to fix its own invocation line is **not** required — if you
   leave it, say so and why.
5. **Write `docs/pairmode-wiring-audit.md`** as the durable record: a short preamble
   naming what the audit compared and when, then one section per divergence with
   divergence / disposition / reason. Link it from nothing else; it is a standalone
   record, and `docs/architecture.md` is CONTENT-022's file, not this story's.
6. Proportionality note: this spec runs past this project's usual doc-story length
   because the audit has four named items plus an open-ended sweep, and the
   already-fixed/do-not-redo distinction is exactly the kind of thing a terse spec gets
   wrong by re-applying.

## Tests

```bash
cd /mnt/work/forqsite.help
test -f docs/pairmode-wiring-audit.md && echo AUDIT-DOC-OK
test ! -e .claude/agents/gate-worker.md && echo GATE-WORKER-REMOVED
git tag -l 'cp-*'   # expected: empty — the fact the audit doc must record
PATH=$HOME/.local/bin:$PATH uv run --with click python \
  ~/flex-marketplace-cache/flex-0.4.7/skills/pairmode/scripts/dark_feature_scan.py --project-dir .
git -C ~/flex-marketplace-cache/flex-0.4.7 status --porcelain   # expected: unchanged from before this story
```

Acceptance: both `echo` markers print, the dark-feature scan reports `0 finding(s)`
(down from the 1 GATE-WORKER finding it reports today), and the flex-cache tree is
untouched. This project has no test suite (`test_command=true`, static HTML) — these
are the story's verification commands.

## Out of scope

- **Fixing flex itself.** Divergences under `~/flex-marketplace-cache/` are reported in
  the audit doc, never patched (phase-9 § "What is NOT in scope").
- **Re-applying the two Phase 8 inline fixes.** They are verified and recorded, not redone.
- **`docs/architecture.md` and the era phase ledger** — CONTENT-022's story.
- **The `#promote` / `rolling-restart.sh` defect** — CONTENT-021's story.
- **GAP-012's public-hygiene question**, and populating any backlog doc this story
  creates with backlog content — an operator ruling, not this phase's work.
- **Re-running or re-recording the CP-8 gates.** Closing CP-8 is the phase's job after
  all three stories merge, not this story's.
