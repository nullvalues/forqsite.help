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
| CER-003 | docs/architecture.md's Deployment section names the internal host and its deployment paths in a public repo. Pre-existing since the Phase 4 containerization commit, outside Phase 9's diff. Same public-hygiene class as CER-002. **RESOLVED cp-10 — generalised in docs/architecture.md, docs/phases/phase-4.md and docs/stories/INFRA/INFRA-002.md; the identifiers were redacted from this row too, under the same principle** | security-auditor (Phase 9 checkpoint) | 2026-09-21 | 9 |
| CER-004 | Operator ruling wanted: whether docs/pairmode-wiring-audit.md's references to a version-pinned flex cache path under a home directory and to flex-internal story IDs are acceptable in a public repo, or should be generalized. Judged LOW-severity disclosure, not blocking. **RESOLVED cp-10 — the audit doc was removed from this repository in CONTENT-025 (its subject is the build harness, not forqsite); the cache path was redacted from this row too, under the same principle applied to CER-003** | security-auditor (Phase 9 checkpoint) | 2026-09-21 | 9 |
| CER-005 | index.html's `sc-for` ledger list does not hydrate under headless Chromium at a `file://` origin, so ledger rows can be verified in source but not in a render. Pre-existing, reproduced on the pre-story bundle. Limits reviewer verification coverage for any story touching that list. | reviewer (CONTENT-019, accepted deviation) | 2026-09-18 | 8 |
| CER-006 | Flex effort recording is unreliable in this harness: `read_completed_spawn` parses a worker's verdict from its final message text, but some subagents deliver the WORKER-004 block via the hand-back channel and sign off in prose, leaving `outcome` NULL. Original finding (phases 8-9): six rows needed hand reconciliation, each carrying a `notes` field saying so. Report upstream to flex rather than patching the cache. **Grew in Phase 10.** Measured against the effort database as of 2026-09-21: of 36 attempt rows, 13 carry a hand-reconciliation note (9 from the phase 8-9 work — rows 15, 16, 17, 18, 21, 24, 25, 31, 32 — and 4 added by Phase 10's own stories: CONTENT-023 rows 33/34, CONTENT-024 rows 35/36), and 6 still carry a NULL `outcome` (ids 1, 3, 5, 6, 9, 11, all builder attempts from July 2026 — a different and older population, predating the reconciliation practice). The original six-row count could not be reproduced from the database and is left as the historical claim it was rather than silently restated. CONTENT-025 wrote the symptom and the transcribed rows up for the project that owns the defect, operator-local and untracked. Referring it upstream does not fix it here, so this finding stays open. | orchestrator (phases 8-9, updated Phase 10) | 2026-09-21 | 9 |
| CER-007 | Phases 3-7 were marked complete in docs/phases/index.md without ever passing a green build gate (the prose `test_command` failed red at exit 127 throughout). Open operator question whether to back-tag them. | CONTENT-020 audit | 2026-09-21 | 9 |
| CER-009 | A frozen-snapshot probe asserted against the effort database cannot pass once its own story is built: the build's and the review's own attempt rows land inside the same calendar day the assertion is stamped for, so a date-only boundary is perturbed by the very run it is meant to verify. Observed on CONTENT-025, whose probe measured 38 rows against an asserted 36. Suggested convention: bound such probes on an attempt-id captured before the build starts, not on a same-day date filter. | reviewer (CONTENT-025) | 2026-09-21 | 10 |
| CER-010 | The date-and-commit stamp convention is scoped to claims about forqsite's behaviour, so a point-in-time claim about harness telemetry carries a date only. CER-006 demonstrates the gap: a date-granularity stamp cannot flag a figure that moves several times within the stamped day. Proposal to extend the convention to harness-telemetry claims of this kind; recorded as a proposal, not a defect. | reviewer (CONTENT-025) | 2026-09-21 | 10 |



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


| CER-008 | The internal host name and deployment paths generalised out of the working tree in Phase 10 remain in this repository's git history, in every commit from the Phase 4 containerization onward; a `git log -S` search still surfaces them. No edit to the working tree reaches history. | orchestrator (Phase 10, CONTENT-024) | 2026-09-21 | 10 | Rejected: the only remedy is a history rewrite and force-push, which invalidates the `cp-N` checkpoint tags this project uses as its verification record. If these identifiers ever become genuinely sensitive, the correct response is to rotate them, not to rewrite history. Recorded so the question is not re-raised at each security gate. |

