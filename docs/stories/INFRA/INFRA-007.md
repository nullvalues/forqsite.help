---
id: INFRA-007
rail: INFRA
title: A drift check that compares served bytes to committed bytes
status: complete
phase: "11"
story_class: code
auth_gated: false
schema_introduces: false
touches:
  - scripts/drift-check.sh
  - scripts/drift-check-selftest.sh
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

On 2026-09-21 the live site was found serving Phase 7 content while the repository stood at
Phase 9. `cp-8` and `cp-9` both went fully green over it, because every gate compared the
repository to itself and stopped at the repository's edge. This story writes the check that
does not stop there: it asks whether the bytes an HTTP request actually returns are the bytes
that were committed, for both served bundles, and exits non-zero when they are not so a
checkpoint can be gated on it. It is the *served-bytes* half of the phase; INFRA-006 built
the copy half and its success block already points here.

The whole value of this check is **what it asserts on**. Three rows already on the backlog
record the same substitution in smaller places — CER-009 (a probe bound on a same-day date
filter instead of an attempt-id boundary), CER-011 (a line-oriented grep that breaks on a
soft-wrap instead of normalising whitespace), CER-012 (a whole-DOM-dump grep counting inert
script source as rendered markup) — each an assertion written against something easy to
compute instead of against the invariant. The stale site is the fourth and most expensive
instance (CER-014). This story is where the pattern is answered, by being built correctly
once in the place it cost something. It does not resolve those rows: CER-009/011/012 stay
filed as harness work (phase doc § What this phase is not), and CER-014 is resolved by this
story *landing*, recorded by CONTENT-028 — not by an edit made here.

## Requires

- INFRA-006 complete: `scripts/deploy.sh` exists and `scripts/deploy.env` is already in
  `.gitignore`. This story reuses that configuration file rather than adding a second one.
  (The two stories are independent in build order per the phase doc; this is a reuse
  dependency, and if `deploy.env` were absent the only consequence would be adding the
  `.gitignore` line here.)
- `index.html` and `gap-handoff.html` tracked at `HEAD`, with more than one commit in their
  history — the commit-walk has to have something to walk.
- `curl` and `sha256sum` available locally. No remote tooling is required: this check makes
  an HTTP request, not an ssh connection.

## Recon (done; the builder does not repeat it)

State these as given; do not re-derive them, and do not contact the live host.

- **The invariant.** `sha256(bytes an HTTP GET of <base-url>/<bundle> returns)` ==
  `sha256(git show <ref>:<bundle>)`. Everything else is a proxy for it.
- **Why hashing the remote file is not enough.** Docker bind-mounts a single file by inode
  (INFRA-006 § Recon). A rename over a bundle leaves the container serving the old, now
  unlinked inode: the file in the remote directory would hash correct while the request
  returns stale bytes. A check that ssh'd in and hashed the file would pass over exactly the
  failure INFRA-006's in-place-overwrite rule exists to prevent. This is the subtlest of the
  forbidden proxies and the reason the fetch is non-negotiable.
- **Byte-level only, never render-level.** CER-005 records that the ledger renders zero rows
  as DOM at any origin and the `#gaps` fragment renders no screen. A render-based or
  DOM-based check inherits CER-005 and CER-012 on its first run and would report drift on a
  correctly deployed site. The bundles' rendering is a sibling content phase's subject.
- **`nginx.conf` is bind-mounted but never served.** `docker-compose.yml` mounts exactly
  three files; `nginx.conf` sets `listen`, `server_name`, `root`, `index` and nothing else.
  No HTTP request returns `nginx.conf`'s bytes, so the invariant above is *undefined* for it.
- **Spec-preflight note.** The scan reports three constant warnings — `FORQSITE_HELP_SITE_URL`
  and `BASE_URL` are named by this story and defined by its build, and `DRIFT` is an output
  token, not a constant — and one `scope:` finding, `docs/ideology.md`. That finding is
  intentional and must not be resolved by widening `touches:`: the file is cited as the source
  of a constraint and named in `## Out of scope` as a file this story must **not** edit
  (CONTENT-028 owns it). Declaring it in scope would assert an edit right this story does not
  have.
