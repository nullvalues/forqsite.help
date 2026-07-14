---
id: CONTENT-001
rail: CONTENT
title: Consistency fixes: correct index.html/gap-handoff.html drift vs forqsite source (C1-C13)
status: complete
phase: "2"
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
  - gap-handoff.html
touches:
  - README.md  # DOC CURRENCY: GAP-001..011 reference must match the corrected 10-item count
  - docs/ideology.md  # DOC CURRENCY: same GAP-001..011 reference in Prototype fingerprints
  - docs/reconstruction.md  # DOC CURRENCY: same GAP-001..011 reference
---

## Requires

- `/mnt/work/forqsite` checked out at the version referenced (used as ground truth for
  every claim below — re-verify each cited path/line still says what's quoted here
  before changing the docs, since forqsite may have moved on since this story was
  written).
- Familiarity with the bundle format: both HTML files are self-unpacking bundles. Page
  markup lives inside `<script type="__bundler/template">` as a JSON-encoded HTML
  string; app state/data (env rows, gap item objects) lives in a `DCLogic` class
  embedded inside that unpacked template. To edit: extract the JSON string, `JSON.parse`
  it, edit the unpacked HTML (or the DCLogic class within it), `JSON.stringify` it back
  (escape every `/` as the unicode escape for a forward slash, matching the existing
  bundle convention — a literal unescaped forward slash inside embedded
  `<script src=...></script>` markup will prematurely close the outer bundle tag), and
  splice it back into the same script tag. Do this once per file: dump
  to a scratch file, apply every edit there, repack once. Verify via a JSON round-trip
  and (if available) a headless-browser render before finishing.

## Ensures

- `gap-handoff.html` no longer contains a GAP-001 item; header counts ("stories",
  priority tallies) and the "suggested sequencing" text are updated to match (10 items,
  starting at GAP-002).
- `index.html`'s Dev environment BLOCKED banner, the Dev→Prod pipeline Stage 01 flag,
  and the gap ledger no longer reference GAP-001.
- GAP-002's proposed approach documents the caveat that `ud`/`ud-shop` provider packs
  are referenced by a live migrated org (`src/db/migrations/0088_migrateone_enable_ud_providers.sql`)
  and `config/providers.json`, so dropping them from `package.json` breaks `pnpm build`
  for this install.
- `index.html`'s env-table rows for `PLATFORM_HOSTNAMES` and `SIGNUP_HOSTNAME`, the
  daily-runbook REMEMBER callout, and the dev-troubleshooting fix text no longer claim a
  rebuild is required — corrected to "read at process start; restart to change" (per
  `src/lib/config.ts`'s lazy getter and `src/middleware.ts`'s per-request read).
- GAP-004 no longer claims `Caddyfile.example` is missing (it is committed at
  `docs/deployment/Caddyfile.example`); it instead documents the real remaining gaps:
  the existing file targets port 3000 and hardcoded forqsite.ai/forqsite.com hostnames,
  both compose files declare `build: .` with no Dockerfile, and the root
  `docker-compose.yml`'s new `db` service lacks pgvector with no MinIO service.
- GAP-005 cites `docs/deployment/Caddyfile.example` and `scripts/rolling-restart.sh:24`
  as additional evidence of the port 3000 vs 6020 drift.
- GAP-010 no longer implies signing docs are entirely absent (configuration.md documents
  `FORQSITE_MANIFEST_SIGNING_MAX_AGE_DAYS` / `FORQSITE_REVOKED_SIGNATURES`) and its sweep
  list includes the `firstrun.sh` step 8 (`pnpm db:bootstrap`) vs. this site's documented
  `pnpm db:seed-platform` divergence.
- Env table: `DEFAULT_ORG_FEATURES` default corrected to
  `ADAPTIVE_CONTENT,ADDITIONAL_TENANTS`.
- Env table: `SMTP_HOST` note corrected to reflect that email is enabled only when
  `SMTP_HOST`, `SMTP_USER`, and `SMTP_PASS` are all set, and names the three features
  this gates (signup verification, form notifications, password-reset).
- Daily runbook E2E snippet reflects the correct order: `test:fixture-seed` (once) →
  `test:fixture-init` (once) → `pnpm e2e`.
- Provider-lifecycle rolling-restart step matches the actual script order (A restarts
  first, then B) or is reworded to avoid asserting an order at all.
- Migration 0057 wording reflects `CREATE EXTENSION IF NOT EXISTS vector` (a no-op if a
  superuser already created it, not a hard failure in that case).
- GAP-006, 007, 008, 009, 011 are left unchanged (verified accurate as of this story's
  writing) unless the builder's own re-verification against current forqsite source
  finds otherwise.
- Both HTML files still parse (JSON round-trip) and render after editing.

## Instructions

Full evidence trail and exact before/after wording for every item above is preserved in
the git history of this conversation's session — if unavailable, re-derive each claim
directly from `/mnt/work/forqsite` (paths cited above) rather than guessing. Do not
change anything not covered by the Ensures list above; scope creep into embellishments,
UX, or prose belongs in CONTENT-002/003/004.

## Tests

- `node -e` JSON round-trip check on both files after editing (parse succeeds, no
  truncation).
- Grep confirms `GAP-001` is absent from `gap-handoff.html` and `index.html`.
- Grep confirms `BAKED AT BUILD TIME` is absent from `index.html`.
- If a headless browser is available, render both files and confirm no console errors
  and that visible text matches the corrected claims above.
