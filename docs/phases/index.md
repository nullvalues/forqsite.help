# forqsite.help — Phase Index

This document is the index of all build phases for the project.
Each phase has a dedicated file in `docs/phases/`.

**Naming convention** (if using a string predicate):
- Predicate: project-specific (e.g. `PM`). 3-digit zero-padded number.
- Suffix system: `-ante[N]` (preflight, blocks parent), `-main` (the phase itself), `-post[N]` (remediation, blocks subsequent phases), `-sec` (security prerequisite, same semantics as `-ante`).
- Alphabetical sort matches build order: `'a' < 'm' < 'p'`.
- Checkpoint tags follow the same naming: `cp-<PRED>NNN-main`, etc.
- Omit suffix for projects using sequential integer IDs.

**Next to build:** [Phase 9: Close CP-8: the defect the checklist missed, and the wiring that predates the convention](phase-9.md)

| Phase | Title | Status | Deferred from | Link |
|-------|-------|--------|---------------|------|
| 1 | Bootstrap pairmode methodology | complete | — | [phase-1.md](phase-1.md) |
| 2 | Refresh docs against forqsite drift | complete | — | [phase-2.md](phase-2.md) |
| 3 | Drift re-sweep vs forqsite source (pairmode 0.3.0 proving cycle) | complete | — | [phase-3.md](phase-3.md) |
| 4 | Containerize for edge deployment | complete | — | [phase-4.md](phase-4.md) |
| 5 | SDK 5.0.0 and the generated-registry ingestion path | complete | — | [phase-5.md](phase-5.md) |
| 6 | Full structural back-check, and a verification stamp | complete | — | [phase-6.md](phase-6.md) |
| 7 | Write for the reader, not about the work | complete | — | [phase-7.md](phase-7.md) |
| 8 | The promotion path, and what a pack may carry | complete | — | [phase-8.md](phase-8.md) |
| 9 | Close CP-8: the defect the checklist missed, and the wiring that predates the convention | planned | — | [phase-9.md](phase-9.md) |


## Backlog promotions

_(List items promoted from the Do Later / Do Much Later backlog — [docs/cer/backlog.md](../cer/backlog.md) —
into active phases here, with a one-line reason and the target phase.)_

---

## Proposed phases (not yet sequenced)

Phases conceived before they enter the build queue use the filename convention
`phase-proposed-<kebab-name>-YYYYMMDD-NNN.md`. No sequential number until
sequenced. When sequenced, stories are absorbed into the next available phase
and this file is deleted (git history records the transit).

| Proposed file | Title | Era |
|---------------|-------|-----|
| _(none)_ | — | — |
