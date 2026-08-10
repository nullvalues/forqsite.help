---
id: INFRA-002
rail: INFRA
title: Containerize forqsite.help behind nginx on port 6000, joined to the edge network
status: complete
phase: "4"
auth_gated: false
schema_introduces: false
primary_files:
  - docker-compose.yml
  - nginx.conf
  - docs/architecture.md
touches: []
---

## Requires

- caddy's `sites/forqsite-help.caddy` (reverse_proxy forqsite-help:6000)
  already correct and unmodified by this story — see FORQSITEHELP-001 /
  phase-EH002-main in the caddy repo. This story only builds the missing
  backend side.
- caddy's edge stack already deployed and running on kw-pub61
  (phase-EH006-main, complete) — this story's container joins the
  existing external `edge` Docker network created there; it does not
  create that network itself.

## Ensures

- `docker-compose.yml` (repo root): single service `forqsite-help`,
  `container_name: forqsite-help`, image `nginx:alpine`, `restart:
  unless-stopped`, joined to external network `edge`, no `ports:`
  mapping (no host-published ports, per caddy's `services/README.md`
  convention that sibling services never publish host ports).
- `nginx.conf`: minimal server block, `listen 6000;`, `root
  /usr/share/nginx/html;`, `index index.html;`. Bind-mounted read-only
  to `/etc/nginx/conf.d/default.conf`, overriding the image's default
  (which listens on 80).
- `index.html` and `gap-handoff.html` bind-mounted read-only into
  `/usr/share/nginx/html/` — served as-is, not copied into an image, not
  modified by this story.
- No `Dockerfile`. No build step introduced for the site content itself
  — the "generated, self-unpacking bundle" editing procedure in
  `docs/architecture.md` is unaffected by this story.
- `docs/architecture.md`'s "no server" framing is corrected: content
  authoring remains build-step-free (unchanged), but the deployed
  artifact now runs behind nginx per FORQSITEHELP-001's uniformity
  requirement. State both facts precisely — don't overcorrect into
  implying the docs themselves now require a build step.

## Instructions

Deploy (after the story's `docker-compose.yml`/`nginx.conf` are
committed) to kw-pub61 at `/srv/forqsite-help`, mirroring caddy's own
`/srv/edge` convention: rsync `docker-compose.yml`, `nginx.conf`,
`index.html`, `gap-handoff.html` only — not the full repo (no `.git`,
`docs/`, `.claude/`, `.companion/`). `docker compose config` validated
before `docker compose up -d`.

## Tests

- `docker compose config` passes locally and on kw-pub61.
- On kw-pub61: `docker ps` shows `forqsite-help` container `Up`.
- On kw-pub61: `curl --resolve forqsite.help:443:127.0.0.1
  https://forqsite.help/` (through the existing caddy container) returns
  `200` with the real page content, not `502`.
- `curl .../gap-handoff.html` via the same pattern also returns `200`.
