# forqsite.help Pairmode — Checkpoints

Each checkpoint is tagged after all stories in the phase pass the full checkpoint sequence
(build gate → security audit → intent review).
Before `checkpoint-tag`, run `scripts/drift-check.sh` by hand and record its exit code and result block in that phase's own checkpoint section below (see `docs/architecture.md` § Deployment for why this step is manual); a drift exit blocks the tag until a deploy corrects it and the check is re-run.

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
complete in `docs/phases/index.md` without ever passing a green gate. The operator
ruled, on 2026-09-21 (CONTENT-026), that they stay untagged: a `cp-<N>` tag asserts
the checkpoint sequence passed, and for these phases it did not — back-tagging would
record a gate result that was never obtained, making this file less trustworthy
rather than more. The work itself is not unverified, because later phases re-check it
regardless: the checkpoint gates run against the current tree, not a phase-scoped
diff (cp-8's dark-feature-scan failed on an artifact that predated Phase 8 — recorded
above in this same file), and Phase 10's CONTENT-024 re-read and corrected
`docs/phases/phase-4.md`. The gap from 3 to 7 in the `cp-*` series is therefore a deliberate state recorded here, not an oversight, and not an invitation to
backfill. CER-007 is closed against this record.

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

## cp-9

**Phase:** 9 — Close CP-8: the defect the checklist missed, and the wiring that predates the convention
**Tag command:** `git tag cp-9 && git push origin main --tags`

**Acceptance:** All 3 stories complete (CONTENT-020..022). A remediation phase, parented
to Phase 8, created because CP-8's docs gate refused to tag. CONTENT-020 audited this
repo's pairmode wiring against flex 0.4.7 convention and recorded it in a standalone
wiring audit, since removed from this repository in Phase 10 (CONTENT-025) because its
subject is the build harness; CONTENT-021 corrected the `rolling-restart.sh` claim on
the Promoting a change page; CONTENT-022 brought `docs/architecture.md` and the era
ledger current. Every story passed review on its first attempt.

**Gates:** security PASS (0 CRITICAL/HIGH; three public-hygiene items filed as CER-002,
CER-003, CER-004). intent ALIGNED, with two LOW advisory findings — this file was stale,
and the wiring audit had no staleness trigger; both were fixed as checkpoint remediation
before the docs gate ran. docs **FAIL, then PASS on re-run**. dark-feature-scan PASS.

**The docs FAIL is worth reading.** `architecture.md` named Phase 7 as most recently
complete after `cp-8` had flipped Phase 8 to complete. The cause was structural, not
textual: `flex_build.py`'s checkpoint-tag step maintains a machine-owned `Current phase:`
line anchored to a hand-maintained `Current era:` line, and this project's
`architecture.md` had never carried that anchor — so every tag emitted `warning: ... no
'Current era:' anchor line — skipping phase pointer stamp` and the pointer was never
auto-maintained. Correcting the wording alone would have gone stale again at the next
tag. The anchor was added instead, and the pointer now self-updates.

**Lesson recorded:** documentation findings raised by a checkpoint gate are checkpoint
remediation — fix them, re-run the gate, re-record. Phase 9 itself was shaped as a full
phase, which the intent gate judged proportionate given CONTENT-020's independent audit
scope, but the two blocking docs findings alone did not warrant it.

---

## cp-11

**Phase:** 11 — Make the deploy repeatable, and make drift visible
**Tag command:** `git tag cp-11 && git push origin main --tags`

**Acceptance:** All 11 stories complete: INFRA-006..014, CONTENT-028 and CONTENT-029. The
phase grew twice. The CP-11 security gate's first run added INFRA-009 and CONTENT-029. The
`cer-do-now` guard then refused the checkpoint, and the operator pulled in all eight
remaining audit findings as round 2 (INFRA-010..014). Three stories needed a second
attempt: CONTENT-029, INFRA-012 and INFRA-013. Each first attempt failed on a real defect,
and each fix went into the spec before the retry.

**Gates:** the first security and docs verdicts were stale once remediation changed both
scripts, so both were re-run against the tree after INFRA-014. security PASS (opus; CER-019
to CER-028 confirmed closed in code; four LOW findings filed as CER-033 to CER-036). docs
PASS. intent ALIGNED. dark-feature-scan PASS.

**Drift check: run after the tag, not before it.** The step this file's header requires was
skipped: `cp-11` was tagged on 2026-09-22 without it, because the build host had no deploy
configuration. That is the same gap this phase exists to close. The check was run on
2026-09-23, once the configuration existed. First run, exit 0:

```
index.html          ok  5890637970f251fbfcf460241a208fdd7d927635aba992e80f6161737f88ed05
gap-handoff.html    ok  d774cb39effc7d5f4d02d39ae4fec621c3d3662fb1fef01c4e8a0f6203faffc6
provenance         absent or unreadable — the bundle result above does not depend on it
result             ok — served bytes match the ref for all 2 bundles
```

The bundles were current, but the provenance sidecar had never been served. `deploy.sh` had
never run against production; the last deploy was the manual one recorded in
`docs/architecture.md`. The container also had no bind mount for the sidecar. Fixed in the
bootstrap order `deploy.sh`'s header requires: `deploy.sh` published `21e6e2a` (all three
files verified on the far side), the sidecar mount was added to the compose file, and the
container was recreated. Re-run, exit 0:

```
ref                21e6e2acbad54dfb2aabe4d49e104e86c8eb75e8  21e6e2a
index.html          ok  5890637970f251fbfcf460241a208fdd7d927635aba992e80f6161737f88ed05
gap-handoff.html    ok  d774cb39effc7d5f4d02d39ae4fec621c3d3662fb1fef01c4e8a0f6203faffc6
provenance         claims 21e6e2a deployed 2026-09-23T02:31:14Z  (claim, not the basis of the result above)
result             ok — served bytes match the ref for all 2 bundles
```

**Lesson recorded:** the drift check is not optional when the checking host lacks the
configuration. A missing configuration is a reason to stop and ask, never a reason to
skip the step. Tagging without the check reproduced, in small, the proxy substitution this
phase names: "the gates are green" stood in for "the site is what we committed."

---

_(Add a checkpoint section for each phase. Tag only after full checkpoint sequence passes.)_
