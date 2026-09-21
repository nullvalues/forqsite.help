---
era: "001"
phase_class: production
status: complete
---

# forqsite.help — Phase 4: Containerize for edge deployment

← [Phase 3: Drift re-sweep vs forqsite source](phase-3.md)

<!-- Phase doc = planning surface only. Story-level detail (acceptance criteria,
     file paths, implementation guidance, test instructions, codebase recon)
     belongs in docs/stories/<RAIL>/<ID>.md — not here. -->
## Goal

caddy's `sites/forqsite-help.caddy` has always reverse-proxied to
`forqsite-help:6000` (assigned in `docs/port-registry.md` under caddy's
own repo, per story FORQSITEHELP-001 / phase-EH002-main), on the explicit
architectural decision that this project's simpler `file_server`
suggestion be rejected in favor of the "one container per app, edge Caddy
only ever does `reverse_proxy`" uniformity rule that every other sibling
app follows (see caddy's `docs/ideology.md`). No container has ever
actually existed to back that port — this phase builds it, so that
caddy's already-correct config has something real to route to.

Constraint: this project's stated architecture is "no build step" for the
site content itself (`index.html` / `gap-handoff.html` remain generated,
self-unpacking bundles, edited via the documented bundler procedure, not
touched by this phase). Containerizing means wrapping the existing static
files in a minimal, off-the-shelf static file server — not introducing a
build pipeline, framework, or hand-maintained server code.

## Stories

| ID | Title | Status |
|----|-------|--------|
| INFRA-002 | Containerize forqsite.help behind nginx on port 6000, joined to the `edge` network | complete |

### INFRA-002 acceptance criteria

- New `docker-compose.yml` at repo root: single service, `container_name:
  forqsite-help`, image `nginx:alpine` (official image, no custom build),
  joined to the external `edge` Docker network (matches caddy's
  `docker-compose.yml` network convention), no published host ports (per
  caddy's `services/README.md` — "sibling services never publish host
  ports").
- `nginx.conf` (or equivalent) bind-mounted read-only, listening on port
  `6000` internally (matching the port already reserved for
  forqsite.help in caddy's `docs/port-registry.md`), serving `index.html`
  at `/` and `gap-handoff.html` at `/gap-handoff.html` — both bind-mounted
  read-only from the repo's existing files, not copied into an image.
- No `Dockerfile` — bind-mount only, preserving the "no build step"
  constraint.
- `docker compose config` validates cleanly.
- Deployed to the Docker host that runs the edge proxy (same host as caddy,
  required for Docker DNS resolution on the shared `edge` network) at a per-site
  directory under that host's service root, mirroring the proxy's own deploy convention.
- Post-deploy verification: `docker compose up -d` brings the container
  up healthy; from the deployment host, `curl --resolve forqsite.help:443:127.0.0.1
  https://forqsite.help/` (proxied through the already-running caddy
  container) returns `200`, not `502`.
- `docs/architecture.md` updated to describe the new `docker-compose.yml`
  / `nginx.conf` and drop any remaining "no server" framing that no
  longer matches reality (the static *content* still has no build step;
  the *deployment* now has a server).

**Risks / mitigations:**

- Risk: this reopens a settled cross-repo decision (FORQSITEHELP-001)
  from the wrong side — if forqsite.help's own docs still say "no
  server," a future reader lands on a contradiction. Mitigation:
  acceptance criteria explicitly requires updating this repo's own
  architecture doc, not just standing up the container.
- Risk: deploying to a per-site directory on the Docker host that runs
  the edge proxy is a shared production host also running caddy — a bad
  `docker compose up` there is blast-radius-adjacent to the live proxy
  (though on a different container, `edge` network only, no port conflict
  since nothing is host-published). Mitigation: `docker compose config`
  validated before `up`; verified via the already-proven `curl --resolve`
  pattern used in caddy's own EH006-main phase, not by touching caddy's
  container at all.

## Deferred stories

None.

## Build record

Built and deployed 2026-08-10. `docker-compose.yml` + `nginx.conf` added
locally, validated with `docker compose config`. Deployed to the Docker
host that runs the edge proxy at a per-site directory under that host's service root
(sudo-gated `mkdir`/`chown` run by the operator, rest by the agent): rsync of
the 4 runtime files only (verified via `-n` dry-run first), `docker compose up -d`
from the deployment host.

Verification:
- `docker ps` from the deployment host: `forqsite-help` container `Up`.
- End-to-end through the already-running caddy container:
  `curl --resolve forqsite.help:443:127.0.0.1 https://forqsite.help/` ->
  `200`, byte-identical to the source `index.html` (427642 bytes both
  sides). `/gap-handoff.html` -> `200`.
- `docs/architecture.md` and `CLAUDE.md` updated to drop the stale
  "no server" framing and describe the nginx deployment; content
  authoring's no-build-step property is preserved and called out
  explicitly as distinct from the deployment's own no-build-step
  property (bind-mount only, no Dockerfile).

Acceptance criteria for INFRA-002 met.
