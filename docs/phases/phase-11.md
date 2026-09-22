---
era: "001"
phase_class: production
---

# forqsite.help — Phase 11: Make the deploy repeatable, and make drift visible

**Parent phase:** Phase 10 — Name the class, not the instance — and close the backlog by resolving, never deleting

← [Phase 10: Name the class, not the instance — and close the backlog by resolving, never deleting](phase-10.md)

<!-- Phase doc = planning surface only. Story-level detail (acceptance criteria,
     file paths, implementation guidance, test instructions, codebase recon)
     belongs in docs/stories/<RAIL>/<ID>.md — not here. -->
## Goal

<!-- State this phase's single purpose in one or two sentences (docs/architecture.md
     § Phase-authoring convention, INFRA-243). If the work naturally splits into more
     than one purpose, that's a signal to open a sibling phase, not to widen this one. -->
Give this project a deploy procedure that survives the person who ran it, and a check that says whether what is live matches what is committed.

## Why this phase exists

On 2026-09-21 the live site was found serving Phase 7 content while the repository stood at
Phase 9 — five days and two phases stale. Nobody noticed, and nothing was broken: `cp-8` and
`cp-9` both went fully green over it. Among the content that had never reached readers was a
correction to a factual claim, so the site was telling operators something the repository had
already fixed.

The gates did not fail. They asserted the wrong thing. Every check compared the repository to
itself and stopped at the edge of the repository, which is a cheap proxy for the question that
matters — *are the bytes being served the bytes that were committed?* Three findings already on
the backlog (CER-009, CER-011, CER-012) describe the same mistake in smaller places: an
assertion written against something easy to compute instead of against the invariant. The stale
site is the fourth and most expensive instance.

The deploy itself worked, by hand, in one session. That is the other half of the problem: the
procedure existed only in the person who ran it.

## What this phase is not

This phase deploys working docs to a production site. It is not a repair of the build harness.
Phase 10 ruled in CONTENT-025 that the build tooling is not this project's subject and moved an
audit of it out of the repository; that ruling binds here. Two backlog rows were considered and
deliberately left out:

- **CER-013** — the build loop's contract never names its own commit step. Build-process, not
  deploy. Its fix shape for this phase is *conduct*, not a story: the orchestrator lands every
  story in this phase with `commit-story-worktree`. The contract gap is referred upstream; the
  row stays open here, because a referral is not a fix.
- **CER-009 / CER-011 / CER-012** — the per-instance probe repairs are harness work and stay
  filed. The *pattern* enters this phase where it has a forcing function: as a forbidden-proxy
  clause in the drift check's own Ensures. The lesson is named by being built once in the place
  it cost something, not by a story that writes a paragraph about it.

**CER-005 stays filed in Do Later.** The ledger renders zero rows as DOM at any origin and the
`#gaps` fragment renders no screen. That is a bundle defect, and fixing it is a generated-artifact
re-export plus a diagnosis of whether the non-render is real or a headless artifact — a sibling
content phase's subject, not this one's. Two consequences follow for this phase and are binding:
the drift check must be **byte-level and must not depend on a render**, or it inherits CER-005 and
CER-012 on its first run; and this phase knowingly ships a bundle with a dead fragment. That is a
deliberate, recorded state, not an oversight.

## Stories

| ID | Title | Status |
|----|-------|--------|
| INFRA-006 | A deploy procedure that survives the person who ran it | complete |
| INFRA-007 | A drift check that compares served bytes to committed bytes | complete |
| INFRA-008 | Site provenance a reader and a check can both see | complete |
| CONTENT-028 | Record the procedure, the incident, and the lesson | complete |
| INFRA-009 | Keep the configured destination out of a failing drift check's output | complete |
| CONTENT-029 | Record the site-URL ruling in the rule it extends, and scrub what it now covers | complete |
| INFRA-010 | Make the drift check's output and fetches safe against a hostile origin | complete |
| INFRA-011 | Make the deploy's remote command safe to construct | complete |
| INFRA-012 | Stage deploys unpredictably and bound the backups they leave | complete |
| INFRA-013 | Read the deploy config as data, never execute it | complete |
| INFRA-014 | Keep the configured destination out of the deploy's transport errors | draft |

### INFRA-006 — The deploy procedure

**Done when** a script in the repository performs what was done by hand on 2026-09-21: back up
the live bundles with a timestamp, copy the committed `index.html` and `gap-handoff.html`, verify
each file's hash on the far side, and print the git ref deployed.

**Done when** the host is reached only through an ssh alias and the remote directory comes only
from configuration — an environment variable or a gitignored local file. Phase 10's
*name the class, not the instance* constraint binds: no host name and no absolute deployment path
re-enters the tree, including in a comment or an example.

**Not done if** it will deploy a dirty working tree for either bundle. Deploying uncommitted bytes
is the drift this phase exists to end, and a procedure that permits it has recreated the problem
in a script.

**Not done if** it restarts the container as a matter of course. Only three files are bind-mounted
and no `open_file_cache` is set, so a copy is served on the next request. `nginx.conf` is the one
mount whose change needs a container action; that is a documented note, not a step this story runs
by default.

