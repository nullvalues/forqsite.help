---
era: "001"
phase_class: production
---

# forqsite.help — Phase 12: One stamp per release: re-verify every published claim against one forqsite commit

← [Phase 11: Make the deploy repeatable, and make drift visible](phase-11.md)

<!-- Phase doc = planning surface only. Story-level detail (acceptance criteria,
     file paths, implementation guidance, test instructions, codebase recon)
     belongs in docs/stories/<RAIL>/<ID>.md — not here. -->
## Goal

<!-- State this phase's single purpose in one or two sentences (docs/architecture.md
     § Phase-authoring convention, INFRA-243). If the work naturally splits into more
     than one purpose, that's a signal to open a sibling phase, not to widen this one. -->
Re-verify every stamped claim in both published pages against a single pinned forqsite commit, restamp them uniformly, and leave behind a claims manifest that a later phase can check automatically.

## Why this phase exists

Both published pages make claims about forqsite's behaviour. Each claim carries a
date-and-commit stamp saying which forqsite commit it was last verified against. On
2026-09-23 the operator found the Known gaps callout still stamped `17b78645` from
2026-09-16, while other claims on the same page carry `7089b9dc` from 2026-09-18 to 21.
CER-029 had already found the same pattern on one `gap-handoff.html` claim. The stamps
drifted because each story re-verified only the claims it touched. The stamp therefore
dates individual claims, not the page. A reader cannot tell which forqsite the page
describes as a whole.

forqsite has moved 137 commits past `17b78645`. Some gaps may have closed. Some claims may
now be wrong.

The operator's intent (2026-09-23): the content is verified and stamped once per docs
release, against one forqsite commit, and eventually forqsite.help ships automatically to
match the current forqsite build. This phase does the first half by hand, once. It also
builds the piece that automation needs and that does not exist today: a machine-readable
list of what each claim asserts and where in forqsite the evidence lives.

**Takes over CER-029.** That finding is resolved by this phase, not separately.

## What this phase is not

- **Not automation.** No trigger, CI job or scheduled check. The claims manifest is built
  so that a later phase can check it mechanically; building the checker is that phase's
  job.
- **Not a revision of `docs/brief.md`.** The brief lists "real-time sync of
  `gap-handoff.html` with the actual state of forqsite" as out of scope, and requires "no
  build step". Automatic releases would change both. That is an operator decision to take
  before the automation phase, not a side effect of this one.
- **Not a content rewrite.** Claims are corrected only where re-verification finds them
  wrong. Gaps are closed only when forqsite has closed them. Wording changes for their own
  sake are out.

## Release commit

This phase verifies against one forqsite commit:
`nullvalues/forqsite@1fda3228322d5ad779f44c321c4013ccd247b3fa`, committed 2026-09-24 and
pinned 2026-09-24 (the tip of `main` in the forqsite repository when CONTENT-030 was built).
The authoritative copy is the `release` object in `docs/claims-manifest.json`. If the two
ever disagree, the manifest wins.

## Stories

| ID | Title | Status |
|----|-------|--------|
| CONTENT-030 | Inventory every stamped claim into a committed claims manifest | complete |
| CONTENT-031 | Re-verify and restamp the Known gaps list in both pages | complete |
| CONTENT-032 | Re-verify and restamp every remaining claim, and pin the pages to one release commit | complete |

### CONTENT-030 — The claims manifest

**Done when** a committed manifest lists every stamped claim in both pages. For each claim
it gives: an id, the page and location, the claim in one sentence, where in forqsite the
evidence lives (path and symbol or behaviour, never a host or an operator path), and the
stamp the claim currently carries. The manifest is derived from the pages through
`scripts/bundle-template.py extract`, not by grepping the bundle. It counts every stamp
occurrence, and each count matches the extracted templates.

**Done when** the release commit this phase verifies against is pinned in the manifest and
in the phase doc: one forqsite commit, chosen at build time and recorded with its date.

**Not done if** a stamp in either page has no manifest entry, or the manifest invents a
claim the page does not make.

### CONTENT-031 — The Known gaps list

**Done when** every Known gaps entry in both pages has been re-verified against the pinned
commit. Each is still open, changed or closed, and a closed gap is removed from the list
with the forqsite commit or file that closed it recorded in the manifest. Any gap the
re-verification finds that the list lacks is added. The Known gaps callout and its
`gap-handoff.html` counterpart carry the pinned commit and verification date.

**Not done if** a stamp changes without its entries being re-checked. A restamp is a claim
of verification. It is never a find-and-replace.

### CONTENT-032 — Every remaining claim, one release stamp

**Done when** every other stamped claim in the manifest has been re-verified against the
pinned commit, corrected where wrong, and restamped. This includes CER-029's ordering
assumption and the claims currently stamped `7089b9dc`. Both pages then carry exactly one
forqsite commit in their stamps. A reviewer can check that with one extract and grep per
page.

**Done when** both pages pass `bundle-template.py verify`, render (CER-005 and CER-012
apply: strip `<script>` before asserting a render), and are deployed. The drift check's
provenance line then names the release commit's deploy.

**Not done if** a claim that could not be verified keeps a fresh stamp. It is marked as
unverified, with the reason, instead.

## Story ordering

CONTENT-030 runs first, because both later stories work from its manifest and the pinned
commit it records. CONTENT-031 and CONTENT-032 both edit both pages, so they run one after
the other, CONTENT-031 first. Each merges before the next branches.

## After this phase: the path to automatic releases

Recorded 2026-09-23 so that it survives between sessions. This is not in this phase's scope.
The operator's goal is for forqsite.help to ship automatically, matching the current forqsite
build. Measured against that goal:

- **Deploy is close.** `deploy.sh` and `drift-check.sh` are verified end to end against
  production. They are run by hand from a host with `scripts/deploy.env`. Neither repo has CI.
- **The claims manifest is missing.** This phase builds it.
- **A stale-claim check is missing.** Given the manifest, a checker can re-examine each
  claim's evidence at a new forqsite commit and list the claims whose evidence changed.
- **Rewriting a claim needs judgment.** Automation can detect the need and draft the change;
  a person still reviews the fix.
- **forqsite has no release event.** `package.json` is at `0.0.0` and there were about 138
  commits in the week to 2026-09-23. The `cp-PM*-main` checkpoint tags are the natural
  trigger.
- **`docs/brief.md` conflicts with the goal.** It rules out real-time sync with forqsite and
  requires no build step. Revise it before any automation is built.

Proposed sequence:
- **Phase 13:** revise the brief, then build a stale-claim checker keyed on forqsite
  checkpoint tags.
- **Phase 14:** a release job. When nothing is stale it restamps and deploys; when something
  is, it opens the stale claims for review.

Fully hands-off releases are realistic only when no claim has gone stale.

## Schema delivery

For each new persistent schema object (table, collection, migration) introduced in
this phase, record the management surface before the phase is checkpointed.

| Object | Management surface | Exception |
|---|---|---|
| _(none)_ | — | No database. The claims manifest is a committed text file; its management surface is the repository itself, edited by the stories that re-verify claims. |

---

### CP-12 Cold-eyes checklist

- [ ] written-never-read — does anything this phase persists have no reader?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] half-implementation — is any branch unreachable, or any producer without its consumer?

— developer fills in after phase completion —
