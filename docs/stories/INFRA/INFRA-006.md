---
id: INFRA-006
rail: INFRA
title: A deploy procedure that survives the person who ran it
status: complete
phase: "11"
story_class: code
auth_gated: false
schema_introduces: false
touches:
  - scripts/deploy.sh
  - scripts/deploy-selftest.sh
  - .gitignore
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

On 2026-09-21 the live site was found serving Phase 7 content while the repository stood at
Phase 9. The deploy that fixed it was done by hand in one session, correctly, and then
existed only in the person who ran it. This story writes that procedure into the repository
as a script: back up the live bundles with a timestamp, copy the bytes of the committed
bundles, verify each file's hash on the far side, and print a record an operator can paste.
It is the *copy* half of the phase — it makes the deploy repeatable. The *served-bytes* half
is INFRA-007's, deliberately, and this story does not claim it.

**This spec names no deployment identifier literally**, and neither may the script. Phase
10's "Name the class, not the instance" constraint (`docs/ideology.md` § Accepted
constraints) binds the scaffolding as much as the target: a script that carries the host
name in a usage string or a default value is a new permanent leak in a public repo, and this
story's own hygiene check could never pass. Where a check needs the identifiers, it derives
them from history the way CONTENT-024 did, rather than typing them.

## Requires

- `docker-compose.yml`, `nginx.conf`, `index.html` and `gap-handoff.html` present and tracked
  at `HEAD`. `scripts/` exists (it holds `bundle-template.py`).
- No prior story in this phase. INFRA-006 and INFRA-007 are independent (phase doc § Story
  ordering).

## Recon (done; the builder does not repeat it)

**The deployment shape, verified 2026-09-21 and 2026-09-22.** State these as given; do not
re-derive them, and do not go looking at the live host to confirm them.

- `docker-compose.yml` runs `nginx:alpine` with exactly three bind-mounts: `nginx.conf`,
  `index.html`, `gap-handoff.html`. Nothing under `docs/` is served. There is no build step
  and no image of our own.
- `nginx.conf` sets `listen`, `server_name`, `root`, `index` and nothing else — no
  `open_file_cache`, no `expires`, no `etag`. A copied file is therefore served on the next
  request, and **no container restart is needed or wanted**. The phase doc's "Not done if"
  is explicit about this.
- `nginx.conf` is the one mount whose change would need a container action. That belongs in
  the script's header comment as a note, **not** as a step the script runs.
- Docker bind-mounts a single file **by inode**. Replacing a bundle with `mv`/rename on the
  remote would leave the container serving the old inode — the deploy would appear to
  succeed and change nothing. The content must be overwritten in place (`cp` over the
  existing file, or `cat >` it), never renamed over it. This is the single most likely way
  for a reasonable implementation of this story to be silently wrong.

**Spec-preflight note.** The scan reports no `scope:` findings and four constant warnings —
`FORQSITE_HELP_DEPLOY_HOST`, `FORQSITE_HELP_DEPLOY_DIR`, `STAMP` and `INFRA`. All are
intentional: the first three are named by this story and defined by its build, and `INFRA`
is a story-rail prefix.

**The procedure performed by hand, in order:** timestamped backup of both live bundles
(`cp -p index.html index.html.bak-<stamp>`, same for `gap-handoff.html`); copy both
committed bundles into the per-site directory; verify sha256 of each remote file against the
local committed file.

## Ensures

