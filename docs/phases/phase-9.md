---
era: "001"
phase_class: docs-only
---

# forqsite.help — Phase 9: Close CP-8: the defect the checklist missed, and the wiring that predates the convention

**Parent phase:** Phase 8 — The promotion path, and what a pack may carry

← [Phase 8: The promotion path, and what a pack may carry](phase-8.md)

<!-- Phase doc = planning surface only. Story-level detail (acceptance criteria,
     file paths, implementation guidance, test instructions, codebase recon)
     belongs in docs/stories/<RAIL>/<ID>.md — not here. -->
## Goal

<!-- State this phase's single purpose in one or two sentences (docs/architecture.md
     § Phase-authoring convention, INFRA-243). If the work naturally splits into more
     than one purpose, that's a signal to open a sibling phase, not to widen this one. -->
Fix the one factual defect Phase 8 shipped, bring the cold-start docs current with how this project is actually built, and reconcile this repo's pairmode wiring with current flex convention so CP-8 can be tagged.

## Why this phase exists

Phase 8's four stories all passed their own reviews and merged. CP-8 then refused to
tag: `checkpoint-docs` returned FAIL, and `checkpoint-intent` surfaced a factual
defect that no story reviewer could have caught, because each reviewer correctly
checked its own story's spec and the hazard was only visible across two of them.

This phase closes CP-8. It is remediation, not new capability.

## What the gates found

| Source | Finding | Blocking |
|---|---|---|
| checkpoint-intent | `#promote` names `rolling-restart.sh` as the systemd reader's restart command | no |
| checkpoint-docs | `architecture.md` Editing procedure superseded; `scripts/` absent from module tree; no era or Phase-7 reference | **yes** |
| checkpoint-docs | `docs/eras/001-initial.md` phase ledger omits phases 4-7 | **yes** |
| dark-feature-scan | `.claude/agents/gate-worker.md` persists for a role flex removed in INFRA-422 | no |

## The pattern behind CONTENT-020

Four separate pieces of this repo's pairmode wiring were found to predate current
flex convention during the Phase 8 build, each surfacing only when it broke something:

- `.companion/` telemetry was tracked in git, so every loop run dirtied the main
  checkout and `merge-story-worktree` refused every story merge.
- `test_command` held a prose description (`none - static HTML, ...`) in a field the
  build-gate guard executes as a shell command, so the gate had been failing red.
  **No `cp-*` tag exists for any of phases 1-7** — this is why.
- `.pairmode-worktrees/` and the shadow-reviewer marker files were not ignored.
- `.claude/agents/gate-worker.md` remains for a dispatch capability flex removed.

The first two were fixed inline during the Phase 8 build under an explicit operator
ruling. CONTENT-020 exists so the remaining drift is found by audit rather than by
the next thing that breaks.

## Stories

| ID | Title | Status |
|----|-------|--------|
| CONTENT-020 | Reconcile this repo's pairmode wiring with current flex convention, and record what was already fixed inline | draft |
| CONTENT-021 | Correct the rolling-restart.sh claim on the Promoting a change page | draft |
| CONTENT-022 | Bring architecture.md and the era ledger current with how this project is actually built | draft |
| CONTENT-020 | Reconcile this repo's pairmode wiring with current flex convention, and record what was already fixed inline | draft |
| CONTENT-021 | Correct the rolling-restart.sh claim on the Promoting a change page | draft |
| CONTENT-022 | Bring architecture.md and the era ledger current with how this project is actually built | draft |

### CONTENT-021 - The rolling-restart.sh claim

**Done when** the `#promote` page no longer implies `rolling-restart.sh` is the tool
for the site's published non-docker, systemd, two-instance path.

