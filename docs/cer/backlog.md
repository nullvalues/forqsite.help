# forqsite.help — Cold-Eyes Review (CER) Backlog

*Last updated: 2026-09-21*

This file is the structured triage log for findings from external cold-eyes reviews.
Each finding is assigned to one quadrant. Findings are not deleted — resolved findings
remain in place with a resolution marker.

A **resolution marker** closes a finding by placing one of three keywords at the start of an annotation segment. The keywords are `RESOLVED`, `SUPERSEDED`, and `OBSOLETE` (case-insensitive: `resolved`, `Resolved`, `RESOLVED` all match). An annotation segment begins at the start of text, after a `|` table cell boundary, after sentence-ending punctuation followed by whitespace, or at an emphasis or bracket opener (`**`, `(`, `[`). Accepted forms include `**RESOLVED Phase 10 — INFRA-1**` (bolded), `| Resolved cp-10 — INFRA-1 |` (after a cell boundary), `**SUPERSEDED by CER-001**`, and `**OBSOLETE — disproved**`. A keyword appearing mid-clause — preceded by a space and a word — is not a marker and leaves the finding open; `this should be resolved before cp-10` and `UNRESOLVED naming gap` do not close. The `cer-do-now` checkpoint guard (a harness rule, not defined in this repo) scans this marker form to enforce that all Do Now findings are either marked closed or re-triaged before each checkpoint.

---

## Do Now

Urgent and important. Blocks correctness, security, or the next phase.

| ID | Finding | Source | Date | Phase |
|----|---------|--------|------|-------|


| — | *(none)* | — | — | — |


---

## Do Later

Important, not urgent. Quality improvements, architectural refinements.

| ID | Finding | Source | Date | Phase |
|----|---------|--------|------|-------|



| CER-001 | CONTENT-004 missed one named acceptance-criterion line item: reword one of GAP-006/GAP-011's near-identical 'exactly the case ... exists to catch/covers' construction in gap-handoff.html. Both phrases still present verbatim. Suggested fix for GAP-011: '...requires the same restart the admin banner already flags.' | intent-reviewer (Phase 2 checkpoint) | 2026-07-16 | 2 |
| CER-002 | GAP-012 (and the Known gaps convention generally) cites forqsite source paths and a commit hash on a publicly served page. Matches the page's existing citation convention, so not a Phase 8 regression — needs an operator ruling on whether product-repo internal detail belongs in public docs. | security-auditor (Phase 8 checkpoint) | 2026-09-18 | 8 |
| CER-003 | docs/architecture.md's Deployment section names internal host `kw-pub61` and paths `/srv/forqsite-help`, `/srv/edge` in a public repo. Pre-existing since the Phase 4 containerization commit, outside Phase 9's diff. Same public-hygiene class as CER-002. | security-auditor (Phase 9 checkpoint) | 2026-09-21 | 9 |
| CER-004 | Operator ruling wanted: whether docs/pairmode-wiring-audit.md's references to local flex-cache paths (`~/flex-marketplace-cache/flex-0.4.7`) and flex-internal story IDs are acceptable in a public repo, or should be generalized. Judged LOW-severity disclosure, not blocking. | security-auditor (Phase 9 checkpoint) | 2026-09-21 | 9 |
| CER-005 | index.html's `sc-for` ledger list does not hydrate under headless Chromium at a `file://` origin, so ledger rows can be verified in source but not in a render. Pre-existing, reproduced on the pre-story bundle. Limits reviewer verification coverage for any story touching that list. | reviewer (CONTENT-019, accepted deviation) | 2026-09-18 | 8 |
| CER-006 | Flex effort recording is unreliable in this harness: `read_completed_spawn` parses a worker's verdict from its final message text, but some subagents deliver the WORKER-004 block via the hand-back channel and sign off in prose, leaving `outcome` NULL. Six rows across phases 8-9 needed hand reconciliation (each carries a `notes` field saying so). Report upstream to flex rather than patching the cache. | orchestrator (phases 8-9) | 2026-09-21 | 9 |
| CER-007 | Phases 3-7 were marked complete in docs/phases/index.md without ever passing a green build gate (the prose `test_command` failed red at exit 127 throughout). Open operator question whether to back-tag them. | CONTENT-020 audit | 2026-09-21 | 9 |



---

## Do Much Later

Not urgent, marginal value. Style, cosmetics, speculative improvements.

| ID | Finding | Source | Date | Phase |
|----|---------|--------|------|-------|


| — | *(none)* | — | — | — |


---

## Do Never

Rejected findings. Record the rejection reason so it is not re-raised.

| ID | Finding | Source | Date | Phase | Resolution |
|----|---------|--------|------|-------|------------|


| — | *(none)* | — | — | — | — |

