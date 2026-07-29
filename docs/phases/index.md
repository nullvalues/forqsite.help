# forqsite.help — Phase Index

This document is the index of all build phases for the project.
Each phase has a dedicated file in `docs/phases/`.

**Naming convention** (if using a string predicate):
- Predicate: project-specific (e.g. `PM`). 3-digit zero-padded number.
- Suffix system: `-ante[N]` (preflight, blocks parent), `-main` (the phase itself), `-post[N]` (remediation, blocks subsequent phases), `-sec` (security prerequisite, same semantics as `-ante`).
- Alphabetical sort matches build order: `'a' < 'm' < 'p'`.
- Checkpoint tags follow the same naming: `cp-<PRED>NNN-main`, etc.
- Omit suffix for projects using sequential integer IDs.

**Next to build:** none scheduled — say "spec next phase [intent]" to plan one

| Phase | Title | Status | Deferred from | Link |
|-------|-------|--------|---------------|------|
| 1 | Bootstrap pairmode methodology | complete | — | [phase-1.md](phase-1.md) |
| 2 | Refresh docs against forqsite drift | complete | — | [phase-2.md](phase-2.md) |
| 3 | Drift re-sweep vs forqsite source (pairmode 0.3.0 proving cycle) | planned | [phase-3.md](phase-3.md) |


## Backlog promotions

_(List items promoted from the Do-Later / Do-Much-Later backlog into active phases here, with a one-line reason and the target phase.)_

---

## Proposed phases (not yet sequenced)

Phases conceived before they enter the build queue use the filename convention
`phase-proposed-<kebab-name>-YYYYMMDD-NNN.md`. No sequential number until
sequenced. When sequenced, stories are absorbed into the next available phase
and this file is deleted (git history records the transit).

| Proposed file | Title | Era |
|---------------|-------|-----|
| [phase-proposed-pairmode-030-migration-20260722-001.md](phase-proposed-pairmode-030-migration-20260722-001.md) | Migrate to pairmode 0.3.0 | — |