`scripts/deploy.sh` exists, is executable, and deploys the bytes of both bundles **as they
exist at a git ref** (default `HEAD`, via `git show <ref>:<path>`) rather than the
working-tree files; it refuses, before contacting anything, when either bundle is dirty at
that ref — where **dirty** means, for `index.html` or `gap-handoff.html`: the path is not
tracked at the ref, or its working-tree content differs from the ref's, or its staged
(index) content differs from the ref's (`git diff --quiet <ref> --` and `git diff --quiet
--cached <ref> --` over exactly those two paths must both pass) — and it offers no flag,
environment variable or prompt that overrides the refusal (forbidden proxy: a warning line
printed while the copy proceeds, or a `--force` that "an operator would only use knowingly");
it reads the ssh alias and the remote directory only from configuration
(`FORQSITE_HELP_DEPLOY_HOST` / `FORQSITE_HELP_DEPLOY_DIR`, falling back to a gitignored
`scripts/deploy.env` when unset) and exits non-zero with a message naming the two variable
*names* when either is missing, with no default of any kind (forbidden proxy: a default that
"only matches our host anyway", or a value carried in a usage string, an example, or a
comment); it backs up each live bundle to `<name>.bak-<stamp>` with one shared UTC stamp
before writing, overwrites each bundle's content in place without renaming over it, then
compares sha256 of each remote file to sha256 of the same file's bytes at the ref and exits
non-zero naming the file when either differs; on success it prints a pasteable block
containing the full 40-character deployed ref, both sha256 values, both backup file names and
the stamp, and **neither configuration value appears anywhere in that output** (forbidden
proxy: the source greps clean because the host and path are read from config at run time,
while the success block echoes them into the record an operator pastes into a tracked doc);
it never runs `docker`, `docker compose`, `systemctl` or any restart; `--dry-run` completes
every local check and prints what it would do while executing no `ssh` at all; and
`scripts/deploy-selftest.sh` exercises the refusals and the happy path against a temporary
fixture repository and fixture target directory, contacting no real host.

## Instructions

1. **Write `scripts/deploy.sh`** (bash, `set -euo pipefail`, `chmod +x`). Usage:
   `deploy.sh [--ref <git-ref>] [--dry-run]`. Default ref `HEAD`.

2. **Repo resolution.** Operate on the git repository containing the current working
   directory (`git rev-parse --show-toplevel`), not on a path derived from the script's own
   location. This is ordinary git-tool behaviour and it is also the seam that lets the
   selftest run the real script against a throwaway repository with no test-only branch
   inside the script. Fail if either bundle is absent at the ref.

3. **Configuration.** Read `FORQSITE_HELP_DEPLOY_HOST` (an ssh alias) and
   `FORQSITE_HELP_DEPLOY_DIR` (the per-site directory on the far side). If either is unset or
   empty, source `scripts/deploy.env` if it exists, then re-check. If either is still
   missing, write to stderr a message that names the two variable names and says they may be
   set in the environment or in `scripts/deploy.env`, and exit 2. Name no value, no host, no
   path, not even as "e.g.". Add `scripts/deploy.env` to `.gitignore`.

4. **Dirty check, before any network contact**, using the definition in `## Ensures`. On
   refusal, print which bundle is dirty and how (unstaged / staged / untracked), and exit 3.
   Do not implement an override. The reason the check is meaningful is that the deploy reads
   from the ref: without the refusal, an operator's local edits would silently not ship,
   which is the same drift in the opposite direction.

5. **Stamp.** One `STAMP=$(date -u +%Y%m%dT%H%M%SZ)` shared by both files, so a pair of
   backups is identifiable as one deploy.

6. **Per bundle, over a single `ssh "$HOST"` invocation per step:**
   - if the file exists on the far side, `cp -p <name> <name>.bak-$STAMP`;
   - stream `git show "$REF:<name>"` to a temporary file in the same directory, then `cp`
     that temporary over the live file (in place — see Recon: rename breaks the bind mount),
     then remove the temporary;
   - `sha256sum <name>` on the far side and compare against
     `git show "$REF:<name>" | sha256sum` locally.
   Quote the remote directory once into the remote command; never interpolate it into
   anything printed. If `sha256sum` is unavailable remotely, fail with that as the message.

7. **Exit codes**, used consistently and documented in the header comment: `0` success,
   `2` configuration missing, `3` dirty-tree refusal, `4` hash verification failure,
   `5` transport/remote failure.

8. **Success output.** A block of the shape below — field names and layout are the builder's
   to finalise, the contents are not. The target is referred to by class, never by value:

   ```
   deployed  <40-char ref>   (<ref-arg> )
   stamp     <STAMP>
   index.html         <sha256>  verified
   gap-handoff.html   <sha256>  verified
   backups   index.html.bak-<STAMP>, gap-handoff.html.bak-<STAMP>
   target    the configured per-site directory, via the configured ssh alias
   next      run the drift check to confirm the bytes a request returns (INFRA-007)
   ```

9. **Header comment** (class language only): what the script does, the five exit codes, the
   note that `nginx.conf` is bind-mounted and a change to it — unlike the bundles — needs a
   container action that this script deliberately does not perform, and the note that the
   bundles must be overwritten in place because the bind mount follows the inode.

