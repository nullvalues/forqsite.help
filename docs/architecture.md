# forqsite.help — Architecture

## What forqsite.help is

Two static HTML bundles — `index.html` (the main docs site) and `gap-handoff.html`
(the gap/handoff tracker) — plus `README.md`. Content authoring has no build step (the
bundles are hand/session-generated, not compiled); the files can still be opened
directly (`file://`) for local editing/preview. The deployed artifact, however, runs
behind a minimal `nginx:alpine` container (see Deployment below) — per FORQSITEHELP-001
in the sibling `caddy` repo, edge Caddy only ever does `reverse_proxy`, never a direct
file-system mount into the shared ingress container, so this project containerizes
rather than relying on Caddy's `file_server`. No database, regardless.

This document is the source of truth for the forqsite.help codebase. Read it before any task.

---

## Stack

static HTML content (no build step for the content itself); deployed behind
`nginx:alpine` (bind-mounted static files + config, no Dockerfile, no build step for
the deployment either); no database

---

## Domain model



---

## Module structure

```
forqsite.help/
├── index.html          # main docs site (self-unpacking bundle)
├── gap-handoff.html    # gap/handoff tracker (self-unpacking bundle)
├── docker-compose.yml  # nginx:alpine container, bind-mounts the two files above
├── nginx.conf          # listens on :6000 (matches caddy's port-registry.md assignment)
└── README.md
```

## Deployment

INFRA-002 (phase 4) containerized this project: `docker-compose.yml` runs
`nginx:alpine` as container `forqsite-help`, joined to the external `edge` Docker
network, with `nginx.conf`, `index.html`, and `gap-handoff.html` bind-mounted
read-only — no Dockerfile, no image build. No host ports are published; the sibling
`caddy` repo's `sites/forqsite-help.caddy` reverse-proxies `forqsite.help` ->
`forqsite-help:6000` over that shared network. Deployed alongside caddy on kw-pub61 at
`/srv/forqsite-help`, mirroring caddy's own `/srv/edge` convention — required since
Docker's embedded DNS resolution for the `edge` network only works within a single
Docker host.

Both HTML files are self-unpacking bundles: a `<script type="__bundler/template">`
tag contains a JSON-encoded HTML string. The unpacked HTML embeds a `DCLogic` class
holding app state, `nav()`/hash-routing logic, and render helpers (`scrollToAnchor`,
`copyCmd`, etc.).

**Editing procedure** (see `docs/stories/CONTENT/CONTENT-001.md`'s Requires section
for the original worked example): extract the `__bundler/template` JSON string, edit
the unpacked HTML/JS as plain markup/`DCLogic` script, `node --check` any edited
script, re-encode with `JSON.stringify` (mind `/` escaping), splice the result back
into the script tag. Verify with a JSON round-trip on the re-encoded payload and,
where the change is interactive/CSS behavior, a headless-browser render
(e.g. Chromium `--dump-dom`) — a text diff alone can't confirm runtime behavior like
scroll reset or hash routing.

---

## Layer rules

| Layer | May import from | May not import from |
|-------|----------------|---------------------|


---

## Build commands

```bash
# Build / test
none — static HTML, open file:// or serve with any static file server

# Run all tests
none — static HTML, open file:// or serve with any static file server
```

---

## Protected files

These files are working and must not be modified without a stated reason:

`index.html` and `gap-handoff.html` are generated-artifact bundles per
`docs/ideology.md`'s Generated-artifact discipline constraint — they are not
hand-edited outside the pairmode build loop (builder/reviewer subagents per story).
See that doc for the Phase 2 exception note covering loop-mediated, spec-cited,
reviewed edits.

---

## Non-negotiables


_(No non-negotiables defined yet — add them here as the project matures.)_