The defect: the sentence `systemctl restart forqsite forqsite-scheduler (or
rolling-restart.sh, if you run two instances behind Caddy)` contradicts two things the
site already says - the Process supervision page's "Zero-downtime restarts, non-docker"
section (that topology is the operator's own manual A-then-B swap), and GAP-004
(`rolling-restart.sh` points at the wrong compose path). The site tells a reader to run
a script it elsewhere documents as broken for their arrangement.

Point instead at the manual two-instance swap already described under "Zero-downtime
restarts, non-docker". Verify the claim against the forqsite repository and refresh the
section stamp per the Phase 6 convention.

**Not done if** the fix introduces container vocabulary into the non-docker path, or
edits the global sidebar stamp.

**Also required:** add a forbidden-proxy line to this phase's own spec for any future
story touching promotion prose, barring `rolling-restart.sh` as the systemd path's
command. CONTENT-018's spec carried that guardrail and CONTENT-016's did not, which is
precisely how the defect shipped.

### CONTENT-022 - The cold-start documents

**Done when** `docs/architecture.md` describes how this project is actually built today:

- The **Editing procedure** section names `scripts/bundle-template.py extract|inject|verify`
  as the editing path. All four Phase 8 stories used it exclusively; the documented
  manual `JSON.stringify` splice is superseded. Keep the round-trip and
  headless-render verification requirements - those are still correct.
- `scripts/` appears in the **Module structure** tree.
- The doc references the current era (`001`) and the most recently complete phase.
- `docs/eras/001-initial.md`'s phase ledger lists phases 1-9 with statuses consistent
  with `docs/phases/index.md`.

**Not done if** the architecture doc is edited to describe a procedure nobody follows,
or the ledger is made consistent by changing `docs/phases/index.md` to match the stale
ledger rather than the reverse.

### CONTENT-020 - The wiring audit

**Done when** this repo's pairmode configuration has been compared against current flex
convention and every divergence is either fixed or recorded with a reason:

- `.gitignore` against flex's own (`.companion/`, `.pairmode-worktrees/`, the
  shadow-reviewer markers) - **already fixed inline** during the Phase 8 build,
  commit `87a8ef7`; this story records it, does not redo it.
- `test_command` in `.companion/pairmode_context.json` and the `CLAUDE.build.md`
  Build standards line - **already fixed inline**, commit after `945d379`; record it,
  including that this is why no phase has ever been tagged.
- `.claude/agents/gate-worker.md` - flex removed `spawn-gate-worker` dispatch in
  INFRA-422. Remove the agent definition, or keep it with a stated reason.
- The Do-Later / Do-Much-Later backlog docs that `docs/phases/index.md` references
  but which do not exist. Create them, or remove the dangling reference.
- Any other divergence the audit finds.

**Not done if** the audit edits anything under `~/flex-marketplace-cache/` - that is
another project's source, and a finding there is reported, not patched.

## Story ordering

CONTENT-020 first: it establishes what is already fixed and what remains, so the other
two do not re-litigate it. CONTENT-021 and CONTENT-022 are independent of each other.

## What is NOT in scope

- **Re-opening any Phase 8 content decision** other than the one factual defect named
  in CONTENT-021.
- **Fixing flex itself.** Divergences found in `~/flex-marketplace-cache/` are reported
  to the operator, never patched here.
- **The GAP-012 public-hygiene question.** The new gap entry cites forqsite source
  paths and a commit hash on a publicly served page. That matches the page's existing
  citation convention and is not a Phase 8 regression, so it is a backlog item and an
  operator ruling, not this phase's work.

## Closing CP-8

After this phase's stories merge, re-run `checkpoint-docs` against **phase 8**
(`--phase-key 8`) and re-record its verdict. CP-8 tags only once that gate is PASS.
Per `CLAUDE.build.md`, a refusal is fixed and retried - never worked around by
deleting a recorded verdict or hand-editing `state.json`.

## Schema delivery

For each new persistent schema object (table, collection, migration) introduced in
this phase, record the management surface before the phase is checkpointed.

| Object | Management surface | Exception |
|---|---|---|
| | | |

---

### CP-9 Cold-eyes checklist

- [ ] written-never-read — does anything this phase persists have no reader?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] half-implementation — is any branch unreachable, or any producer without its consumer?

— developer fills in after phase completion —