10. **Write `scripts/deploy-selftest.sh`** (executable). It builds, in a temp directory: a
    fixture git repo containing two small stand-in `index.html`/`gap-handoff.html` files with
    one commit; a fixture "remote" directory; and a stub `ssh` placed first on `PATH` that
    ignores its first argument and runs the rest with `bash -c` against the fixture directory.
    The stub also appends a line to a marker file each time it is invoked. The selftest then
    runs the real `scripts/deploy.sh` from inside the fixture repo for each case in
    `## Tests`, asserts the exit code and the stated condition, and exits non-zero if any case
    fails. No branch in `deploy.sh` may exist for the sake of this harness.

11. **Do not** write a provenance sidecar (INFRA-008 adds that to this script's path later),
    do not curl or otherwise check what is served (INFRA-007), and do not edit
    `docs/architecture.md` or `docs/checkpoints.md` (CONTENT-028).

*(Proportionality note: this is the phase's only executable story, with two new files, a
transport, and five failure paths that each need a named exit code — the length is spent on
the failure paths, not on restating the happy one.)*

## Tests

The project has no test suite (`test_command` is `true`), so the acceptance evidence is the
selftest plus one hygiene check. **Run the selftest and paste its full output into the build
note.** It must exercise all five cases and report each by name:

```bash
cd "$(git rev-parse --show-toplevel)" && ./scripts/deploy-selftest.sh
```

| Case | Setup | Must hold |
|---|---|---|
| missing config | both variables unset, no `deploy.env` | exit 2; message names both variable names; stub-ssh marker file absent |
| dirty tree | fixture repo clean, then append a byte to one bundle | exit 3; message names that bundle; both fixture target files byte-identical to before the run |
| happy path | clean fixture repo | exit 0; both target files match the committed bytes; two `.bak-<stamp>` files exist sharing one stamp; success block printed |
| hash mismatch | stub `ssh` corrupts the file after the copy step | exit 4; message names the failing bundle |
| dry run | clean fixture repo, `--dry-run` | exit 0; stub-ssh marker file absent (no ssh invoked at all) |

Acceptance: all five pass, and in the happy-path case the captured stdout+stderr contains
neither the fixture host alias nor the fixture target directory path (`grep -F` both; zero
hits). The last is the forbidden-proxy check for the success block, and it is why the
selftest must capture the output rather than let it stream to the terminal.

The hygiene assertion, deriving its search terms from history so neither builder nor reviewer
types an identifier (the CONTENT-024 form, verified there on 2026-09-21):

```bash
cd "$(git rev-parse --show-toplevel)"
mapfile -t IDS < <(git show 8bb837b:docs/cer/backlog.md \
  | grep '^| CER-003 ' | grep -o '`[^`]*`' | tr -d '`')
[ "${#IDS[@]}" -eq 3 ] || { echo "FAIL: expected 3 identifiers, got ${#IDS[@]}"; exit 1; }
args=(); for i in "${IDS[@]}"; do args+=(-e "$i"); done
hits=$(grep -Il "${args[@]}" scripts/deploy.sh scripts/deploy-selftest.sh .gitignore \
  docs/stories/INFRA/INFRA-006.md || true)
[ -z "$hits" ] && echo "PASS: no identifier in this story's files" || { echo "FAIL:"; echo "$hits"; }
```

Acceptance: `PASS`. Also confirm by reading that neither new file carries an absolute
deployment path or a host name in any *other* form — a comment, a default value, an example
invocation, or a usage string — since the grep only catches the three known strings.

Deploying to the real site is **not** part of this story's acceptance. When the operator
chooses to run it for real, that is a deploy, and the record it prints is the artifact.

## Out of scope

- **Checking what is served.** Hashing the file in the remote directory proves the copy
  landed; it does not prove the bytes a request returns. That assertion is INFRA-007's, and
  making it here too would create a second writer of the same claim, in the weaker form
  INFRA-007's own Ensures forbids. The success block points at it instead.
- **The provenance sidecar** (INFRA-008), which is written by this script's path later.
- **Rollback.** The timestamped backups make restoring possible, and the success block names
  them so an operator can, but no restore mode is built here. Deliberate: a restore path
  needs its own hash verification and its own "which backup" selection, and bolting it on
  would double this story.
- **Documenting the procedure** in `docs/architecture.md` / `docs/checkpoints.md` /
  `docs/ideology.md` — CONTENT-028.
- **Automating the deploy on merge.** Who runs it and when stays an operator decision (phase
  doc § What is NOT in scope).
- **Deploying `nginx.conf`.** It is bind-mounted but not a bundle, and a change to it needs a
  container action this script does not perform. The header comment records that; nothing
  else here acts on it.
- **Any change to the bundles themselves.** This phase carries no content.