- **Two byte-level traps in an ordinary bash implementation**, both of which produce a false
  DRIFT on a correct site: command substitution (`$(curl …)`) strips trailing newlines, so
  the fetched bytes must go to a file, never to a shell variable; and a compressed response
  hashes as the compressed entity, so the request must ask for an identity encoding.

## Ensures

`scripts/drift-check.sh` exists, is executable, and for **each of `index.html` and
`gap-handoff.html`** compares `sha256` of the bytes an HTTP GET actually returns — fetched
to a file, with an identity content-encoding and no redirect following — against `sha256` of
`git show <ref>:<bundle>` (default ref `HEAD`), exiting `0` only when both match and exiting
`3` when either differs; the comparison rests on **no proxy**, and each of the following is
forbidden as the basis of the match/no-match decision: file mtime, file size, a version
string or phase marker grepped out of the served HTML, the container reporting itself up
(`docker ps` or equivalent), `scp`/`ssh` exiting zero, and — the one a reasonable
implementation is most likely to reach for — hashing the bundle file in the remote
bind-mount directory *instead of* the bytes a request returns, which would report a match
while a stale inode is served; on any mismatch the output **names which commit the served
bytes do match**, by walking the commits reachable from the ref that touched that bundle and
hashing each distinct blob until one matches, printing that commit's short sha, committer
date, subject and how many commits behind the ref it is, alongside the ref's own short sha
and subject (so the report reads as one sentence of the form "live matches <that commit>,
the ref is <this commit>"), and when **no** commit matches it prints that as the real state
it is — the served bytes correspond to no committed version of that bundle, i.e. the file
was hand-edited on the host or deployed from a ref outside this history — still exiting `3`
for drift and never treating it as a tool error; the report contains one explicit line for
`nginx.conf` stating that it is bind-mounted but never served and therefore not checkable by
this check's invariant (forbidden proxy: silently omitting the file, or checking it over ssh
and presenting a file-on-host comparison in the same report as if it carried the same
strength); the base URL, the ssh alias and the remote directory are read only from
configuration and **no** deployment or site identifier of ours appears anywhere in the
script, the selftest, this spec, or in any usage string, default, comment or example in
them; the exit codes are distinct and each failure mode has its own (`0` no drift, `2`
configuration missing, `3` drift, `4` fetch failure, `5` the bundle is not tracked at the
ref, `64` usage error) with **usage never sharing a code with any other condition**
(CER-015, filed because `deploy.sh` overloads `2` for both); nothing in the check depends on
the page rendering, on the DOM, or on any JavaScript executing (CER-005); and
`scripts/drift-check-selftest.sh` exercises the real script against a fixture git repo and a
local static server for every case in `## Tests`, contacting no host other than `127.0.0.1`.

## Instructions

1. **Write `scripts/drift-check.sh`** (bash, `set -euo pipefail`, `chmod +x`), matching
   `scripts/deploy.sh`'s shape: a header comment block (what it does / usage / exit codes /
   notes), then argument parsing, then configuration, then the work. Usage:
   `drift-check.sh [--ref <git-ref>]`. Default ref `HEAD`. Resolve the repository with
   `git rev-parse --show-toplevel` and `cd` to it — the same seam `deploy.sh` uses, and the
   one that lets the selftest run the real script against a throwaway repo with no test-only
   branch in the script.

