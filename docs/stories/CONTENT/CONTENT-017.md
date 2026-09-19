---
id: CONTENT-017
rail: CONTENT
title: Rewrite Provider packs (condensed) to state the ceiling on what a pack may store and why installing one needs a rebuild
status: draft
phase: "8"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
touches: []
narrative_roles: []
---

## Context

"Provider packs (condensed)" on the Day-two runbook page is a wiring recipe: install,
manifest entry, build, restart, licence, enable. It says every step and no reason, so
a reader cannot answer the two questions that decide whether a pack is safe to take:
what may a pack keep in the database, and why can a running instance not just pick one
up. Both answers are already true of forqsite; neither is written down here. This story
rewrites that section to state the ceiling and the rebuild reason, and to place a pack
change inside the three streams the Promoting a change page (`#promote`) already names —
referencing that vocabulary, never redefining it.

## Requires

- The bundle-edit path: `scripts/bundle-template.py extract|inject|verify`. Extract once
  to a scratch file, edit only there, inject once, verify. Do not hand-edit the encoded
  `__bundler/template` payload inside `index.html`.
- CONTENT-016 complete: the `promote` page exists and defines the **artifact**, **schema**
  and **content** streams. This section uses those three words in that sense and does not
  restate their definitions.
- `/mnt/work/forqsite` checked out at `7089b9dc` (branch `main`), clean. Every claim below
  was verified there; the citations in `## Instructions` are the evidence a reviewer
  re-checks, at that commit.

## Ensures

The "Provider packs (condensed)" section of the Operations page states, as verified fact:
that a pack's block configuration is `jsonb` on the block row validated by the pack's own
`dataSchema` and needs no migration; that `provider_storage` is a platform-owned key-value
table the pack gets a namespace in, keyed `(organisation_id, provider_id, tenant_id, key)`,
with the third-party `aaac.generate` mis-attribution named; that a pack may not create
tables, add columns or reach the database directly, and that a change needing schema is a
platform change including for first-party packs; that install → manifest entry → build →
restart is required because pack components are compiled in as literal `import()`
specifiers and a browser cannot resolve a module path read from a database; and that a
declared pack the build did not compile is rejected per-pack — the platform serves, the
health check returns 200, that pack's blocks are simply absent, and the only signal is a
line in the process log. The section ends with its own stamp reading `verified 2026-09-18
against nullvalues/forqsite@7089b9dc`.

Forbidden proxies, each of which would satisfy a careless read of the above and must not
appear:

- Saying a pack "should not" or "is discouraged from" touching the database. The rule is a
  stated boundary in forqsite's provider contract, not advice; state it as the ceiling.
  (Forbidden proxy: hedged phrasing that leaves the reader thinking it is a style choice.)
- Claiming the platform *prevents* a pack from reaching the database. It does not — packs
  run in-process with full data access, as this same section already says. The verified
  claim is that the contract forbids it and the handle offers no route to it.
- Describing the rebuild as "recommended", "to pick up changes", or a cache refresh.
  (Forbidden proxy: any wording that implies a restart alone could suffice.)
- Naming the per-pack rejection as an error the operator will see. It reaches
  `console.error` and nothing else: the platform-admin block-providers page surfaces
  namespace and predicate rejections only. (Forbidden proxy: "the admin UI will tell you".)
- Re-defining artifact / schema / content, or introducing a fourth stream. This section
  names them and links to `#promote`.
- Editing the global sidebar stamp (`repo: nullvalues/forqsite@17b78645` /
  `verified: 2026-09-16`) instead of adding a section stamp.
- Changing any Phase 6 fact already on the page (the five install steps, `TRUSTED_PUBLISHERS`,
  `REQUIRE_PACK_SIGNATURES`, `FORQSITE_REVOKED_SIGNATURES`, in-process execution). A factual
  error found in them is recorded as a Phase 6 defect, not fixed here.

## Instructions

1. `python3 scripts/bundle-template.py extract index.html /tmp/tpl.html`. Edit `/tmp/tpl.html`
   only. The target is the `<h2>Provider packs (condensed)</h2>` block inside the `pOps`
   page — keep the existing five numbered install steps and the in-process/signing paragraph
   intact, and build the new material around them, matching that page's inline-style
   conventions.

