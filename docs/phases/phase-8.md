---
era: "001"
phase_class: production
---

# forqsite.help — Phase 8: The promotion path, and what a pack may carry

← [Phase 7: Write for the reader, not about the work](phase-7.md)

## Goal

The site tells a reader how to get forqsite **running**. It does not yet tell them
how to change a running instance **without breaking it** — how a build becomes a
release, what may be promoted unchanged, which steps cannot be undone, and what a
provider pack is and is not allowed to bring with it.

That is the most-requested missing piece and the least-documented one. This phase
adds it.

## What is missing today

| Reader question | Where the site answers it now |
|---|---|
| How do I stand this up? | "From clone to running instance", "Production, without docker", "systemd units" |
| How do I upgrade it? | "Day-two runbook → Upgrade" — a command sequence, no failure model |
| What is a provider pack? | "Provider packs (condensed)" — registration only |
| **What can I safely promote, and what can I never undo?** | **Nowhere** |
| **Can a pack add database tables?** | **Nowhere** |
| **Why does my rolling restart break on a migration?** | **Nowhere** |

The upgrade section is a recipe with no theory. A reader who follows it and hits a
destructive migration mid-rollover has no way to know, from this site, that the
topology it recommends is what made that fail.

## The three-stream model this phase introduces

Everything below rests on one distinction the site currently does not draw:

| Stream | What moves | Reversible |
|---|---|---|
| Artifact | The built code, including every compiled-in pack | Yes — swap back |
| Schema | Numbered SQL, applied to the database | No |
| Content | Stored block data reshaped for a pack upgrade | No, and no mechanism |

The promotion advice on the page is only sound if a reader can tell which stream
their change is in. That is the teaching job of this phase.

## Source document

The model this phase publishes is written up in full, with the diagrams, at
`docs/deployment/promotion-model.html` **in the forqsite repository** — not on this
site and not at any external URL. Read it before starting. It is the internal
statement of the model; this phase produces the reader-facing one, which is a
different document with different vocabulary rules (below), not a copy.

## Vocabulary constraint — read before writing a word

Phase 7's cold-eyes checklist forbids **build-process vocabulary**: terms only this
project's process defines. The ring model as discussed internally numbers its
environments R0–R4. **That numbering is ours, not the reader's, and must not ship
as-is.**

Use plain environment names on the published page: **local**, **CI**, **standup**,
**staging**, **production**. If a shorthand is wanted for the diagram, define it once
on the page in the same breath as the plain name, and never use it in prose that does
not sit beside the diagram.

## Audience constraint — a self-hoster has one box, not five

The five environments are **roles**, not machines. A single-operator self-hoster will
collapse several of them onto one host, and the page must say so plainly rather than
prescribing infrastructure they will not build.

What the page must convey is which collapses are safe:

- Collapsing **local** and **CI** costs reproducibility, not safety.
- Collapsing **standup** into **staging** costs the fresh-install proof. Acceptable on
  an existing instance; not acceptable before a first go-live.
- Collapsing **staging** into **production** removes the only rehearsal of the two
  irreversible streams. **This is the one collapse the page must advise against**, and
  it must say why in terms of what cannot be undone, not in terms of process hygiene.

A reader who runs one box should finish the section knowing they need a second database
they can throw away — not a second server.

## Stories

| ID | Title | Status |
|----|-------|--------|
| CONTENT-016 | Add a Promoting a change section: the three streams, the environment roles, the lane diagram, and which collapses are safe | complete |
| CONTENT-017 | Rewrite Provider packs (condensed) to state the ceiling on what a pack may store and why installing one needs a rebuild | complete |
| CONTENT-018 | Add the expand-and-contract rule to Day-two runbook Upgrade, derived from the rolling-restart topology | complete |
| CONTENT-019 | Record the content-migration gap as a new numbered entry in Known gaps | complete |

### CONTENT-016 — Promoting a change

**Done when** the page carries:

- The three-stream table, with reversibility stated for each.
- The environment roles as plain names, each with the one class of failure it exists
  to catch — not a description of the machine.
- A lane diagram, **inline SVG, hand-authored** (this site has no build step and loads
  no libraries), showing a pack's path from intake through the build into each
  environment, with the promotion arrow carrying the same artifact.
