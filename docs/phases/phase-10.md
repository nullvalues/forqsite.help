---
era: "001"
phase_class: docs-only
---

# forqsite.help — Phase 10: Name the class, not the instance — and close the backlog by resolving, never deleting

**Parent phase:** Phase 9 — Close CP-8: the defect the checklist missed, and the wiring that predates the convention

← [Phase 9: Close CP-8: the defect the checklist missed, and the wiring that predates the convention](phase-9.md)

<!-- Phase doc = planning surface only. Story-level detail (acceptance criteria,
     file paths, implementation guidance, test instructions, codebase recon)
     belongs in docs/stories/<RAIL>/<ID>.md — not here. -->
## Goal

<!-- State this phase's single purpose in one or two sentences (docs/architecture.md
     § Phase-authoring convention, INFRA-243). If the work naturally splits into more
     than one purpose, that's a signal to open a sibling phase, not to widen this one. -->
Bring every open backlog finding to a recorded disposition, and establish that this project documents approaches by their class rather than by our specific implementation.

## Why this phase exists

Seven findings accumulated across Phases 2, 8 and 9. Triage found they are not seven
problems — they are four different kinds of thing wearing one label, and two of them had
already expired without anyone re-reading them.

One turned out to be a bad filing: the record claimed the shipped bundle does not render
when opened from disk, which would have violated a stated non-negotiable. It was tested
under every condition it described, including with all DNS blackholed, and the site
renders completely. That finding is closed as obsolete with the reproduction recorded, so
it is not re-raised on a hunch.

The operator ruled on the four questions no story had standing to answer. This phase
executes those rulings and closes the rest.

## The principle this phase establishes

**Name the class, not the instance.** When this project documents an approach, it
describes the shape of the thing — the constraint, the topology, the reason — not our
particular deployment of it. A host name, a directory path or a machine identifier is our
implementation detail; it is not what a reader needs and it is not their business.

This is not only a public-repo hygiene rule. Naming the instance is *worse documentation*:
it describes one arrangement where the reader needs the rule that generated it. "Same
Docker host as the edge proxy, because that network's embedded DNS only resolves within
one host" tells a reader what to do on their own infrastructure. A host name tells them
about ours.

The published site already follows this — the cold-eyes checklists forbid build-process
and instance vocabulary, and the gates enforce it. The repository does not. This phase
closes that gap and writes the rule down where it survives.

## What triage found

| Finding | What it actually is | Disposition |
|---|---|---|
| Duplicated gap wording | Stale — half its target was pruned in Phase 5, three phases before anyone re-read it | Re-verify, then reword or close as superseded |
| Published source citations | Operator ruling | **Keep**, recorded as deliberate policy |
| Our host name and paths, in four files | Operator ruling | **Generalise**, all four |
| Build-tooling audit in this repo | Operator ruling | **Move out** — not this project's subject |
| Bundle allegedly fails from disk | Bad filing | **Obsolete** — tested air-gapped, renders completely |
| Flex effort-recording defect | Another project's bug | Referred upstream |
| Phases 3-7 never gated | Operator ruling | **Leave untagged**; later phases re-check the work |

## The prerequisite

`docs/cer/backlog.md` predates flex 0.4.7's resolution-marker convention. Flex's template
specifies `RESOLVED` / `SUPERSEDED` / `OBSOLETE` markers that `cer.is_resolution_marked`
reads for the checkpoint guard; this repo's header says only that resolved findings "remain
in place." Without the markers a row has two states — present, or deleted. That is the
failure mode this phase exists to avoid, so the convention lands first.

## Stories

| ID | Title | Status |
|----|-------|--------|
| CONTENT-023 | Bring the backlog's resolution-marker convention current so a finding can be closed without being deleted | complete |
| CONTENT-024 | Record name-the-class-not-the-instance as an accepted constraint, and generalise our infrastructure identifiers out of all four files | complete |
| CONTENT-025 | Move the build-tooling audit out of this repository and refer the flex defect to the project that owns it | complete |
| CONTENT-026 | Record the publication policy and the phases 3-7 ruling where each belongs | draft |
| CONTENT-027 | Close the two stale findings: the duplicated gap wording, and the disproved air-gap claim | draft |

### CONTENT-023 — Make a finding closable

**Done when** `docs/cer/backlog.md`'s header states flex 0.4.7's resolution-marker
convention in substance — the three markers, where they may appear, and the checkpoint
guard that reads them — closely enough that a marker written under it would actually be
matched by `cer.is_resolution_marked`.

**Not done if** any existing row's text, ID, quadrant or ordering changes. This story
edits the header. It resolves nothing.

### CONTENT-024 — Name the class, not the instance

**Done when** `docs/ideology.md` carries the principle as an accepted constraint,
alongside Zero runtime dependencies and Generated-artifact discipline, stating both the
documentation argument and the hygiene one; **and** our host name and deployment paths are
gone from all four files that carry them, replaced by the constraint that made us choose
that arrangement.

The live architecture doc and the historical phase and story docs are all in scope. A
public repository leaks the same string either way, and a reader grepping it does not care
which file was historical.

**Not done if** the replacement drops the operational reason. A reader must still be able
to reconstruct why the arrangement is what it is — same Docker host as the edge proxy,
per-site directory, because that network's embedded DNS resolves within a single host.

**Not done if** the generalisation reaches the published bundles. They are already clean;
this is a repository fix.

### CONTENT-025 — Move what is not ours

**Done when** the build-tooling audit no longer lives in this repository, its genuinely
project-specific facts survive where they belong, and the references that pointed at it
resolve to something real.