2. **Cross-link.** Add `goPromote: this.nav('promote')` beside `goProviders` in `renderVals()`
   (it does not exist yet) and use it for a single link into Promoting a change. Say once
   that a pack change is an **artifact**-stream change — reversible by rebuilding from the
   previous pin — and that a pack is not permitted to put anything in the **schema** stream.

3. **What a pack may store — the two places, and nothing else.** Write both, as fact:
   - **Block configuration**: a `jsonb` column on the block row, validated on every save
     against the block type's own `dataSchema` and stripped of keys the schema does not
     declare; a failed parse rejects the whole save, not the offending block. No table, no
     migration. Evidence: `src/db/schema/content.ts:99-112`;
     `src/services/block-registry/index.ts:329-370` (`dataSchema.parse` at :357, whole-save
     `invalid_data` at :366); call sites `src/app/actions/blocks.ts:80`,
     `src/app/actions/org-blocks.ts:90`.
   - **A scoped key-value store**: the platform's `provider_storage` table, primary key
     `(organisation_id, provider_id, tenant_id, key)`, value `jsonb`, 64 KB per value. The
     pack does not choose its namespace — the platform passes the provider id when it builds
     the handle. Evidence: `src/db/schema/provider-storage.ts:8-25`;
     `src/services/provider-storage.ts:14` (64 KB cap), `:23-25` (org-scoped rows use an
     empty-string tenant sentinel); `src/services/block-registry/handle.ts:133-153`.
   Name the one place that namespace does not hold: storage and log calls made from a
   third-party pack's `aaac.generate` are attributed to the platform's built-in `core`
   provider, so they land in the wrong namespace. It is silent. Evidence:
   `src/services/adaptive/triggers.ts:222` (`providerId: 'core'`, hardcoded), disclosed at
   `docs/block-provider-spec.md:425-428`.

4. **The ceiling.** A pack may not create tables, add columns, or reach the database
   directly: forqsite's provider contract states "No direct database access… Providers are
   pure compute over the data and handle they are given"
   (`docs/block-provider-spec.md:286-287`), and the handle it is given exposes only
   `storage`, `ai`, `signals`, `media`, `log`, `getTheme` and content reads
   (`src/block-provider-sdk/index.ts:127-176`) — no database route. Say plainly that if a
   change needs schema it is a platform change, including for a first-party pack: every
   table lives in the platform's numbered migrations applied by `pnpm db:migrate`, including
   the pack-facing `provider_storage` itself
   (`src/db/migrations/0030_14_6_provider_storage.sql`), and no pack directory ships SQL.
   Pair this with the existing in-process sentence rather than contradicting it: the contract
   forbids it and nothing on the handle offers it — the runtime does not enforce it.

5. **Why a rebuild.** Give the reason, not just the step: a pack's client components are
   compiled into the bundle as literal `import('<path>')` specifiers generated from the
   manifest at prebuild, because a module path read from a database cannot be resolved by a
   browser — no `node_modules`, no filesystem. Evidence:
   `scripts/generate-client-registry.ts:26-31` and `:112-120`; `package.json:10` (`prebuild`);
   `next.config.mjs:56` (`transpilePackages` derived from the manifest). The restart is
   separate and also required: the loaded provider list is memoised for the life of the
   process (`src/services/block-registry/loader.ts:285-286`), so a manifest edit alone changes
   nothing in a running instance.

6. **The silent failure.** State it as its own short passage, not a footnote. A pack whose
   declared client component is not in the generated registry — the build did not include it
   — is rejected **on its own**: every other provider keeps serving, that pack's block types
   are absent from the editor and from render, and the only signal is one `console.error`
   line naming the pack. `/api/health` still returns 200: it checks the database and object
   storage only, and never consults the provider registry. The platform-admin block-providers
   page does not show this class of rejection — it surfaces namespace and predicate
   rejections only. Tell the reader where to look: the process log
   (`journalctl -u forqsite`), grepping for `[block-registry]`. Evidence:
   `src/services/block-registry/loader.ts:530-547` (per-pack reject then `continue`),
   `:549-565`, `:503-528`; `src/app/api/health/route.ts:21-47`;
   `src/app/platform-admin/block-providers/page.tsx:14,35`;
   `getLastClientRegistryRejections` has no production consumer
   (`src/services/block-registry/loader.ts:185`, referenced only by tests).
   Also state the harder neighbouring case, because it is not per-pack and a reader must not
   expect graceful degradation from it: a manifest entry naming a module the build never
   registered aborts the provider load entirely, with an error naming the module and telling
   the operator to run `pnpm generate:registries`. Evidence:
   `src/services/block-registry/loader.ts:341-347`, pinned by
   `tests/services/block-registry/loader.test.ts:468-470`.

