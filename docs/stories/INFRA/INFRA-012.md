---
id: INFRA-012
rail: INFRA
title: Stage deploys unpredictably and bound the backups they leave
status: complete
phase: "11"
auth_gated: false
schema_introduces: false
primary_files:
  - scripts/deploy.sh
touches:
  - scripts/deploy-selftest.sh
  - scripts/provenance-selftest.sh
  - docs/architecture.md
narrative_roles: []
---

## Context

The CP-11 security audit filed two findings against how `scripts/deploy.sh` writes on the far
side. CER-023: each file is staged at a predictable name (`.<name>.deploy-<one-second
stamp>.tmp`) opened with `cat >`, which follows a pre-planted symlink, so another account with
write access to the remote directory could redirect the bytes. The backup write
(`cp -p <name> <name>.bak-<stamp>`) has the same flaw, because the name is predictable and the
write follows the destination. CER-027: every deploy leaves one backup set (`index.html`,
`gap-handoff.html`, `site-provenance.json`, each `.bak-<stamp>`) and nothing is ever pruned.
The operator pulled both findings into Phase 11 round 2. The phase doc's "Not done if" is
binding: pruning must never remove the rollback copy of a deploy that failed verification, or
the backup the current deploy just made. INFRA-011 already added the `sq()` POSIX quoting
helper and moved the selftest's stub remote shell to `dash`. This story uses both and redoes
neither.

## Requires

- INFRA-011 merged (`sq()` present in `scripts/deploy.sh`; `deploy-selftest.sh` stub runs under
  `dash`).
- `dash` and `mktemp` on the build host.

## Ensures

