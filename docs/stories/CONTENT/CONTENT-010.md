---
id: CONTENT-010
rail: CONTENT
title: "Env reference: add the four missing keys and the required-but-undeclared proxy header"
status: complete
phase: "6"
story_class: content
execution: orchestrator
primary_files:
  - index.html
touches: []
---

## Background

Diffing the site's env table against `src/lib/config.ts` found 39 declared keys
against 44 on the site: four declared keys missing, and nine on the site with no
registry entry.

## The nine were all correct

Checked individually rather than pruned. Every one is read from scripts, the
seed, or `process.env` directly — `DATABASE_URL` in 20 places, the
`PLATFORM_ADMIN_*` trio in `seed-platform.ts`, `BACKUP_*` in `backup.sh`.
Removing them would have deleted true content, which is the same trap
CONTENT-008 avoided on the gap ledger. "Absent from the registry" is not
"wrong".

## The fifth key is the one that matters

Four missing keys are ordinary omissions: `TRUST_PROXY_CLIENT_IP`,
`TRUST_PROXY_FORWARDED_HOST`, `IMPORT_WORK_DIR`,
`CONTENT_IMPORT_MAX_UPLOAD_BYTES`.

`TRUST_PROXY_CLIENT_IP_HEADER` is different. It is **deliberately excluded from
the config registry** (Story SEC-045), has no default, and the platform throws at
startup unless it is `x-forwarded-for` or `x-real-ip` — with no fallback between
them. `TRUST_PROXY_CLIENT_IP` defaults to `true`, so **the default configuration
requires it**. Any deployment behind a proxy fails to start without it.

Because it is excluded from the registry, it appears in no generated key list —
so a `.env.example` diff will not surface it either. It gets a `req*` row of its
own and a READ FIRST callout on the production install page, above the install
sequence, where someone hits it.

## Corrected mid-build

An earlier draft of the phase spec said a self-hoster "has nothing to search
for". That overstated it: forqsite's own `docs/configuration.md` documents this
key (8 references) and the other three. The gap was **this site's alone**. The
spec now says so.
