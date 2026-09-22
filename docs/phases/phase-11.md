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
| INFRA-006 | A deploy procedure that survives the person who ran it | draft |
| INFRA-007 | A drift check that compares served bytes to committed bytes | draft |
| INFRA-008 | Site provenance a reader and a check can both see | draft |
| CONTENT-028 | Record the procedure, the incident, and the lesson | draft |

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

## Story ordering

INFRA-006 and INFRA-007 are independent and may run in either order. INFRA-008 follows INFRA-006,
because the sidecar is written by the deploy path. CONTENT-028 runs last: it documents what the
other three built, and cannot describe a procedure that does not exist yet.

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