After this story, `scripts/deploy.sh` makes no remote write through a predictable name that
could follow a symlink. Each staging file is created by a remote `mktemp`: the name is
unpredictable and the file is created exclusively. Each `.bak-<stamp>` backup is refused if its
name already exists in any form, including a dangling symlink, and is otherwise written with
noclobber. After both bundles and the sidecar have verified, and only then, the deploy writes a
`.deploy-verified-<stamp>` marker and prunes verified backup sets beyond `BACKUP_KEEP=5`, a
constant stated in the header. The set this deploy just made is always kept, and so is any set
without a marker (a failed deploy's rollback copy, or a set older than this story).
`deploy-selftest.sh` and `provenance-selftest.sh` both pass. The deploy selftest includes new
cases proving three things:
- a symlink planted at every old-scheme staging or backup name for the run's time window is
  never written through;
- retention with future-dated verified sets keeps the current set;
- a hash-mismatch run deletes nothing and writes no marker.

Added after attempt 1's review (2026-09-22):
- **A file created for the first time is world-readable.** When a bundle or the sidecar does not
  yet exist on the far side (a fresh target directory, or the first deploy that ships
  `site-provenance.json`), the file the deploy creates has mode 0644. It must not inherit the
  `mktemp` stage's 0600 through `cp`. The container's web server may run as a different uid and
  must be able to read it. An existing file keeps its inode and its mode, unchanged. A deploy
  selftest case creates a destination that did not exist before and asserts its mode is 0644.
  Forbidden proxy: an unconditional `chmod` on the live file. On an existing destination it
  would overwrite a mode the operator set on purpose.
- **A prune report says what was pruned.** If pruning fails partway through, the output names
  which stamps were removed before the failure and which one failed. It never prints a blanket
  "no backups pruned" once any removal succeeded. A deploy selftest case makes the second of two
  prune removals fail and asserts the first stamp is reported as pruned. Forbidden proxy: a
  message reworded to say nothing about which sets remain.

Forbidden proxies: pruning that simply keeps the newest N stamps by sort order, which drops the
current set under clock skew and can drop a failed deploy's rollback copy; and a staging name
made "random" locally, such as `$RANDOM` or `date +%N`, while the far side still opens it with
a plain `>`.

## Instructions

1. **Staging (CER-023).** For each of the three files, the copy step's remote command creates
   the stage with `mktemp` in the remote directory, using a template that keeps the file's name
   and ends in at least ten `X`s (e.g. `./.index.html.deploy-XXXXXXXXXX`; GNU, BSD and busybox
   all accept that form). It then writes stdin into the stage, `cp`s the stage over the live
   file in place (the bind-mount inode rule is unchanged: never `mv` over a live file), and
   removes the stage whether the steps succeed or fail. If `mktemp` is missing on the far side,
   fail with that as the message, the same way the missing-`sha256sum` case does (exit 5).
   Keep the literal `cat >` in the copy command and keep the file's name in the template.
   `deploy-selftest.sh`'s corrupt hook and `provenance-selftest.sh`'s `FAIL_GAP_COPY` hook both
   match on those strings. If you must change the command shape, update both stubs so each hook
   still fires on the copy step only.
2. **Backups.** Replace `cp -p <name> <bak>` with: if `<bak>` exists, or is a symlink
   (`[ -e ] || [ -L ]`), fail (exit 5, naming the file, not the directory). Otherwise
   `set -C; cat <name> > <bak>`, so that a name appearing between the check and the write
   makes the write fail instead of following it. Losing `-p`'s timestamps is accepted, because
   the stamp is in the name.
3. **Retention (CER-027).** Add `BACKUP_KEEP=5` near the top. After the sidecar verifies
   (never on any failure path, and never in `--dry-run`, which only prints that verified sets
   beyond 5 would be pruned):
   - create `.deploy-verified-$STAMP` with noclobber;
   - list the far side's `.deploy-verified-*` names over one `ssh`;
   - locally, keep only the names whose stamp matches `^[0-9]{8}T[0-9]{6}Z$`. Treat the
     listing as untrusted and ignore any other name;
   - drop `$STAMP`, then sort the remaining stamps and keep the newest `BACKUP_KEEP - 1`;
   - for each other stamp, remove exactly `index.html.bak-S`, `gap-handoff.html.bak-S`,
     `site-provenance.json.bak-S` and `.deploy-verified-S` in one `ssh`, every name through
     `sq()` and `rm -f --`. Use no glob in the `rm`.
   If the marker or prune step fails, exit 5 with a message saying the files verified and no
   backups were pruned. Add a `pruned` line to the success block listing the pruned stamps, or
   `none`. Stamps are not configuration values, so printing them is allowed.
4. **Header.** Document the `mktemp` staging, noclobber backups, `BACKUP_KEEP`, the marker, and
   the rule that sets without a marker are never pruned and may be removed by hand. Also state
   the precondition in class terms: the remote directory should be writable only by the deploy
   account. The script narrows the symlink race but does not make a shared directory safe.
5. **`deploy-selftest.sh`.** Add these cases and update the header's case list:
   - **staging/backup symlinks:** create a sentinel file outside the target. Before the run,
     plant symlinks to the sentinel at every old-scheme stage name (`.<name>.deploy-<S>.tmp`)
     for each second `S` from now to now+10s, for all three files. Run → exit 0, bytes match,
     sentinel unchanged, and no `.*.deploy-*` stage left in the target. Separately, plant a
     symlink at `index.html.bak-<S>` for the same window → exit 5, sentinel unchanged.
   - **retention:** clear the target of backups and markers. Seed six verified sets with past
     stamps and `BACKUP_KEEP` verified sets dated in 2099. Also seed one unverified set (backup
     files, no marker) with the oldest stamp of all, and one marker whose name fails the stamp
     pattern. Run → exit 0. Afterwards:
     - the current set and its marker exist;
     - exactly `BACKUP_KEEP` markers match the pattern;
     - every pruned stamp's files are gone;
     - the unverified set and the malformed marker are untouched.
   - **no prune on failure:** seed as above, then run with `CORRUPT_FLAG` → exit 4, every seeded
     file still present, and no marker for the run's stamp.
6. **`docs/architecture.md` § Deployment**, the `deploy.sh` bullet: add one sentence on
   retention (verified sets bounded to a stated count; unverified sets kept) and one on the
   remote-directory ownership precondition. Use class language only, with no host name and no
   path.

Ideology check: no conflict. Output names stamps and file names, never the alias or directory
(§ Name the class, not the instance). The retention and staging tests assert the property
itself — a sentinel that was not written, a set that survived — rather than a proxy such as
"the command string contains mktemp" (§ Assert the invariant, not a proxy for it).

Spec-preflight note: its three constant warnings are intentional. `BACKUP_KEEP` is defined by
this story. `CORRUPT_FLAG` and `FAIL_GAP_COPY` are shell variables that already exist in
`deploy-selftest.sh` and `provenance-selftest.sh`.

*(Proportionality note: this story touches one script and its two selftests, and fixes two
findings, one of which has a binding "Not done if" that needs its own adversarial cases. The
extra length is those cases.)*

## Tests

No test suite exists (`test_command` is `true`). The selftests are the acceptance evidence.
Paste their full output into the build note.

```bash
cd /mnt/work/forqsite.help && ./scripts/deploy-selftest.sh && ./scripts/provenance-selftest.sh
bash -n scripts/deploy.sh && bash -n scripts/deploy-selftest.sh
grep -nE '\.deploy-\$\{?STAMP|cp -p' scripts/deploy.sh   # expect no output
```

Acceptance:
- both selftests report every case PASS, including the three new ones;
- the grep prints nothing;
- the build note confirms by hand, once, that the staging-symlink case fails against the
  pre-change `deploy.sh`.

## Out of scope

- A restore or rollback mode. Backups stay a manual resource (INFRA-006 § Out of scope).
- Making `BACKUP_KEEP` configurable. It is a stated constant. Configuration keys are
  INFRA-013's loader's business.
- Pruning backup sets without a marker, including sets older than this story. They are kept by
  design, and the operator removes them by hand.
- Hardening the live bundle files themselves against a hostile co-tenant of the remote
  directory. The ownership precondition is stated, not enforced.
- The config loader (INFRA-013) and redacting `ssh`'s stderr (INFRA-014).