The audit records this project's pairmode configuration and its drift from flex
convention. That is a subject about the build harness, not about administering forqsite.
The reason phases 3-7 are untagged already lives in `docs/checkpoints.md`, which is its
right home and is unaffected.

**Done when**, additionally, the flex effort-recording defect is written up for the
project that owns it — the symptom, the affected rows transcribed (the evidence lives in
a gitignored directory and cannot be cited by path), and whether it duplicates a finding
already open there.

**Open decision, to be settled before this story builds.** "Move it out" needs a
destination, and the obvious one is the build tooling's own repository. Writing into
another repository from a story here is a boundary this project has not crossed, and the
per-story permission manifests are scoped to this repo by construction. The alternatives
are: produce a paste-ready document here for the operator to file, keep the record
operator-local and untracked, or authorise the cross-repo write explicitly. This story
cannot choose for the operator.

**Not done if** anything under the flex cache is modified. It is another project's source,
and this story's own subject is a defect in it.

**Not done if** the transcribed evidence carries an operator identity, an absolute home
path or a machine name — the principle this phase establishes applies to the write-up too.

### CONTENT-026 — Record the two rulings

**Done when** the decision to keep publishing source citations is written down as
deliberate policy in a document that survives, with its reason: those paths name the
reader's own source tree, and the citations are what make the site's claims checkable.
Recording it is the point — it stops the question being re-raised at every checkpoint.

**Done when** the decision to leave phases 3-7 untagged is recorded in
`docs/checkpoints.md` with its reason, including that later phases re-check the work
regardless, so the absence of those tags is a deliberate state rather than an oversight.

**Not done if** a `cp-3`..`cp-7` tag is created. A tag asserts a checkpoint passed; for
those phases it did not.

### CONTENT-027 — Close what has expired

**Done when** the duplicated-wording finding is re-checked against the current bundle
rather than against its own description. Its twin was pruned in Phase 5; if no live
duplicate remains, it closes as superseded, with a note explaining why the row outlived
its own target.

**Done when** the air-gap finding closes as obsolete, carrying the reproduction that
disproved it: the bundle opened from disk, headless, with DNS blackholed, renders every
ledger row, expands every template tag, and emits no error — byte-identical to the same
run with a network available. Record that the embedded React is mapped to local blob URLs
rather than fetched, so the zero-dependency guarantee holds.

**Not done if** the closure is recorded without the reproduction. A disproved finding that
does not say how it was disproved will be filed again.

**The reproduction, as run (2026-09-21).** Copy the bundle to an empty directory, then:

```
# air-gapped, from disk: every DNS lookup blackholed
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=8000 \
  --host-resolver-rules="MAP * 0.0.0.0" --disable-features=NetworkService \
  --dump-dom "file://<dir>/index.html#gaps"

# control: same bundle served over a loopback static origin
python3 -m http.server <port> --directory <dir>
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=6000 \
  --dump-dom "http://127.0.0.1:<port>/index.html"
```

Observed, air-gapped: exit 0, all nine ledger rows rendered, zero unexpanded template
tags, zero error banners, and output byte-identical to the same run with a network
available. The two origins differ only in the blob-URL prefix (`blob:null/...` versus
`blob:http://127.0.0.1/...`), which is cosmetic. The `unpkg.com` strings in the bundle
are keys in a resource map, not fetches — the embedded React resolves to local blob URLs,
so nothing leaves the machine and the zero-dependency guarantee holds.

Re-run both before closing the finding; do not close it on this record alone.

## Story ordering

CONTENT-023 first and strictly — until a row can be marked resolved, every other story's
only closing move is deletion. The remaining four are independent and may run in any order.

## What is NOT in scope

- **Deleting or re-numbering any finding.** Every row present at the start of this phase is
  present at the end, with its original text and a marker appended. A phase that shortens
  the table has failed even if the table is empty.
- **Re-opening any Phase 8 or 9 content decision.**
- **Patching the flex cache.** The defect is referred, never fixed here.
- **Touching the published bundles**, except for the single gap-wording sentence if
  CONTENT-027 finds a live duplicate.
- **Building tooling to prevent future backlog staleness.** Two findings expired unread;
  that is worth naming as a lesson, not worth a mechanism in this phase.

## Verification obligation

CONTENT-027 makes claims about the current state of both bundles. Each is checked against
the live artifact via the extract path, not against the finding's own wording. Any claim
about forqsite's behaviour carries a date-and-commit stamp per the Phase 6 convention.

## Schema delivery

For each new persistent schema object (table, collection, migration) introduced in
this phase, record the management surface before the phase is checkpointed.

| Object | Management surface | Exception |
|---|---|---|
| | | |

---

### CP-10 Cold-eyes checklist

- [ ] no row deleted — does the backlog contain every finding it contained before this phase, with its original text intact and a marker appended?
- [ ] every close has evidence — does each resolution name a commit, a document, a ruling or a reproduction, rather than asserting a conclusion?
- [ ] no invented ruling — is every recorded operator decision traceable to an answer the operator actually gave?
- [ ] class not instance — does any file this phase touched, or any evidence it transcribed, name a host, an absolute path, a machine or an operator identity?
- [ ] the reason survived — where an identifier was generalised, can a reader still reconstruct why the arrangement is what it is?
- [ ] nothing left dangling — does every reference to the relocated audit resolve to something that exists?
- [ ] no cross-repo patch — is the flex cache unmodified?
- [ ] a disproved finding says how — does the closed air-gap finding carry the reproduction that disproved it?
- [ ] backlog honesty — if any finding grew rather than closed, is it recorded as its own row at the severity it deserves?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] half-implementation — is any branch unreachable, or any producer without its consumer?

— developer fills in after phase completion —
