# forqsite.help Pairmode — Checkpoints

Each checkpoint is tagged after all stories in the phase pass the full checkpoint sequence
(build gate → security audit → intent review).

---

## cp1-bootstrap-complete

**Phase:** 1 — Bootstrap pairmode methodology
**Tag command:** `git tag cp1-bootstrap-complete && git push origin cp1-bootstrap-complete`
**Acceptance:** Pairmode scaffolding is in place alongside the existing, working
`index.html` / `gap-handoff.html` docs bundle without disrupting it. No code stories
were required for this phase. Build gate: static HTML, no test failures possible with
zero code changes. Security audit: no CRITICAL/HIGH findings. Intent review: ALIGNED —
existing site content confirmed untouched.

---

## cp2-docs-refresh-complete

**Phase:** 2 — Refresh docs against forqsite drift
**Tag command:** `git tag cp2-docs-refresh-complete && git push origin cp2-docs-refresh-complete`
**Acceptance:** All 5 stories complete (CONTENT-001..004, INFRA-001) — consistency
fixes, repo-grounded embellishments, UX fixes (hash routing/scroll reset/responsive
layout/deep links/clipboard fallback), prose decluttering, and README's
generated-artifact framing revisited. Build gate: static HTML, both bundles render
clean (no error banners) in headless Chromium. Security audit: 0 CRITICAL/HIGH (2
informational findings, both pre-existing upstream flex infrastructure, out of this
project's diff). Intent review: 4/5 stories ALIGNED, CONTENT-004 PARTIAL (one named
GAP-006/GAP-011 reword line item not applied — logged as CER-001, Do Later, not
blocking). `docs/architecture.md` backfilled with bundle-format/module-structure/
protected-files content per intent-reviewer recommendation.

---

## cp-8

**Phase:** 8 — The promotion path, and what a pack may carry
**Tag command:** `git tag cp-8 && git push origin main --tags`

**Naming note:** the two tags above (`cp1-bootstrap-complete`, `cp2-docs-refresh-complete`)
predate the current `cp-<N>` convention. A `git tag -l 'cp-*'` glob does not match them —
use `git tag -l` unfiltered when asking what has been tagged. This project's Phase 9
audit initially recorded, wrongly, that no phase had ever been tagged for exactly that
reason.

**Phases 3-7 have no entry here and no tag.** From Phase 3 until Phase 8, the build-gate
guard shelled out `test_command`, which held a prose description rather than a runnable
command, and failed red (exit 127) on every checkpoint attempt. Those phases were marked
complete in `docs/phases/index.md` without ever passing a green gate. Whether to
back-tag them is an open operator question — see `docs/pairmode-wiring-audit.md`.

**Acceptance:** All 4 stories complete (CONTENT-016..019) — the three-stream promotion
model with a hand-authored inline SVG lane diagram, the ceiling on what a provider pack
may carry, expand-and-contract in the Day-two runbook, and GAP-012 recording the
content-migration gap. Every story passed review on its first attempt.

**Gates:** security PASS (0 CRITICAL/HIGH). intent ALIGNED — with one HIGH finding: the
new #promote page named `rolling-restart.sh` as the non-docker/systemd path's restart
command, contradicting the site's own Process supervision section and GAP-004. Neither
story reviewer could have caught it: CONTENT-018's spec barred that exact claim, and
CONTENT-016's — written first — did not. docs **FAIL on five documentation-currency
findings**, which blocked the tag. dark-feature-scan FAIL (orphaned `gate-worker.md`).

**Remediation:** Phase 9 (CONTENT-020..022) fixed the defect and the docs findings. The
docs gate was re-run against phase 8 and returned PASS; dark-feature-scan re-run PASS.
`cp-8` is the first tag under the `cp-<N>` convention.

---

_(Add a checkpoint section for each phase. Tag only after full checkpoint sequence passes.)_