2. **Configuration — and the base-URL decision, flagged for the operator.** The check needs
   something `deploy.sh` does not: a base URL to fetch from. Read
   `FORQSITE_HELP_SITE_URL` from the environment, falling back to the gitignored
   `scripts/deploy.env` when unset, exactly as `deploy.sh` reads its two variables; on a
   missing or empty value write to stderr a message naming the variable *name* and saying it
   may be set in the environment or in `scripts/deploy.env`, and exit `2`. Reuse
   `scripts/deploy.env` — do not add a second config file; it is already gitignored, so
   `.gitignore` needs no change.

   *The decision, and why, so it can be overruled:* the site's public hostname is arguably
   not an instance identifier in the sense `docs/ideology.md` § Name the class, not the
   instance is aimed at — it is the published product's public address, and § Cite the source
   that makes a claim checkable draws a comparable line for the product's source tree. But
   that same constraint closes with "nothing here grants a host name, an absolute path or a
   machine name of ours any publication right", and the practical argument is stronger than
   the definitional one: the config surface already exists for `deploy.sh`, so keeping the
   URL in it costs one line of operator setup, and it preserves a **single** rule that a
   `grep` can enforce over the whole tree instead of two rules with a judgment call at the
   boundary — which is the kind of boundary that erodes. **Recommendation: keep the base URL
   out of the tree.** If the operator overrules this, the change is a one-line default and
   nothing else in the script moves. Do not build the overruled version without that word.

3. **Fetch the served bytes** — this is the story. Per bundle, to a temp file in a `mktemp -d`
   scratch directory (never a shell variable — command substitution strips trailing newlines
   and would report a false DRIFT on a correct site):

   ```
   curl --fail --silent --show-error --location=false \
        --header 'Accept-Encoding: identity' \
        --header 'Cache-Control: no-cache' \
        --output "$scratch/$bundle" \
        "$BASE_URL/$bundle"
   ```
   Normalise a trailing `/` off `BASE_URL` before joining. Treat a non-2xx, a 3xx, a
   connection failure, or a timeout as a **fetch failure**: exit `4` with a message naming
   the bundle and the reason, and (for a 3xx) the `Location`, because "the bytes this URL
   returns" is the claim being checked and a redirect means some other URL answered it. Set a
   connect and max time (e.g. `--connect-timeout 10 --max-time 60`) so a hung host fails
   rather than hangs a checkpoint. Then `sha256sum` that file.

4. **Compute the committed side** with `git show "$REF:$bundle" | sha256sum`. If the bundle
   is not tracked at the ref, exit `5` naming the bundle and the ref (a distinct condition
   from drift: there is nothing to compare against).

5. **Name the matching commit.** When a bundle's two hashes differ, walk
   `git rev-list "$REF" -- "$bundle"` newest-first; for each commit take the blob OID
   (`git rev-parse "$commit:$bundle"`), skip OIDs already seen, and compare
   `git cat-file blob <oid> | sha256sum` against the served hash. Stop at the first match and
   report: short sha, committer date, subject, and `git rev-list --count <match>..<REF>`
   as "N commits behind". Also report the ref's own short sha and subject, so the two read as
   one sentence. If the walk completes with no match, print that the served bytes match no
   commit in this history that touched the bundle — stating both readings (hand-edited on the
   host, or deployed from a ref outside this history) — and carry on to the exit-3 drift
   result. A no-match is a real state of the world, not a failure of the check.

6. **`nginx.conf`.** Print one line for it in every report, whatever the result:

   ```
   nginx.conf         not served — bind-mounted only; no request returns its bytes, so this check cannot cover it
   ```
   **Do not** check it over ssh here, and say why in the header comment: an ssh comparison
   would assert a *different and weaker* invariant (the file on the host equals the committed
   file — the very proxy this check forbids for the bundles), and printing it in the same
   report would make the report's own strength ambiguous line by line. It would also make an
   ssh reachability a precondition of a check that otherwise needs only an HTTP client, so
   the check could no longer be run from anywhere the site is reachable. The asymmetry is
   reported, not hidden and not papered over.

7. **Output.** One block, in `deploy.sh`'s flat `label value` style. Shape below; field names
   and layout are the builder's to finalise, the contents are not. Nothing in it may contain
   the base URL, the ssh alias or the remote directory.

   ```
   ref                <40-char>  <short> "<subject>"
   index.html         DRIFT
     served           <sha256>
     committed        <sha256>
     live bytes match <short> 2026-09-05 "<subject>"  (14 commits behind the ref)
   gap-handoff.html   ok  <sha256>
   nginx.conf         not served — bind-mounted only; …
   result             DRIFT — 1 of 2 served bundles does not match the ref
   ```

