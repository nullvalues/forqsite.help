---
phase_class: production
---

# forqsite.help — Proposed Phase: Migrate to pairmode 0.3.0

**Status:** proposed — not yet sequenced. Sequence this into a real phase
number following this project's own (bare-integer) convention during a
normal "spec next phase" cycle run from *this* project's own orchestrator
session — not built directly from flex-harness.

**Origin:** drafted 2026-07-22 by the flex-harness fold-prep orchestrator
(Phase 97) as part of a fleet-wide pairmode 0.2.0 → 0.3.0 migration effort.
Per repo-owner direction, this is left as a proposal rather than built
directly, to respect this project's own conventions and avoid disrupting
in-flight work here.

## Goal

Migrate this project from pairmode 0.2.0 to 0.3.0 (the Era 3 thin dispatch
loop): run the 6-step per-project mechanic documented in flex-harness's
`docs/harness-cutover-runbook.md` (§Per-project mechanic), using the
canonical pairmode tooling at `/mnt/work/flex/skills/pairmode/scripts/`:

1. Confirm the working tree is at HEAD with no build attempt in flight.
2. `pairmode_sync.py sync-all --project-dir . --dry-run` — review the diff.
3. `pairmode_sync.py sync-all --project-dir . --apply --yes`.
4. `pairmode_migrate.py to-030 --project-dir . --apply`.
5. `fleet_discovery.py --candidate-dir . --json` — require Signal-1
   (`binding` includes `scripts`).
6. Run one complete story cycle to prove the migrated loop works; confirm
   `pairmode_version: 0.3.0` in `.companion/state.json`; commit and push.

If step 5 or 6 fails, roll back: `git checkout HEAD -- CLAUDE.build.md
.companion/state.json`, and return this story for human review rather than
forcing the migration.

## Context

A 2026-07-22 survey (read-only, no changes made) found this project clean
— Phase 2 complete, nothing else scheduled ("Next to build: none"). Low
risk, straightforward candidate. Still on pairmode 0.2.0 despite the
unrelated INFRA-209 fleet hook-rollout commit already having landed here
(2026-07-21).

## Proposed stories

| Working title | Notes |
|---|---|
| Migrate forqsite.help to pairmode 0.3.0 | Assign this project's own next phase number (3) when sequenced |

## Out of scope

- Actually running the migration from outside this project's own
  orchestrator session.
- Any change to this project's phase-numbering or story-rail conventions.
