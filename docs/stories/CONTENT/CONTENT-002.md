---
id: CONTENT-002
rail: CONTENT
title: Embellishments: add repo-grounded detail missing from the docs (E1-E8)
status: draft
phase: "2"
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
touches:  # If this story changes any documented architecture, add docs/architecture.md to this list.
---

## Requires

- CONTENT-001 complete or in progress against the same working tree (avoids two stories
  editing the same bundle script tag out of order).
- Same bundle-format handling as CONTENT-001 — see that story's Requires section for the
  unpack/edit/repack procedure.
- `/mnt/work/forqsite` available as ground truth for every addition below; re-verify
  cited paths before writing, don't invent detail not backed by the source.

## Ensures

- Architecture page's "What the scheduler owns" section is a table (not prose) covering
  the ten jobs in `scripts/scheduler.ts`: `aaac-thresholds` (*/15min), `domain-reverify`
  (daily 03:00), `notifications-drain` (*/5min), `billing-tokens-daily` (01:00),
  `billing-storage-daily` (02:00), `signup-codes-purge` (6h), `publish-scheduled`
  (hourly), `rate-limit-cleanup` (daily 03:00), `org-reaper` (daily 04:00, the
  `FORQSITE_ORG_RETENTION_DAYS` sweep), `fsrs-consolidation` (daily 05:00) — and notes
  each takes a `scheduler_locks` lease so replicas are safe, and that if the scheduler is
  down, scheduled publishing and notification emails never fire.
- Operations→Incidents table and the production-install step-3 expected output both
  mention `/api/health`'s `subsystem` field (`"db"|"minio"`, 1.5s MinIO timeout) as the
  first diagnostic for an unhealthy app.
- Process supervision page notes the dotenv caveat: the proposed systemd unit's
  `ExecStart=/usr/bin/pnpm start` relies on `package.json`'s `start`/`prestart` scripts
  running `dotenv -e .env.local`, so if `.env.local` is removed after moving secrets to
  `/etc/forqsite/env`, the unit may fail to start unless an empty `.env.local` is kept or
  the ExecStart bypasses the pnpm wrapper. Same caveat folded into GAP-003's proposed
  approach in gap-handoff.html.
- Env table gains rows for: `SMTP_PORT` (opt, default 587), `SMTP_USER` (opt),
  `SMTP_PASS` (opt), `SMTP_FROM` (opt, default `noreply@forqsite.com`),
  `ADMIN_NOTIFY_EMAIL` (opt — notifications-drain sends form-submission alerts here;
  unset means notifications are silently marked seen), `SIGNUP_RATE_LIMIT_BYPASS` (opt,
  default false), `HANDLE_RATE_LIMIT` (opt, default 60), `ANTHROPIC_API_KEY`
  (script-only, required by `pnpm calibrate-thresholds --live`). The optional
  `TEST_ADMIN_*`/`TEST_ORGADMIN_*` Dev/E2E group is a judgment call for the builder —
  include it only if it doesn't make the env table unwieldy.
- Dev setup step 2 notes which `.env.local.example` values arrive pre-filled for dev
  (`DATABASE_URL` pointing at a local Postgres, MinIO `minioadmin`/`minioadmin`,
  `PLATFORM_ADMIN_EMAIL=dev@forqsite.test` / `devpassword123`), and that the dev admin
  credentials are consumed by `db:seed-platform` via `PLATFORM_ADMIN_*`.
- Restore procedure includes a line that restores should target a freshly created empty
  database (`createdb forqsite`), not one with existing data, since `restore.sh` does not
  drop/recreate.
- Dev setup step 3 notes that `firstrun.sh`'s printed next-steps mention
  `pnpm db:bootstrap` but this site's flow uses `db:seed-platform` (cross-reference: this
  divergence is also folded into GAP-010 by CONTENT-001).
- Incident table has a row for "emails not sending" pointing at: `SMTP_HOST`/`SMTP_USER`/
  `SMTP_PASS` all set, scheduler running (notifications-drain), and `ADMIN_NOTIFY_EMAIL`
  for operator alerts.

## Instructions

Do not touch GAP items or existing consistency corrections — that's CONTENT-001's
scope. If CONTENT-001 hasn't landed yet, coordinate rather than duplicating the
GAP-001-prune or PLATFORM_HOSTNAMES fixes.

## Tests

- JSON round-trip check on `index.html` after editing.
- Grep confirms the new env-table rows and scheduler job table are present in the
  decoded template content.
