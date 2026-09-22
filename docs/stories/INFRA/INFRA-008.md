---
id: INFRA-008
rail: INFRA
title: Site provenance a reader and a check can both see
status: draft
phase: "11"
story_class: code
auth_gated: false
schema_introduces: false
touches:
  - scripts/make-provenance.sh
  - scripts/deploy.sh
  - scripts/drift-check.sh
  - scripts/provenance-selftest.sh
  - docker-compose.yml
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

Neither published bundle contains any reference to this repository's own commit or version —
verified, zero occurrences. So when the live site sat five days and two phases stale, nothing
on the site said which version a reader was looking at, and nothing a check could read said it
either. INFRA-007 now answers "do the served bytes match the ref?" for anyone holding the
repository; this story gives the *site itself* a machine-readable record of which commit
produced it, written at deploy time as a **sidecar served alongside the bundles** so both
bundles stay byte-identical to their committed form. A stamp written into a bundle at deploy
would destroy the equality INFRA-007 depends on — the two stories would fight — and a stamp
committed into a bundle would put a generated-artifact edit into the release path, which
`docs/ideology.md` § Generated-artifact discipline forbids (`index.html` and
`gap-handoff.html` are self-unpacking bundles changed only through `scripts/bundle-template.py`).

## Requires

- INFRA-006 complete: `scripts/deploy.sh` exists with its config surface
  (`FORQSITE_HELP_DEPLOY_HOST`, `FORQSITE_HELP_DEPLOY_DIR`, gitignored `scripts/deploy.env`),
  its backup → overwrite-in-place → verify-hash loop, and its `--ref` / `--dry-run` flags.
- INFRA-007 complete: `scripts/drift-check.sh` exists with `FORQSITE_HELP_SITE_URL` and the
  exit table `0/2/3/4/5/64`.
- `docker-compose.yml` bind-mounts exactly three files, each individually
  (`./nginx.conf`, `./index.html`, `./gap-handoff.html`), from a relative path.

## Decisions (made here; the builder implements, does not re-litigate)

1. **Path and format.** One file, `site-provenance.json`, deployed into the same remote
   directory as the bundles and served at `<base-url>/site-provenance.json`. JSON, because it
   is the one format both audiences read without tooling: nginx's stock `mime.types` serves
   `.json` as `application/json` and a browser renders it as text, while a check parses it.
   Exact shape (key order fixed, so the output is diffable):

   ```json
   {
     "schema": 1,
     "repo_commit": "<40-char sha of this repo at the deployed ref>",
     "repo_ref": "<the --ref string as given, e.g. HEAD>",
     "repo_commit_date": "<committer date, UTC, 2026-09-22T14:03:11Z>",
     "deployed_at": "<UTC time the sidecar was generated, same format>",
     "bundles": {
       "index.html": "<sha256 of that bundle's bytes at the ref>",
       "gap-handoff.html": "<sha256 of that bundle's bytes at the ref>"
     }
   }
   ```

   `repo_commit_date` is carried because "how stale is this?" is the question the incident
   asked and it cannot be answered from a bare sha without the repository. The commit
   *subject* is deliberately **not** carried: it adds nothing a check needs, and it is the
   only candidate field that is free-form text — omitting it keeps every value a hex string,
   an ISO timestamp, an integer or a fixed filename, so the generator needs no JSON string
   escaping at all. Carrying each bundle's sha256 is deliberate: it lets a reader or a check
   compare the claim against reality without fetching both bundles.

2. **The infrastructure change, stated plainly and not hidden inside a script.** Docker
   bind-mounts here are **per-file**, so a new served file requires a new `volumes:` entry in
   `docker-compose.yml`:

   ```yaml
       - ./site-provenance.json:/usr/share/nginx/html/site-provenance.json:ro
   ```

   Unlike a bundle copy — which needs no container action at all, because the mount already
   exists and the file is overwritten in place — **this mount must be added and the container
   recreated** (`docker compose up -d`) before the sidecar is ever served. The bootstrap order
   is load-bearing and must be documented in the script header and in the deploy's own
   "next" line: **(a)** run `deploy.sh` once so the file exists in the remote directory,
   **(b)** add the mount, **(c)** recreate the container. Adding the mount first makes Docker
   create a *directory* at that path and the mount is then permanently wrong. After the
   one-time recreate, every later deploy is a copy like the bundles and needs nothing.

3. **Who writes it.** A separate generator, `scripts/make-provenance.sh`, which writes the
   JSON to **stdout** and does nothing else; `deploy.sh` calls it and performs the transport.
   The split is not decoration: generation is a pure function of (repo, ref) and is therefore
   testable with no fixture remote at all, while transport is `deploy.sh`'s already-built and
   already-tested concern. It also gives a human a way to see exactly what would be published
   without deploying.