- The "which collapses are safe" guidance from the constraint section above.
- An explicit statement that the artifact is built once and promoted unchanged, phrased
  consistently with the **non-docker, systemd, tarball-and-symlink** path the site
  already documents. Do not introduce container vocabulary; verify against the existing
  "Production, without docker" and "systemd units" sections before writing.

**Not done if** the diagram uses R0–R4 in prose, or if the section describes forqsite's
internal CI arrangement rather than what a self-hoster should do.

### CONTENT-017 — What a pack may carry

**Done when** the section states, as fact a reader can act on:

- A pack's block configuration is stored as `jsonb` on the block row and validated by
  the pack's own `dataSchema`. It is not a table and needs no migration.
- A pack may use a scoped key-value store (`provider_storage`), keyed by organisation,
  provider, tenant and key. The table is the platform's; the pack gets a namespace.
- A pack may **not** create tables, add columns, or reach the database directly. If a
  change needs schema, it is a platform change, not a pack change — including for
  first-party packs.
- Installing or upgrading a pack therefore requires **install, manifest entry, build,
  restart** — because a pack's client components are compiled into the bundle as literal
  imports, and a browser cannot resolve a module path read from a database.
- A pack declared on a running instance whose build did not include it is **rejected
  per-pack**: the platform boots normally, the health check passes, and that pack's
  blocks are absent. Name this failure explicitly — it is silent, and a reader who does
  not know to look for it will not find it.

### CONTENT-018 — Expand and contract

**Done when** the Upgrade section states the constraint and its origin:

- The site recommends two instances behind a proxy for zero-downtime restarts. That
  topology means **one database serving two code versions simultaneously**, for the
  duration of the rollover.
- Therefore every migration must be readable by the **previous** version. Additive
  first — add, backfill, write both — and drop the old shape in a later release.
- A destructive change is **two releases, never one**.
- The migration is applied before the restart, so **rolling back the artifact does not
  roll back the schema**. Say this in the same breath as the rollback instruction, not
  in a separate caution.

### CONTENT-019 — The content gap

**Done when** Known gaps carries a new numbered entry recording that a pack upgrade
which renames a field key does not rewrite stored block data — the editor shows the
field empty, `render` falls through to its default, and nothing reports it. Follow the
existing entry structure (**HOW TO FIX IT** / **DONE WHEN**), and state the workaround a
reader has today: check a pack's release notes for renamed keys before upgrading, and
plan the data rewrite as part of that upgrade.

## Story ordering

CONTENT-016 establishes the vocabulary and the diagram; CONTENT-017 and CONTENT-018 both
reference the streams it names, so it goes first. CONTENT-019 is independent and may run
in parallel.

## What is NOT in scope

- **Building any of it.** This phase documents the promotion path; it does not create
  CI, a staging environment, or a promotion script. Nothing here may imply forqsite ships
  tooling it does not ship.
- **Deciding the content-migration mechanism.** The gap is recorded, not closed. The
  decision is held in forqsite's own backlog and is the operator's to rule on.
- **Changing any fact established in Phase 6.** As in Phase 7: a factual change found
  here is a Phase 6 defect and gets recorded as one rather than fixed silently.

## Verification obligation

Every claim in CONTENT-017 and CONTENT-018 is a claim about forqsite's behaviour, not
about this site. Each must be checked against the forqsite repository at a named commit,
and the section's **verified on DATE against COMMIT** stamp refreshed per the Phase 6
convention. A claim that cannot be verified does not ship.

## Schema delivery

| Object | Management surface | Exception |
|---|---|---|
| _(none — static HTML, no database)_ | | |

---

### CP-8 Cold-eyes checklist

- [ ] no build-process vocabulary — does any published sentence use R0–R4, "ring", "story" or "phase" without defining it for a reader who has never seen this project?
- [ ] no self-narration — does any new passage describe what the page used to say?
- [ ] single-box honesty — does the section prescribe infrastructure a one-server self-hoster will not build?
- [ ] irreversibility named — is every irreversible step labelled as such at the point the reader would perform it?
- [ ] silent-failure named — is every failure mode that passes a health check called out explicitly?
- [ ] diagram grammar — are all diagram boxes states and all arrows operations, with no box holding a verb?
- [ ] public hygiene — does any shipped file name an internal path, host or address?
- [ ] verification stamp — does every new factual section carry a date and commit it was checked against?
