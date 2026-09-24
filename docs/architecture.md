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
Current phase: 11 — Make the deploy repeatable, and make drift visible

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
├── docs/
│   └── claims-manifest.json  # every stamped claim both pages make about forqsite, and where its evidence lives
└── README.md
```

## Deployment

INFRA-002 (phase 4) containerized this project: `docker-compose.yml` runs
`nginx:alpine` as container `forqsite-help`, joined to the external `edge` Docker
network, with `nginx.conf`, `index.html`, and `gap-handoff.html` bind-mounted
read-only — no Dockerfile, no image build. No host ports are published; the sibling
`caddy` repo's `sites/forqsite-help.caddy` reverse-proxies the public site's address to
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

**Claims manifest.** `docs/claims-manifest.json` lists every forqsite stamp in both pages,
every claim each stamp covers, and where in the forqsite repository each claim's evidence
lives, against one pinned release commit. The stories that re-verify or restamp a claim
update it in the same change.

**Deploy, drift-check and provenance scripts** (INFRA-006, INFRA-007, INFRA-008, Phase 11).
Three scripts, each documented in full in its own header comment — this section points at
those tables rather than restating them:

- `scripts/deploy.sh` — copies the two published bundles to the configured per-site
  directory over the configured ssh alias, backing up each live file on the remote side to
  `<name>.bak-<UTC stamp>` (both bundles sharing one stamp) before overwriting it in place.
  "In place" is required, not stylistic: the remote bind mount follows the file's inode, so
  a rename-over would leave the container serving an old, unlinked inode while the deploy
  reported success. After both bundles are copied and hash-verified, `deploy.sh` generates
  the provenance sidecar (below) and deploys it the same way. Retention is bounded: once
  every file of a deploy has verified, that deploy's backup set is marked verified and
  verified sets beyond a stated count (a constant in the script's header) are pruned, while
  the set just made and any set without a verified marker — such as a failed deploy's
  rollback copy — are always kept. The script assumes the remote directory is writable only
  by the deploy account: its unpredictable staging names and noclobber backups narrow a
  co-tenant's symlink race there, but do not make a shared directory safe. On any ssh or
  remote-command failure it prints a fixed reason class (e.g. "the connection was
  refused"), never ssh's own diagnostic text or the remote shell's, because that text
  names the configured target (CER-028, INFRA-014).
- `scripts/drift-check.sh` — the served-bytes half of the same invariant. It fetches each
  bundle over HTTP from the configured site and hashes the response bytes, then hashes
  `git show <ref>:<bundle>`, and compares the two sha256 values — never the file sitting in
  the remote directory, which is exactly the proxy a stale bind-mounted inode would pass.
  `nginx.conf` is also bind-mounted but is never served over HTTP (it only configures
  `listen`/`server_name`/`root`), so this check is undefined for it and says so in its
  report rather than silently skipping it.
- `scripts/make-provenance.sh` — a pure function of `(repo, ref)` that prints the
  provenance sidecar's JSON to stdout; it reads no configuration and contacts no host.

**Configuration surface.** All three scripts read their settings from the environment,
falling back to a gitignored `scripts/deploy.env`. That file is never committed; a
committed `scripts/deploy.env.example` template (all lines commented) is the starting
point for creating it. The variable names: `FORQSITE_HELP_DEPLOY_HOST` (deploy.sh, ssh
alias), `FORQSITE_HELP_DEPLOY_DIR` (deploy.sh, remote per-site directory) and
`FORQSITE_HELP_SITE_URL` (drift-check.sh, base URL to fetch served bytes from). The file
is parsed as `KEY=value` data for those known keys by one shared reader loaded from the
scripts' own directory, never executed, so its values stay literal text, and any other
line is refused by line number without printing its content (CER-024).

**The provenance sidecar** (`site-provenance.json`, INFRA-008). `make-provenance.sh`
generates it and `deploy.sh` writes it last, deliberately: it is deployed only after both
bundles have landed and hash-verified, because it asserts "this commit is deployed" and
writing it earlier would publish that claim before it was true. `docker-compose.yml`
bind-mounts it alongside the two bundles; that mount is a one-time addition requiring a
container recreate to take effect, and must be added only after the file already exists on
the remote side (see `deploy.sh`'s header for the bootstrap order), or Docker creates a
directory at that path instead of bind-mounting a file. `drift-check.sh` fetches it and
reports its claimed per-bundle sha256 values as a labelled claim alongside the real
served-vs-committed comparison — it can only ever add a failure (a contradiction between
its claim and the served bytes) and never supply or suppress a match; trusting it as the
basis of the drift decision would be the same proxy substitution the served-bytes check
exists to refuse.

**Exit-code contract.** Each script's own header comment carries its exit-code table —
restating those tables here would make this doc a second writer of a fact each script
already owns, and the numbers would drift the first time one is added. At class level, the
contract all three share: `0` means the invariant the script asserts held; every distinct
failure mode gets its own code; and a usage error never shares a code with a condition of
substance (CER-015 records where `deploy.sh` does not yet hold this).

**Verification record — 2026-09-21.** By hand, before this phase's scripts existed: the
deployment host was found serving `index.html` as committed at `5ec8194` and
`gap-handoff.html` as committed at `813ce27` (both Phase 7, 2026-09-16), while the
repository stood at Phase 9 — six commits touching the two bundles, one of them a factual
correction, had not reached readers. Both live bundles were backed up under a shared
timestamp and copied; each file's sha256 was verified on the remote side and again locally;
both pages were then fetched over the reverse proxy, returning `200` with bodies hashing
equal to the repository's. This incident is what CER-014 and INFRA-006/007/008 exist to
prevent a gate from missing again.

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