4. **Whether `drift-check.sh` reads it — and the bound on how.** It reads it, strictly as
   **additional context reported**, never as the basis of the match decision. Reading a
   version string out of the sidecar and trusting it is precisely the proxy INFRA-007 bans: a
   stale or hand-written sidecar would lie, and the site would look current because it said
   so. The rule, stated so the next builder cannot get it wrong: **the sidecar may only ever
   add a failure; it may never supply a match, suppress one, or change a DRIFT into an ok.**
   Concretely — the existing per-bundle decision (served bytes vs `git show <ref>:<bundle>`)
   is untouched; the sidecar's `repo_commit` / `deployed_at` are printed as a *claim*, labelled
   as such; and the sidecar's per-bundle sha256 values are compared against the sha256 of the
   bytes actually served, with a disagreement reported and given its own new exit code `6`,
   reachable only when no bundle drifted (drift's `3` always outranks it). A green check must
   never pass over a provenance claim it can see is false — that silence is the sin this phase
   exists to end.

## Ensures

`scripts/make-provenance.sh` exists, is executable, and prints to stdout exactly the JSON
object in § Decisions 1 for `--ref <git-ref>` (default `HEAD`), exiting `0` on success, `5`
when a bundle is not tracked at the ref, and `64` on a usage error — usage sharing a code with
no other condition (CER-015, following `drift-check.sh`, not `deploy.sh`); `scripts/deploy.sh`
deploys that output to `site-provenance.json` in the configured directory **after** both
bundles have been copied and hash-verified, using the same backup → overwrite-in-place →
verify-sha256 sequence and the same existing exit codes (`4` mismatch, `5` transport), prints
it under `--dry-run` without contacting any host, and still never runs docker or any
container action; `scripts/drift-check.sh` fetches the sidecar and reports `repo_commit` and
`deployed_at` as a labelled claim plus a per-bundle claimed-vs-served sha256 comparison,
exiting `6` only when the sidecar contradicts the served bytes and no bundle drifted, `3`
unchanged whenever any bundle drifts, and `0` unchanged when the sidecar is absent or
unfetchable (reported as a line, never an error) — and the sidecar is read by **no** code path
that can produce a match, with these forbidden explicitly as the basis of any match decision:
the sidecar's `repo_commit`, its `deployed_at`, its claimed bundle sha256 values, and its mere
presence; `docker-compose.yml` gains exactly one `volumes:` line for the sidecar and no other
change; `index.html` and `gap-handoff.html` are **byte-identical before and after this story**
(`git diff --stat HEAD~1 -- index.html gap-handoff.html` is empty at the story commit), no
`verified <date> against <product-commit>` stamp anywhere in either bundle is rewritten, moved
or synthesised, and no bundle is read, written or modified by any new code — forbidden proxy:
a generated stamp injected into a bundle's bytes at deploy time, or a "harmless" whitespace or
comment edit to a bundle, either of which would break INFRA-007's equality while the deploy
still reported success; no deployment or site identifier of ours (host name, absolute
deployment path, site URL) appears in any new or edited file, in any usage string, default,
comment or example; and `scripts/provenance-selftest.sh` exercises the real scripts against a
fixture git repo, a stub `ssh` on `PATH` and a local server bound to `127.0.0.1` for every case
in `## Tests`, contacting no other host.

## Instructions

1. **Write `scripts/make-provenance.sh`** (bash, `set -euo pipefail`, `chmod +x`), in
   `drift-check.sh`'s shape: header block (what it does / usage / exit codes / notes), then
   argument parsing, then the work. `git rev-parse --show-toplevel` and `cd` to it — the seam
   both siblings use, and the one that lets the selftest run the real script against a
   throwaway repo with no test-only branch in the script. Usage:
   `make-provenance.sh [--ref <git-ref>]`. Exit `64` on an unrecognised argument or `--ref`
   with no value; exit `5` naming the bundle and the ref when `git cat-file -e <ref>:<bundle>`
   fails. Fields: `git rev-parse "$REF"`; the `--ref` string as given; `git log -1
   --format=%cd --date=format-local:%Y-%m-%dT%H:%M:%SZ` with `TZ=UTC` (or equivalent) for the
   commit date; `date -u +%Y-%m-%dT%H:%M:%SZ` for `deployed_at`; `git show "$REF:$bundle" |
   sha256sum | cut -d' ' -f1` per bundle. Emit with `printf` — no `jq` dependency, and none is
   needed given Decision 1's escape-free field set. **Reads no configuration and contacts
   nothing**; it is a pure function of (repo, ref).

2. **Extend `scripts/deploy.sh`.** After the existing per-bundle verify loop has passed for
   both bundles (i.e. after the `mismatch` check), generate the sidecar with
   `scripts/make-provenance.sh --ref "$REF"` and deploy it with the same three remote steps the
   bundles use: back up to `site-provenance.json.bak-$STAMP` if present, stream to a temp name
   and `cp` **over** the live file (never a rename — the bind-mount inode note in the existing
   header applies verbatim), then `sha256sum` it on the far side and compare against the
   locally-computed hash of the generated bytes. Reuse the existing exit codes: `4` on
   mismatch, `5` on a remote/transport failure. Order matters and must be stated in the
   header: the sidecar is written **last**, because it asserts "this commit is deployed" and
   writing it before the bundles land would publish a claim that a failed copy then falsified.
   Under `--dry-run`, print the generated JSON and exit `0` without any ssh. Add the sidecar's
   hash line to the success block, and extend the `next` line with the one-time bootstrap from
   Decision 2. Do **not** touch `deploy.sh`'s CER-015 exit-`2` overload (out of scope), and do
   not add a container action.

3. **Add the bind-mount to `docker-compose.yml`** — exactly the one `volumes:` line in
   Decision 2, relative-path form like its three siblings, `:ro`. Nothing else in the file
   changes.

4. **Extend `scripts/drift-check.sh`** under Decision 4's bound. Fetch
   `<base-url>/site-provenance.json` with the same `fetch_bundle`-style curl discipline (to a
   file, identity encoding, no redirect following, timeouts). Then, in the report, after the
   per-bundle lines and the `nginx.conf` line:
   - If the fetch failed or the body does not parse as the expected shape: print one line
     saying the sidecar is absent or unreadable and that the bundle decision above does not
     depend on it. **Do not** change the exit code for this.
   - Otherwise print `provenance claims <repo_commit-short> deployed <deployed_at>`, labelled
     as a claim, and per bundle compare the sidecar's claimed sha256 against `SERVED_SHA` —
     the hash of the bytes this run actually fetched, never against the committed hash and
     never against anything the sidecar itself supplied.
   - Exit `6` when a claimed hash disagrees with a served hash **and** `DRIFT_COUNT` is 0.
     When `DRIFT_COUNT` is non-zero, exit `3` as today.
   Update the header's exit-code table and add a note stating, in one sentence, why the
   sidecar can only ever add a failure. Parse without `jq` (a `grep -o`/`sed` extraction of
   the fixed-shape fields is sufficient and keeps the check dependency-free); a parse failure
   is the "unreadable" branch, not an error.

5. **Write `scripts/provenance-selftest.sh`** (executable) in the siblings' harness shape:
   `mktemp -d` work dir with a `cleanup` trap, a fixture git repo, a stub `ssh` first on `PATH`
   writing a marker file (as `deploy-selftest.sh` does), a `127.0.0.1` static server driven
   from a control directory so served bytes can differ from on-disk bytes (as
   `drift-check-selftest.sh` does), and the same `report`/`PASS_COUNT`/`FAILURES` reporting.
   Capture stdout+stderr per case to a file so the hygiene greps in `## Tests` are possible.

6. **Ideology note (Step 4a, resolved inline).** `docs/ideology.md` § Name the class, not the
   instance binds every new file here; the operator ruled on 2026-09-22 that the public site
   URL is *also* an instance identifier, because this repository and its product are to be
   released as public sibling repos and a downstream adopter rebrands both. Configuration
   only — no exception is taken in this story. § Generated-artifact discipline is preserved by
   construction: the sidecar is a *fourth* artifact, generated at deploy time, never committed
   and never written into the working tree, so no generated-artifact edit enters the release
   path and `.gitignore` needs no new entry.

**Spec-preflight note.** The scan reports `docs/ideology.md` as named-but-not-in-scope: that
is intentional — this story *reads* the constraint and takes no exception to it; every edit to
`docs/ideology.md` belongs to CONTENT-028 (§ Out of scope). Its constant warnings for
`DRIFT_COUNT`, `SERVED_SHA`, `PASS_COUNT`, `FAILURES` and `PATH` are scanner artifacts — all
are existing shell variables in `scripts/drift-check.sh` and `scripts/drift-check-selftest.sh`.

## Tests

The project has no test suite (`test_command` is `true`), so the acceptance evidence is the
selftest plus the hygiene and byte-identity checks. **Run the selftest and paste its full
output into the build note.** It must exercise every case below and report each by name:

```bash
cd /mnt/work/forqsite.help && ./scripts/provenance-selftest.sh
```

| Case | Setup | Must hold |
|---|---|---|
| generate | `make-provenance.sh` in the fixture repo | exit 0; stdout is one JSON object carrying the fixture `HEAD` sha, both bundle sha256 values matching `git show HEAD:<bundle> \| sha256sum`, and both timestamps in `…Z` form |
| generate, untracked bundle | a bundle removed at the ref | exit 5; names the bundle and the ref; no partial JSON on stdout |
| generate, usage error | an unrecognised flag | exit 64 — asserted explicitly **not** 2 (CER-015) |
| deploy writes sidecar | full `deploy.sh` happy path against the fixture target + stub ssh | exit 0; `site-provenance.json` present in the target with the generated bytes; its `repo_commit` is the fixture `HEAD`; success block names it |
| bundles untouched by deploy | same run | both fixture bundles in the target are byte-identical to `git show HEAD:<bundle>`; the sidecar bytes appear in **no** bundle |
| sidecar written last | stub ssh fails the copy step for `gap-handoff.html` | non-zero exit; `site-provenance.json` **absent** from the target — no claim published over a failed deploy |
| dry run | `deploy.sh --dry-run` | exit 0; JSON printed; stub-ssh marker file absent |
| drift check, honest sidecar | served bundles == `HEAD`, sidecar consistent with them | exit 0; the claim line names the sidecar's commit and is labelled a claim |
| drift check, lying sidecar | served bundles == `HEAD`, sidecar's claimed `index.html` sha256 altered | exit 6; the disagreement is reported per bundle |
| lying sidecar cannot rescue drift | served `index.html` is an older commit's bytes, sidecar claims `HEAD` and matches nothing | exit 3, **not** 0 and **not** 6 — proves the sidecar supplies no match |
| sidecar absent | sidecar path returns 404, bundles match | exit 0; one line says the sidecar is absent and that the decision does not depend on it |

Acceptance: every case passes, and across the captured output of all cases `grep -c` finds
zero occurrences of any hostname other than `127.0.0.1`.

Byte-identity of the published bundles, asserted directly:

```bash
cd /mnt/work/forqsite.help
git diff --stat HEAD -- index.html gap-handoff.html
git grep -n -c 'site-provenance' -- index.html gap-handoff.html || echo "PASS: sidecar name absent from both bundles"
```

Acceptance: the first prints nothing; the second prints `PASS`.

The hygiene assertion, deriving its search terms from history so neither builder nor reviewer
types an identifier (the CONTENT-024 form, as reused by INFRA-006 and INFRA-007):

```bash
cd /mnt/work/forqsite.help
mapfile -t IDS < <(git show 8bb837b:docs/cer/backlog.md \
  | grep '^| CER-003 ' | grep -o '`[^`]*`' | tr -d '`')
[ "${#IDS[@]}" -eq 3 ] || { echo "FAIL: expected 3 identifiers, got ${#IDS[@]}"; exit 1; }
args=(); for i in "${IDS[@]}"; do args+=(-e "$i"); done
hits=$(grep -Il "${args[@]}" scripts/make-provenance.sh scripts/provenance-selftest.sh \
  scripts/deploy.sh scripts/drift-check.sh docker-compose.yml \
  docs/stories/INFRA/INFRA-008.md || true)
[ -z "$hits" ] && echo "PASS: no identifier in this story's files" || { echo "FAIL:"; echo "$hits"; }
```

Acceptance: `PASS`. Also confirm by reading that no new or edited file carries a public
hostname, an absolute deployment path or a host alias in any *other* form — the grep only
catches the three known strings.

Running any of this against the real site is **not** part of acceptance. When the operator
runs the deploy for real, the block it prints and the served sidecar are the artifacts.

## Out of scope

- **`scripts/deploy.env.example`.** The committed placeholder template is CONTENT-028's, not
  this story's; this story adds no new configuration variable, so it needs none.
- **Any edit to `index.html` or `gap-handoff.html`**, including a stamp, a comment or a
  whitespace change — the Ensures assert their byte-identity, and the phase carries no content.
- **Rewriting, moving or synthesising any `verified <date> against <product-commit>` stamp.**
  Those record when a claim was checked against the *product* repo; regenerating one at deploy
  time would assert a verification that never happened. Phase 10 spent itself correcting
  exactly that class of error.
- **Serving a human-rendered provenance page**, a footer, a banner, or any UI surface for the
  sidecar. A reader who opens the URL sees the JSON; anything richer is a content story and
  would require touching a bundle.
- **Checking `nginx.conf` over ssh**, and any container action (`docker`, `docker compose`,
  restart, reload) from any script. The one-time recreate in Decision 2 is an operator step,
  documented, not automated.
- **Fixing `deploy.sh`'s CER-015 exit-code overload**, and fixing CER-005's render gap.
- **Wiring anything into `docs/checkpoints.md`, `docs/architecture.md` or `docs/ideology.md`** —
  CONTENT-028.
