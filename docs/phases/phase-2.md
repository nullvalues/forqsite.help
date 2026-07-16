---
era: "001"
---

# forqsite.help — Phase 2: Refresh docs against forqsite drift

<!-- Phase doc = planning surface only. Story-level detail (acceptance criteria,
     file paths, implementation guidance, test instructions, codebase recon)
     belongs in docs/stories/<RAIL>/<ID>.md — not here. -->

## Goal

A prior review agent diffed `index.html` and `gap-handoff.html` against the current
state of the sibling source-of-truth repo `/mnt/work/forqsite` and produced a detailed,
evidence-backed edit plan: consistency fixes where the docs have drifted from the code,
embellishments grounded in real repo evidence, UX fixes to the bundle's own JS/CSS, and
a prose-decluttering pass. README.md also needs its "do not hand-edit" framing revisited
to reflect that these bundles are due for a deliberate refresh pass, with an auto-sync
skill planned as a later, separate piece of work.

This phase writes that plan up as stories only. Per project policy, execution happens
through the normal pairmode build loop (builder/reviewer subagents per story via
`CLAUDE.build.md`), not as a direct hand-edit outside that loop. Nothing in this phase
is built yet.

## Stories

| ID | Title | Status |
|----|-------|--------|
| CONTENT-001 | Consistency fixes: correct index.html/gap-handoff.html drift vs forqsite source (C1-C13) | complete |
| CONTENT-002 | Embellishments: add repo-grounded detail missing from the docs (E1-E8) | complete |
| CONTENT-003 | UX fixes: hash routing, scroll reset, responsive layout, deep links, clipboard fallback (U1-U10) | complete |
| CONTENT-004 | Prose decluttering pass: reduce em-dash overuse and repetitive phrasing | draft |
| INFRA-001 | README.md: revisit generated-artifact/do-not-hand-edit framing for the refresh workflow | draft |

## Schema delivery

No persistent schema objects introduced in this phase (static HTML docs site, no
database).

| Object | Management surface | Exception |
|---|---|---|
| n/a | n/a | n/a |

---

### CP-1 Cold-eyes checklist

— developer fills in after phase completion —

Note: E4's optional Dev/E2E env-var group (`TEST_ADMIN_*` / `TEST_ORGADMIN_*`) is
explicitly marked optional in the source review plan; the CONTENT-002 story below
should decide whether to include it rather than growing the env table unbounded by
default.

Note: CONTENT-001's first review revert cited `docs/ideology.md`'s Generated-artifact
discipline constraint (bundles are not hand-edited beyond trivial fixes). An explicit
Phase 2 exception was recorded in `docs/ideology.md` on 2026-07-14 — loop-mediated,
spec-cited, reviewed edits satisfy the constraint's intent. See that doc for the full
rationale.