8. **Exit codes**, documented in the header comment and used consistently: `0` no drift,
   `2` configuration missing, `3` drift detected, `4` fetch failure, `5` bundle not tracked
   at the ref, `64` usage error (unrecognised argument, or `--ref` without a value). `64` is
   `EX_USAGE` and is deliberately outside the `0-5` band the two deploy-path scripts use, so
   no future condition can quietly reuse it — CER-015 was filed precisely because usage and
   missing-config share `2` in `deploy.sh`, and the checkpoint gate will read this script's
   code. Do not repeat that overload. Leave `deploy.sh` alone; CER-015 is its own row.

9. **Never** run `docker`, `docker compose`, `ssh` or `scp`; never parse, grep or render the
   fetched HTML for a version string, a phase marker or any other content signal; never
   consult mtime or size. The only thing read out of the fetched bytes is their sha256.

10. **Write `scripts/drift-check-selftest.sh`** (executable), modelled on
    `scripts/deploy-selftest.sh` — same `report()` helper, `mktemp -d` + `trap cleanup EXIT`,
    a PASS/FAIL line per case and a trailing `N passed, M failed` summary with a non-zero
    exit on any failure. It builds in a temp directory: a fixture git repo with **three**
    commits touching `index.html` (so there is a history to walk and an identifiable "old"
    version) and one for `gap-handoff.html`; a served directory; and a small local static
    server bound to `127.0.0.1` on an ephemeral port, whose URL is passed via
    `FORQSITE_HELP_SITE_URL`. Wait for the port to accept a connection before running a case,
    and shut the server down in `cleanup`. A `python3 -m http.server` subclass is fine here —
    this is a dev-time harness, not the published artifact, so the zero-runtime-dependency
    constraint (which governs the two bundles) is untouched.

    **The harness must be able to serve bytes that differ from the file on disk in the served
    directory** — a handler that returns the contents of a designated fixture file rather
    than the requested path. That is what makes the forbidden-proxy case in `## Tests`
    testable at all: it reproduces, locally, the stale-inode shape where a file-hashing check
    passes and a request-hashing check correctly reports drift.

    No branch in `drift-check.sh` may exist for the sake of this harness.

11. **Do not** edit `docs/architecture.md`, `docs/checkpoints.md`, `docs/ideology.md` or
    `docs/cer/backlog.md` — CONTENT-028 documents this and resolves CER-014. Do not touch
    `scripts/deploy.sh`, either bundle, or any content.

*(Ideology note, resolved inline per the spec-writer procedure's Step 4a: the base-URL
decision in step 2 routes around the § Name the class, not the instance constraint rather
than through it, keeping the identifier out of the tree while flagging the judgment for the
operator. The selftest's local HTTP server is dev-time tooling and does not bear on the
§ Zero runtime dependencies constraint, which governs the two published bundles.)*

*(Proportionality note: `story_class: code`, two new executables, six exit paths, and a
central assertion whose every plausible cheap substitute has to be named and closed — the
length is spent on the forbidden proxies and the failure paths, not on restating the happy
one. Comparable to INFRA-006, its sibling.)*

## Tests

The project has no test suite (`test_command` is `true`), so the acceptance evidence is the
selftest plus one hygiene check. **Run the selftest and paste its full output into the build
note.** It must exercise every case below and report each by name:

```bash
cd /mnt/work/forqsite.help && ./scripts/drift-check-selftest.sh
```