### INFRA-007 — The drift check

**Done when** a script answers "does what is live match what is committed?" by comparing the
sha256 of the **bytes an HTTP request actually returns** against the sha256 of the file at the
committed ref, for both served bundles, and exits non-zero on a mismatch.

**Done when** the output names which commit the live bytes match, not merely that they differ —
"live matches Phase 7 content, HEAD is Phase 10" is the sentence that made the original diagnosis
useful in minutes.

**Not done if** the assertion rests on a proxy. Forbidden, explicitly: file mtime, file size, a
version string or phase marker grepped out of the served HTML, the container reporting itself up,
scp exiting zero, or hashing the file in the remote directory *instead of* the bytes a request
returns. CER-009, CER-011 and CER-012 are three prior instances of this exact substitution; this
Ensure is where the pattern is answered.

**Not done if** it depends on the page rendering. See CER-005 above.

**Note the asymmetry rather than hiding it:** `nginx.conf` is bind-mounted but never served, so it
cannot be checked the same way. Say so in the output; do not silently omit the file.

### INFRA-008 — Site provenance

**Done when** the live site carries a machine-readable record of which commit of *this*
repository produced it. Neither bundle currently contains any reference to this repo's own
commit or version — verified, zero occurrences — which is why five days of staleness had nothing
a reader or a check could look at.

**Done when** the provenance is written at deploy time as a sidecar served alongside the bundles,
so both bundles stay **byte-identical to their committed form**. A stamp written into a bundle at
deploy would break the equality INFRA-007 depends on, and a stamp committed into a bundle would
put a generated-artifact edit in the release path.

**Not done if** it rewrites any `verified <date> against <product-commit>` stamp in the content.
Those record when a claim was checked against the product, and moving one at deploy time asserts a
verification that never happened. That is the failure Phase 10 spent itself correcting.

### CONTENT-028 — Record it

**Done when** `docs/architecture.md` § Deployment describes the deploy and drift-check procedures
by class — the configuration surface, what is backed up, what is compared — without naming an
instance.

**Done when** `docs/checkpoints.md` carries one line in the checkpoint sequence requiring the
drift check to be run and its result recorded, so a green checkpoint can no longer be silent about
the live site. If the gate can only be wired inside the build harness, this degrades to a
documented mandatory manual step and stops at this repository's edge — it does not follow the
problem into the harness.

**Done when** `docs/ideology.md` carries one paragraph naming the class: *assert the invariant,
not a proxy for it*, citing the stale-site incident as the instance that cost five days and
CER-009/011/012 as the rows that observed it. One paragraph, deliberately sized so it cannot grow
into the three findings' individual repairs.

**Done when** the 2026-09-21 hand deploy is recorded as a dated verification record, and CER-014
is resolved by INFRA-007 landing.

## CP-11 remediation

The CP-11 security gate passed — no CRITICAL, no HIGH — and filed nine findings. Seven are
backlog. Two were created by this phase and are fixed here rather than deferred, because both
are cheap and both undercut something this phase or the operator just established.

### INFRA-009 — Keep the destination out of a failing check's output

**Done when** a failing `scripts/drift-check.sh` run prints no configured value. Its failure
paths currently emit curl's stderr and the redirect target verbatim, and both embed the base
URL. `docs/checkpoints.md`, written by CONTENT-028, directs the operator to record that output
in a committed public file — so this phase built a procedure that publishes the value the
operator ruled must stay out of the tree.

**Done when** the hygiene assertion covers the failure blocks, not only the success block.
INFRA-007 scoped its guarantee to the success path; the block an operator actually pastes on a
failing run was never tested. That gap is why the defect shipped.

**Not done if** the redaction drops the diagnostic. A reader must still be able to tell a
connection refusal from a timeout from a redirect — replace the value, keep the reason.

### CONTENT-029 — Record the ruling in the rule it extends

**Done when** `docs/ideology.md` § Name the class, not the instance states that the public site
URL is covered, with the operator's reason: this repository and its product are to be released
as public sibling repos, and a downstream adopter rebrands both, so the URL names our instance
rather than the product.

**Done when** the occurrences that rule now covers are generalised — the auditor found them in
`README.md`, `docs/architecture.md`, `docs/phases/phase-4.md` and `docs/stories/INFRA/INFRA-002.md`.
Re-derive the list rather than trusting it.

**Not done if** a reader loses the ability to find the live site or to reconstruct the hosting
arrangement. Phase 10's standard applies: the reason must survive generalisation.

**Not done if** the published bundles are touched. They are out of scope for this phase entirely.

### Round 2 — the rest of the audit, pulled in by the operator

The `cer-do-now` checkpoint guard refused CP-11 on CER-025, CER-026 and CER-027: they were filed
in Do Now while this doc called them carried. The operator ruled on 2026-09-22 to build all
three, and to pull forward the five other findings from the same audit that touch the same two
scripts — CER-019, CER-021, CER-023, CER-024 and CER-028. Eight findings, five stories, grouped
by file and by concern.

