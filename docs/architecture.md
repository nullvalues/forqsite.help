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

## Era and phase currency

Current era: `001` — `docs/eras/001-initial.md`
Current phase: 10 — Name the class, not the instance — and close the backlog by resolving, never deleting

`docs/phases/index.md` is the source of truth for phase status. The two lines above
and below are pointers into that record, not a second copy of it.

**The `Current era:` line above is a hand-maintained anchor, and the `Current phase:`
line below it is machine-owned.** `flex_build.py`'s checkpoint-tag step rewrites the
`Current phase:` line in place on every tag, keyed off that anchor. Do not reformat
either line or the pointer silently stops updating: this section previously carried
the phase in prose, the anchor did not match, `record-checkpoint-step` emitted
`warning: docs/architecture.md has no 'Current era:' anchor line — skipping phase
pointer stamp`, and the pointer went stale the moment cp-8 was tagged.

This repo's build-harness wiring was audited against convention in Phase 9. The audit
itself is not kept here — its subject is the build harness rather than forqsite — and
was removed in Phase 10 (CONTENT-025). The one outcome that is about this repository:
`.claude/agents/gate-worker.md` was removed as a dark feature — the dispatch that would
reach it was retired upstream — and must not be restored by a future scaffold sync.

---

## Module structure

```
forqsite.help/
├── index.html          # main docs site (self-unpacking bundle)
├── gap-handoff.html    # gap/handoff tracker (self-unpacking bundle)
├── docker-compose.yml  # nginx:alpine container, bind-mounts the two files above
├── nginx.conf          # listens on :6000 (matches caddy's port-registry.md assignment)
├── scripts/
│   └── bundle-template.py  # canonical bundle-edit tool (extract|inject|verify) — see Editing procedure below
└── README.md
```

## Deployment

INFRA-002 (phase 4) containerized this project: `docker-compose.yml` runs
`nginx:alpine` as container `forqsite-help`, joined to the external `edge` Docker
network, with `nginx.conf`, `index.html`, and `gap-handoff.html` bind-mounted
read-only — no Dockerfile, no image build. No host ports are published; the sibling
`caddy` repo's `sites/forqsite-help.caddy` reverse-proxies `forqsite.help` ->
`forqsite-help:6000` over that shared network. Deployed alongside caddy on the Docker
host that runs the edge proxy at a per-site directory under that host's service root,
mirroring the proxy's own deploy convention — required since Docker's embedded DNS
resolution for the `edge` network only works within a single Docker host.

Both HTML files are self-unpacking bundles: a `<script type="__bundler/template">`
tag contains a JSON-encoded HTML string. The unpacked HTML embeds a `DCLogic` class
holding app state, `nav()`/hash-routing logic, and render helpers (`scrollToAnchor`,
`copyCmd`, etc.).

**Editing procedure**: edit through `scripts/bundle-template.py`, never by hand-splicing
the `__bundler/template` JSON string. The script defines three subcommands, invoked as
`python3 scripts/bundle-template.py <subcommand> …`:

- `bundle-template.py extract <bundle.html> <out.template.html>` — pulls the decoded
  template out of the bundle into a plain HTML/JS file.
- `bundle-template.py inject <bundle.html> <in.template.html>` — re-encodes that file
  and splices it back into the bundle's `<script type="__bundler/template">` element.
- `bundle-template.py verify <bundle.html>` — re-encodes the template already in the
  bundle and asserts the result is byte-identical to what's there.

Workflow, as all four Phase 8 stories used it: run `verify` before editing, to confirm
the script's encoder still matches the bundler's; `extract` once to a scratch file;
make every edit in the unpacked template as plain markup/`DCLogic` script; `inject`
once; `verify` again.

Hand-splicing is wrong, not merely discouraged, because the encoder escapes every `/`
as `\u002F`, and the template contains its own `</script>` sequences that would
terminate the carrying script element if left unescaped — a manual re-encode that gets
either detail wrong corrupts the bundle with no useful error at load. (The historical
pre-script example in `docs/stories/CONTENT/CONTENT-001.md`'s Requires section predates
this tooling; it is not current guidance.)

The requirements the script doesn't cover are unchanged: `node --check` on any edited
script, and — where the change is interactive/CSS behavior — a headless-browser render
(e.g. Chromium `--dump-dom`), because a text diff can't confirm runtime behavior like
scroll reset or hash routing. The JSON round-trip check is now performed by `verify`
itself.

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