| Case | Setup | Must hold |
|---|---|---|
| match | served bytes == the fixture repo's `HEAD` bytes for both bundles | exit 0; output contains no `DRIFT`; the `nginx.conf` not-served line is present |
| drift, matching commit | serve the **first** commit's `index.html` bytes; `gap-handoff.html` current | exit 3; output names that commit's short sha and subject and the count of commits behind the ref; also names the ref's short sha; `gap-handoff.html` reported ok |
| drift, no matching commit | serve an `index.html` byte-modified from every commit | exit 3; output states the served bytes match no commit in this history, and does **not** present it as a tool error |
| forbidden proxy (stale inode) | the file on disk in the served directory holds the `HEAD` bytes, but the server returns the first commit's bytes | exit 3 — a check that hashed the file on disk would report a match here; this case is the one that proves the check asserts on the request |
| fetch failure | server stopped (or a bundle path made to return 404) | exit 4; message names the bundle and the reason; **not** exit 3 — an unreachable site is not a drift claim |
| missing config | `FORQSITE_HELP_SITE_URL` unset and absent from `deploy.env` | exit 2; message names the variable name; no request attempted |
| usage error | an unrecognised flag | exit 64 — and, asserted explicitly, **not** 2 (CER-015) |

Acceptance: every case passes, and across the captured output of all cases `grep -c` finds
zero occurrences of any hostname other than `127.0.0.1` and zero occurrences of the fixture
URL in the *success* block. Capture stdout+stderr per case rather than letting it stream, so
those greps are possible.

The hygiene assertion, deriving its search terms from history so neither builder nor reviewer
types an identifier (the CONTENT-024 form, as reused by INFRA-006):

```bash
cd /mnt/work/forqsite.help
mapfile -t IDS < <(git show 8bb837b:docs/cer/backlog.md \
  | grep '^| CER-003 ' | grep -o '`[^`]*`' | tr -d '`')
[ "${#IDS[@]}" -eq 3 ] || { echo "FAIL: expected 3 identifiers, got ${#IDS[@]}"; exit 1; }
args=(); for i in "${IDS[@]}"; do args+=(-e "$i"); done
hits=$(grep -Il "${args[@]}" scripts/drift-check.sh scripts/drift-check-selftest.sh \
  docs/stories/INFRA/INFRA-007.md || true)
[ -z "$hits" ] && echo "PASS: no identifier in this story's files" || { echo "FAIL:"; echo "$hits"; }
```

Acceptance: `PASS`. Also confirm by reading that neither new file carries a public hostname,
an absolute deployment path or a host alias in any *other* form — a comment, a default value,
an example invocation or a usage string — since the grep only catches the three known
strings.

Running the check against the real site is **not** part of this story's acceptance. When the
operator runs it for real, the block it prints is the artifact.

## Out of scope

- **Checking `nginx.conf` over ssh.** Ruled out with reasons in Instructions step 6: it would
  assert the weaker file-on-host invariant this check forbids for the bundles, and would make
  ssh reachability a precondition of an HTTP-only check. The asymmetry is reported instead.
  If a config-drift check is wanted later it is its own story, with its own invariant named.
- **Fixing the drift.** This check reports; `scripts/deploy.sh` corrects. A `--fix` that
  shelled into the deploy would make one script both the observer and the actor, and the
  observer would then have a reason to be lenient.
- **Wiring the check into the checkpoint sequence**, and any edit to `docs/checkpoints.md`,
  `docs/architecture.md` or `docs/ideology.md` — CONTENT-028.
- **Resolving CER-009, CER-011, CER-012 or CER-014.** The first three stay filed as harness
  work; CER-014 is resolved by this story landing and that resolution is recorded by
  CONTENT-028, not by an edit made here.
- **Fixing CER-005's render gap**, and anything render-, DOM- or JavaScript-based in this
  check. Sibling content phase.
- **Checking the provenance sidecar** (INFRA-008). When that sidecar exists it is a third
  served artifact with its own equality claim; extending this check to it is that story's
  call, not a hook built speculatively here.
- **Fixing `deploy.sh`'s CER-015 exit-code overload.** That row is its own; this script
  simply does not repeat the mistake.
- **Any change to the published bundles.** This phase carries no content.
