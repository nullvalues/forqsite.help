---
era: "001"
phase_class: production
---

# forqsite.help — Phase 5: SDK 5.0.0 and the generated-registry ingestion path

← [Phase 4: Containerize for edge deployment](phase-4.md)

## Goal

Bring the public docs site back in line with forqsite as it stands at tag
`cp-PM100-main`. The provider lifecycle page describes an installation procedure
that no longer exists — it instructs operators to hand-edit two source files that
are now generated and carry "do not edit by hand" headers — and the site says
nothing about the SDK delivery contract that now governs how third-party packs
are authored and handed back.

## Why now

Two things changed under the docs at once, and a partner pack is about to be
ingested against the corrected path:

1. **The registries are generated.** `server-provider-registry.ts` and
   `client-registry.ts` are produced from the provider manifest at prebuild
   (`pnpm generate:registries`, also run by `prebuild`). Both files open with
   `GENERATED FILE — do not edit by hand.` The docs still tell operators to edit
   them, and still carry a "VERIFIED" callout asserting the manual step *has not*
   been engineered out. That callout is now false, and it is the most load-bearing
   claim on the page.
2. **The SDK reached 5.0.0** with a stated delivery contract: artifacts, not
   repository access. The docs describe none of it.

## Scope note — this is a docs repo with a build artifact

`index.html` and `gap-handoff.html` are self-extracting bundles, not hand-written
pages. The editable content is a JSON-encoded template inside a
`<script type="__bundler/template">` element. Editing the rendered HTML directly
is not possible and editing the bundle by hand is not safe: the encoding escapes
every `/` as `/` so the template's own `</script>` cannot terminate the
element carrying it.

INFRA-003 therefore lands a small extract/inject tool **first**, with a
byte-identical round-trip proven on both files before any content story runs. A
content edit that cannot be re-injected losslessly is not a content edit, it is a
corrupted artifact.

## Public-repo constraint

This repo is public. The gap ledger currently prints an absolute path from the
original build machine (`file:/mnt/work/ud/…`) in two files. That is both a
disclosure and obsolete — the dependency it describes no longer exists. It goes
out with CONTENT-008 rather than being edited around.

Every story in this phase is checked against the same rule: no internal paths, no
internal hostnames, no infrastructure addresses. `admin.forqsite.test` and port
`6020` stay — they are forqsite's own documented dev defaults, not deployment
facts, and a self-hoster needs both.

## Stories

| ID | Title | Status |
|----|-------|--------|
| INFRA-003 | Bundle template extract/inject tool, with a proven byte-identical round-trip | complete |
| CONTENT-006 | Provider lifecycle: the registries are generated — correct the swap sequence and retire the false callout | complete |
| CONTENT-007 | Document the SDK delivery contract and what a pack author builds against at 5.0.0 | complete |
| CONTENT-008 | Prune GAP-002 and GAP-011 from both files; remove the build-machine path from the public repo | complete |
| CONTENT-009 | Day-two runbook: correct the condensed provider-pack steps to match | complete |
| INFRA-004 | Correct Phase 3's status row and record the re-bundle procedure in the README | complete |

## Story ordering

INFRA-003 gates every content story — nothing can be edited until the round-trip
is proven. CONTENT-006 and CONTENT-007 are the substance and may run in either
order. CONTENT-008 and CONTENT-009 are corrections that depend on 006 having
settled the vocabulary. INFRA-004 is independent.

## What is NOT in scope

- **The eight gap items that are still open.** GAP-003 through GAP-010 were
  re-checked against the source during spec recon and remain open: no systemd
  units ship, there is still no `Dockerfile`, `restore.sh` still names the legacy
  credential key, `backup.sh` still restores tracing with a bare `set -x`. Only
  GAP-002 and GAP-011 are resolved, and only those two are pruned. An unverified
  prune would be worse than a stale ledger, because a reader trusts a short list
  more than a long one.
- **Re-checking the whole site.** This phase corrects what the PM100-main work
  provably changed. A full drift re-sweep is Phase 3's job and Phase 3's story is
  already complete; INFRA-004 closes its record rather than reopening the work.
- **Deployment.** Publishing the updated bundle to the host that serves
  forqsite.help is an operator action after this phase, not a story in it.

## Schema delivery

| Object | Management surface | Exception |
|---|---|---|
| _(none — this repo persists no schema; it ships two static HTML files)_ | | |

---

### CP-5 Cold-eyes checklist — answered

- [x] **round-trip.** Both bundles verify byte-identical after every inject; a
      no-op extract/inject cycle was `cmp`-confirmed to change nothing.
- [x] **public hygiene.** No internal path, host or address in any shipped file.
      `/mnt/work` is gone from both bundles; the two remaining GAP-002/011
      mentions are deliberate "previously reported, now fixed" notes carrying no
      path.
- [x] **written-never-read (adapted).** No dangling cross-reference: the data
      arrays were executed, and every pipeline gap flag resolves to a ledger row.
      Three `#gap-002` anchors that would have dangled are repointed.
- [x] **duplicate state.** The install sequence now exists in three places — this
      site's lifecycle page, its day-two runbook, and the platform's own install
      page. They are stated to agree, and the site says the platform is
      authoritative if they ever diverge.
- [x] **half-implementation.** No partial edits: every stale instruction to
      hand-edit a registry is gone from both the long and condensed paths.

### CP-5 result

**Phase complete.** Six stories, all complete. Not verified: a live browser render
— the Chrome extension was unavailable in this session. Validation was static and
thorough (HTML tag balance, embedded-JS syntax, executed data arrays,
byte-identical round-trip), but the pages have not been *seen*. Load both before
publishing.

<!-- original checklist -->
- [ ] written-never-read — does anything this phase persists have no reader?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] half-implementation — is any branch unreachable, or any producer without its consumer?
- [ ] round-trip — does every edited bundle still extract, re-inject and render?
- [ ] public hygiene — does any shipped file name an internal path, host or address?