### INFRA-010 — The drift check against a hostile origin (CER-026, CER-021)

**Done when** every sidecar field `scripts/drift-check.sh` prints is reduced to its expected
character class at extraction, so no control or escape sequence from the origin reaches the
operator's terminal or the report block they paste.

**Done when** both fetches bound their size and restrict their scheme; `file://` is refused.

**Not done if** the check can be fooled by the sanitising. The byte comparison runs on the raw
fetched file, never the display copy — a field that differs must still read as drift.

### INFRA-011 — The deploy's remote command (CER-025, CER-019)

**Done when** the configured alias is constrained to a hostname-shaped class that cannot begin
with `-`, and refused before any `ssh` call.

**Done when** no value reaches the far shell in bash-only quoting. Every quoted value must be
valid under POSIX `sh`, because the remote login shell is not ours to choose.

**Not done if** a configuration that deploys today stops deploying.

### INFRA-012 — Staging and backups (CER-023, CER-027)

**Done when** each file is staged at an unpredictable name created exclusively on the far side,
not a predictable name opened with `cat >`.

**Done when** backups are bounded to a stated retention count.

**Not done if** pruning can remove the rollback copy of a deploy that failed verification. Prune
only after a verified deploy, and never the backup it just made.

### INFRA-013 — The config is data (CER-024)

**Done when** neither script `source`s the config. Both parse `KEY=value` lines for the keys they
know, and refuse any other line by line number, without printing its value.

**Not done if** any part of a value is ever evaluated. `$(...)` and backticks in the file are
literal text.

### INFRA-014 — The deploy's transport errors (CER-028)

**Done when** a failing deploy prints what went wrong (the host would not resolve, auth was refused,
the remote directory is missing) without the configured alias or directory. The failure output is
asserted the same way INFRA-009 asserted the drift check's.

**Not done if** interactive authentication breaks. Capturing `ssh`'s stderr must not swallow a
passphrase or host-key prompt.

### Gate state — read this before tagging CP-11

`checkpoint-security` is recorded PASS for this phase, and that verdict is **stale**. It was
recorded on 2026-09-22 against the tree as it stood *before* INFRA-009 and CONTENT-029, and
those two stories exist because that audit found the defects. The resolver will not re-emit a
step whose verdict is already recorded, so a session resuming here would tag over an unaudited
change to `scripts/drift-check.sh`.

**Before `checkpoint-tag`:** re-run `checkpoint-security` and `checkpoint-docs` against the
remediated tree and re-record both verdicts, then `checkpoint-intent`, the dark-feature scan and
`checkpoint-report` as normal. Security is worth re-running with an escalated model — this phase
ships executable code that authenticates to a production host, which the first CP-11 audit
treated as a materially different risk surface from Phase 10's documentation.

The same holds, with more force, after round 2: INFRA-010 through INFRA-014 change both scripts
again, so the re-run must audit the tree as it stands after INFRA-014.

Remaining after INFRA-014: the two gate re-runs above, `checkpoint-intent`, the dark-feature
scan, `checkpoint-report`, then `record-checkpoint-step checkpoint-tag` → commit the ledger paths
→ `git tag cp-11`.

**Superseded:** this section used to say that CER-019, CER-021 and CER-023 through CER-028 were
carried and not built. Round 2 builds all of them. One observation has no row yet and should get one: CER-014, CER-020 and CER-028 share
a shape — a guarantee tested on the success path and assumed on the failure path. The stale site
itself was the same thing at a larger scale. That may be a sharper form of the constraint
CONTENT-028 added to `docs/ideology.md`, and belongs to a later phase's framing rather than this
one's.

## Story ordering

INFRA-006 and INFRA-007 are independent and may run in either order. INFRA-008 follows INFRA-006,
because the sidecar is written by the deploy path. CONTENT-028 runs last: it documents what the
other three built, and cannot describe a procedure that does not exist yet.

The round-2 stories run in table order after CONTENT-029: INFRA-010, then INFRA-011 through
INFRA-014. Each merges before the next branches, so two stories touching `scripts/deploy.sh` never
build over each other. INFRA-013 changes how both scripts load their config, so whichever story
follows it builds against the new loader.

## What is NOT in scope

- **Fixing CER-005's render gap.** Sibling content phase.
- **Any change to the published bundles.** This phase builds the path that carries them; it
  carries no content of its own.
- **Repairing the build harness**, in any form, including the contract gap CER-013 names.
- **Automating deploy on merge.** The phase makes the deploy repeatable and the drift visible; who
  runs it, and when, stays an operator decision.

## Schema delivery

For each new persistent schema object (table, collection, migration) introduced in
this phase, record the management surface before the phase is checkpointed.

| Object | Management surface | Exception |
|---|---|---|
| _(none)_ | — | No persistent schema object: static HTML, no database. |

---

### CP-11 Cold-eyes checklist

- [ ] written-never-read — does anything this phase persists have no reader?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] half-implementation — is any branch unreachable, or any producer without its consumer?

— developer fills in after phase completion —