7. **Stamp.** End the section with its own stamp line in the mono/muted style the promote
   page uses: `verified 2026-09-18 against nullvalues/forqsite@7089b9dc`. Leave the global
   sidebar stamp untouched.

8. Do not narrate the change — no sentence describing what this section used to say or omit.
   Name no internal host or path beyond what the site already publishes.

9. `python3 scripts/bundle-template.py inject index.html /tmp/tpl.html`, then verify.

*Ideology note:* step 1's extract/inject path is written in to preserve the
Generated-artifact discipline constraint under its Phase 2 loop-mediated exception; the
section adds text only, so the Zero-runtime-dependencies constraint is untouched.

*Scope note:* `scripts/bundle-template.py` is read, not modified; the forqsite paths cited
above are evidence in a sibling repository and are deliberately absent from `touches:`.
`index.html` is the only file this story writes. Spec-preflight's warnings on `/api/health`,
`TRUSTED_PUBLISHERS`, `REQUIRE_PACK_SIGNATURES` and `FORQSITE_REVOKED_SIGNATURES` are
expected and left standing: all four are defined in `nullvalues/forqsite`, not in this
static-site tree, which has no source for the scan to find them in.

*Verification note:* the phase doc's fifth "Done when" bullet is verified for the case it
describes — a pack the build did not compile in. The adjacent case (a manifest module absent
from the generated server registry) is **not** per-pack and step 6 requires it to be stated
as the different failure it is, rather than folded into the per-pack claim.

*Proportionality note:* longer than a one-file `doc` story normally warrants because every
sentence it instructs is a claim about a second repository and carries its own citation.

## Tests

```bash
cd /mnt/work/forqsite.help
python3 scripts/bundle-template.py verify index.html
python3 scripts/bundle-template.py extract index.html /tmp/check.html
node --check <(sed -n '/type="text\/x-dc"/,/<\/script>/p' /tmp/check.html | sed '1d;$d')
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 \
  --dump-dom 'file:///mnt/work/forqsite.help/index.html#ops' > /tmp/ops.dom
grep -c 'provider_storage' /tmp/ops.dom
grep -c 'dataSchema' /tmp/ops.dom
grep -ci 'health check' /tmp/ops.dom
grep -c 'nullvalues/forqsite@7089b9dc' /tmp/ops.dom
grep -Eic 'R[0-4]\b|\bring\b' /tmp/ops.dom
grep -Eo '<(img|use|link|script)[^>]*(src|href)="(https?:|//)[^"]*"' /tmp/ops.dom | wc -l
```

Acceptance: `verify` reports byte-identical; `node --check` exits 0; the rendered `#ops`
DOM contains `provider_storage`, `dataSchema`, the health-check sentence and the stamp; the
build-process-vocabulary grep returns 0; no external `src`/`href` is introduced. Also open
`file:///mnt/work/forqsite.help/index.html#ops` and confirm the link into Promoting a change
navigates and the page's existing install steps still render.

## Out of scope

- The Upgrade section's expand-and-contract rule (CONTENT-018) and the Known gaps entry for
  the content stream (CONTENT-019) — including the field-key-rename failure, which belongs to
  CONTENT-019 and must not be pre-empted here beyond naming the content stream.
- The Provider lifecycle page. This story rewrites the condensed section on the Operations
  page only; the existing link to Provider lifecycle stays as it is.
- The signing and revocation material (`TRUSTED_PUBLISHERS`, `REQUIRE_PACK_SIGNATURES`,
  `FORQSITE_REVOKED_SIGNATURES`) and the five install steps — carried over unchanged.
- Proposing any fix to the `aaac.generate` namespace mis-attribution. This site records the
  behaviour; the fix is forqsite's.
- `gap-handoff.html` and the global sidebar stamp.
