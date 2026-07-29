---
era: "001"
phase_class: production
---

# forqsite.help — Phase 3: Drift re-sweep vs forqsite source (pairmode 0.3.0 proving cycle)

← [Phase 2: Refresh docs against forqsite drift](phase-2.md)

<!-- Phase doc = planning surface only. Story-level detail (acceptance criteria,
     file paths, implementation guidance, test instructions, codebase recon)
     belongs in docs/stories/<RAIL>/<ID>.md — not here. -->
## Goal

<!-- State this phase's single purpose in one or two sentences (docs/architecture.md
     § Phase-authoring convention, INFRA-243). If the work naturally splits into more
     than one purpose, that's a signal to open a sibling phase, not to widen this one. -->
Re-check the docs site against the current forqsite source repo (changed since the 2026-07-16 phase-2 sync baseline, forqsite@90b64b99) and fix any content drift found. Serves as the RELEASE-066 proving cycle through the migrated 0.3.0 loop.

## Stories

| ID | Title | Status |
|----|-------|--------|
| CONTENT-005 | Drift re-sweep: re-check index.html/gap-handoff.html against current forqsite source and fix drift | complete |

## Schema delivery

For each new persistent schema object (table, collection, migration) introduced in
this phase, record the management surface before the phase is checkpointed.

| Object | Management surface | Exception |
|---|---|---|
| | | |

---

### CP-3 Cold-eyes checklist

- [ ] written-never-read — does anything this phase persists have no reader?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] half-implementation — is any branch unreachable, or any producer without its consumer?

— developer fills in after phase completion —
