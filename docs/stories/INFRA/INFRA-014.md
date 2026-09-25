---
id: INFRA-014
rail: INFRA
title: Keep the configured destination out of the deploy's transport errors
status: complete
phase: "11"
auth_gated: false
schema_introduces: false
primary_files:
  - scripts/deploy.sh
touches:
  - scripts/deploy-selftest.sh
  - docs/architecture.md
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

`scripts/deploy.sh` now makes nine `ssh "$HOST" ...` calls: backup, copy and verify for each
bundle and for the sidecar, then the marker, listing and prune steps. All of them inherit
stderr. The script's own `echo` lines are clean, but two other sources of text reach the
terminal unfiltered. The first is `ssh` itself, for example `ssh: Could not resolve hostname
<alias>: ...`, `ssh: connect to host <host> port 22: Connection refused`, or
`<user>@<host>: Permission denied (publickey).` The second is the remote shell, for example
`sh: 1: cd: can't cd to <dir>`. That text names the configured alias, the host behind it, and
the remote directory (CER-028). INFRA-009 fixed the same problem in `drift-check.sh`. This story
applies its rule, *replace the value, keep the reason*, to the deploy.

CER-028 was kept separate from CER-020 because capturing `ssh`'s stderr could swallow
interactive prompts. That was measured while writing this spec, on OpenSSH 9.6p1. The test ran
a throwaway paramiko server on 127.0.0.1 and a pty-driven `ssh` with `2>file` and
`</dev/null`:

- The host-key question ("authenticity of host ... can't be established ... (yes/no/
  [fingerprint])?"), the password prompt and the keyboard-interactive prompt were all written
  to the **controlling tty**. The stderr file had none of them. OpenSSH's `read_passphrase`
  opens `/dev/tty` for every prompt that is not an askpass prompt, and it does so even when
  stdin is a pipe, as it is in the copy steps.
- The stderr file held the server banner, `Warning: Permanently added '<host>' ... to the list
  of known hosts.`, and the remote shell's `cd` error.

So redirecting fd 2 leaves authentication interactive. The stderr capture also fixes a
success-path leak that no assertion caught: on a first connection, the `Permanently added`
line names the host even when the deploy works.

`BatchMode=yes`, `-q` and `LogLevel=QUIET` are rejected. BatchMode disables every prompt, and
the phase says the story is not done if interactive authentication breaks. `-q` suppresses the
fatal messages the reason classes are derived from. This story adds no ssh options.

## Requires

- INFRA-010 through INFRA-013 have been merged. `deploy.sh` has the `sq()` helper, alias
  validation, mktemp staging, noclobber backups and the marker/prune retention, and it loads
  config through `read-deploy-env.sh`.
- `deploy-selftest.sh`, `provenance-selftest.sh` and `drift-check-selftest.sh` pass before any
  change is made.

## Ensures

- **No leak on failure.** Every failure path of `deploy.sh` that follows an `ssh` call prints
  no configured value: not the alias, not the host `ssh` resolved from it, and not the remote
  directory. That covers all nine call sites. `ssh`'s captured stderr and the remote shell's
  captured stderr are never printed, whole or in part.
- **Reasons survive.** Each failure still prints the step and file it failed on, which is the
  existing line. It also prints a reason label from a fixed set. The set tells apart at least
  these causes:
  - the host would not resolve;
  - the connection was refused;
  - the connection timed out;
  - host key verification failed;
  - authentication was refused;
  - the remote directory is missing or cannot be entered;
  - each of the script's own remote refusals: no `mktemp`, no `sha256sum`, the backup name
    already exists, the marker name already exists.

  Anything else falls back to a label that names ssh's exit code, or the remote command's.
- **Nothing else changes.** The `ssh` argv is unchanged: no `BatchMode`, `-q`, `LogLevel` or
  any other new option. stdin and the tty are untouched. The local exit codes are unchanged.
- **The success path is clean.** A successful run prints no `ssh` stderr, so the
  `Permanently added` notice never reaches it.
- **The selftest can see a leak.** `deploy-selftest.sh`'s stub ssh emits realistic ssh text
  and remote-shell text that contains the alias in force or the directory in force. A
  precondition check proves that the raw stub text does contain the value.
- **Each case is asserted on its own output.** For each new failure case, the captured
  stdout+stderr of that case contains zero occurrences of the alias in force and the directory
  in force, and it does contain that case's reason label. The existing happy-path hygiene
  check still passes now that the stub prints alias-bearing noise on every call.
- **All three selftests pass deterministically**, to INFRA-013's standard.

Forbidden proxies:
- Deleting the alias and directory with literal substitution (`${err//$HOST/...}`). `ssh`
  prints the resolved `HostName` or IP, not the alias, so substitution passes a test that
  greps for the alias and still leaks the real host.
- Satisfying the grep by printing nothing, or a bare "ssh failed". INFRA-009's rule is to keep
  the reason: a silent or reasonless failure block fails this story.

## Instructions

1. **One wrapper, one call site.** Add a function, for example `run_ssh <remote-cmd>`, that
   runs `ssh "$HOST" "$1"` with **only fd 2** redirected to a file. That file lives in a local
   scratch directory made by `mktemp -d` and removed by an `EXIT` trap. Create the scratch
   directory after the dry-run exit. The wrapper keeps ssh's stdout, so `remote_out="$(...)"`
   and the piped-stdin copy steps work as before, and it returns ssh's exit status. Route all
   nine call sites through it. Afterwards `grep -c 'ssh "\$HOST"' scripts/deploy.sh` is 1.
2. **Classify, never print.** Add a function that reads the captured file and the status and
   emits one label line, for example `deploy.sh: reason: <label>`:
   - **Status 255 means ssh itself failed.** Match `Could not resolve hostname`,
     `Connection refused`, `timed out`, `Host key verification failed` and
     `Permission denied (`, with the parenthesis, which is ssh's auth-failure form. Then fall
     back in two steps. Any other `connect to host` line gets "could not connect to the host".
     Anything else gets "ssh failed before the remote command ran (exit 255)".
   - **Any other status means the remote command failed.** Match the script's own fixed remote
     messages to their labels. Otherwise use "the remote command failed (exit N)".
   - The unmatched labels also say that ssh's own text was withheld because it names the
     configured target. They point to `ssh -v <alias>` by hand as the way to see it, with
     `<alias>` written literally.
   - The labels are fixed strings. Nothing captured is interpolated into them.
3. **Remote directory missing, decided at the source.** In every remote command, change
   `cd $(sq "$DIR") || exit 1` / `&&` to silence `cd`'s stderr and exit with a reserved code.
   The code must be distinct from 1, 5 and 255, and a comment must name it. Map that code to
   the "remote directory is missing or cannot be entered" label. This avoids parsing text
   whose wording depends on which shell the far side runs and on its locale.
4. **Leave the rest alone.** Keep the existing per-step failure lines and the prune-failure
   report. Add the reason line after them. Discard captured stderr on success.
5. **Header comment.** Say that ssh's and the remote shell's stderr are captured and turned
   into reason labels. Say that prompts are unaffected, because OpenSSH writes them to the
   controlling tty. Say that the accepted cost is that server banners and the known-hosts
   notice are not shown. Say that BatchMode was rejected, and why.
6. **Stub ssh (`deploy-selftest.sh`).**
   - Before `shift`, record the alias (`$1`). On every call, have the stub write
     `Warning: Permanently added '<alias>' (ED25519) to the list of known hosts.` to stderr.
   - When a mode file exists, emit that mode's text to stderr, containing the alias or the
     directory in force, and use its exit status without running the command. Use real
     OpenSSH wording, as quoted in § Context:
     - `resolve`, `refused`, `auth` and `hostkey`, each with exit 255;
     - `remote-text`, with exit 1. Use a remote-shell line such as
       `cp: cannot create regular file '<dir>/index.html': Permission denied`.
7. **New selftest cases.** Follow the existing case shape and `report` lines.
   - One case per stub mode, plus a case where the remote directory does not exist. For that
     case, use a path that is never created and run it without a mode file. The dash stub then
     runs the real `cd` failure.
   - Expect exit 5 in each case.
   - For the ssh modes, use an alias that is distinct from `fixture-host-alias`, so the grep is
     unambiguous. Derive the values you grep for from the variables, never from literals.
   - Before each run that can reach the backup step, reset its target with `fresh_target`.
   - Add one precondition check: invoke the stub directly in `resolve` mode, and in
     `remote-text` mode, and assert that its stderr **does** contain the alias and the
     directory.
   - Update the header case list.
8. **`docs/architecture.md` § Deployment.** In the `deploy.sh` bullet, add one sentence at
   class level: failures print a reason class, never ssh's or the remote shell's own text,
   because that text names the configured target. `docs/checkpoints.md` needs no change,
   because no step in it records deploy output.

*(Ideology, Step 4a: this routes around § Name the class, not the instance by never printing
the value. It does not redact the value. § Assert the invariant is kept: the hygiene
assertion proves the stub's text carried the value before it asserts that the output did not.)*

*(Spec-preflight: there are two findings, and both are intentional. `EXIT` is a trap
pseudo-signal, not a constant. `docs/checkpoints.md` is named only to record that it needs no
change, so it stays out of `touches:`.)*

*(Proportionality: nine call sites, a prompt-safety question that had to be measured, and two
forbidden proxies that the obvious fixes walk into. That is where the length goes.)*

## Tests

```bash
cd "$(git rev-parse --show-toplevel)" && ./scripts/deploy-selftest.sh
cd "$(git rev-parse --show-toplevel)" && ./scripts/provenance-selftest.sh
cd "$(git rev-parse --show-toplevel)" && ./scripts/drift-check-selftest.sh
```

Acceptance:
- All three are green. `deploy-selftest.sh` reports the new cases and the precondition check.
  The other two are regression evidence. Paste all three outputs into the build note.
- Run `deploy-selftest.sh` twice in a row, and both runs are green.
- `grep -c 'ssh "\$HOST"' scripts/deploy.sh` prints `1`.
- Reading the classifier confirms that no captured file content reaches stdout or stderr.

## Out of scope

- **Fewer prompts per deploy.** Nine ssh calls can mean nine passphrase prompts without an
  agent. Using `ControlMaster`, or collapsing the calls into fewer, is a separate change.
- **Showing banners or keyboard-interactive instruction text live.** This story accepts that
  they are hidden, and the header records it.
- **CER-015**, which asks that bad usage get an exit code distinct from `2`. Exit codes are
  unchanged here.
- **`drift-check.sh`**, which INFRA-009 and INFRA-010 cover. Also **resolving CER-028's
  backlog row**, which is the orchestrator's merge bookkeeping.
