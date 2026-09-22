---
id: INFRA-009
rail: INFRA
title: Keep the configured destination out of a failing drift check's output
status: draft
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

`scripts/drift-check.sh` (INFRA-007) prints curl's stderr verbatim when a fetch fails, and
curl's error text embeds the destination. Observed live by the CP-11 auditor:

```
drift-check.sh: fetch failed for index.html: curl: (7) Failed to connect to 127.0.0.1 port 1 after 0 ms: Couldn't connect to server
```

Against a real configuration that line names the real host and port. A second path prints the
redirect target on a 3xx, which is origin-controlled and may itself be anything.

This is not a generic nit here. `docs/checkpoints.md`, added by CONTENT-028 in this same
phase, instructs the operator to run the drift check by hand and record its exit code and
result block in that phase's checkpoint section — a committed, public file. So the phase built
a procedure that publishes the value the operator ruled on 2026-09-22 must stay out of the
tree (`docs/ideology.md` § Name the class, not the instance; the ruling's extension to the
site URL is CONTENT-029's subject, not this story's). It shipped because INFRA-007's hygiene
assertion scoped its guarantee to the *success* block only — the block an operator actually
pastes on a failing run was never tested. Backlog row: CER-020.

## Requires

- INFRA-007 complete: `scripts/drift-check.sh` and `scripts/drift-check-selftest.sh` exist and
  the selftest's seven cases pass before any change is made.
- `scripts/deploy-selftest.sh` and `scripts/provenance-selftest.sh` pass before any change is
  made, so a post-change failure in either is attributable.

## Ensures

Every failure path of `scripts/drift-check.sh` — connection failure, timeout, non-2xx, 3xx
redirect, and the provenance sidecar fetch's own failures — prints no configured value: not
the base URL, not a host derived from it, not a port derived from it, and not the
origin-supplied redirect target; each still prints a reason that distinguishes a connection
refusal from a timeout from a non-2xx from a redirect (forbidden proxy: collapsing them to a
bare "fetch failed", or satisfying the hygiene grep by printing nothing at all — a silent
failure block passes the grep and fails this story); `scripts/drift-check-selftest.sh` asserts
that absence in at least a connection-failure case, a non-2xx case and a redirect case, each
against that case's own captured stdout+stderr; and the exit codes, the byte-level served-vs-
committed comparison and every forbidden-proxy clause of INFRA-007 are unchanged.

## Instructions

1. **Redact by placeholder, in `fetch_bundle`.** Keep `local url="${BASE_URL}/${bundle}"` for
   the request; introduce a display-only form for messages that substitutes a fixed token for
   the configured part — e.g. `<site>/${bundle}`. The bundle name is a repository constant and
   stays; only the configured prefix is replaced.

2. **The `status -ne 0` branch (connection failure, timeout, TLS, resolution).** Do not `cat`
   the `.curlerr` file, and do not print it in any other form. Print curl's own exit code plus
   a short label mapped from it — at minimum `6` could-not-resolve-host, `7` failed-to-connect,
   `28` timed-out, with a default label for anything else that names the code and points at
   `curl(1)`. curl's exit code carries the whole distinction this story must preserve and
   embeds no destination. The `.curlerr` file may keep being written (it is inside the
   `mktemp -d` scratch that `cleanup` removes); it must not reach stdout or stderr.

3. **The `3??` branch.** Print the HTTP status code and the fact that the response was a
   redirect. Do **not** print `${redirect_url}`: it is origin-controlled, and on the failure
   this check is most likely to meet it is the configured origin echoing itself back. Say in
   the message that the target is withheld, so a reader knows the omission is deliberate.

4. **The `*)` branch** already prints only `HTTP ${http_code}`; leave its content alone. Apply
   the same `<site>` placeholder if the message is reworded.

5. **`fetch_provenance`.** It currently returns non-zero silently and the caller prints a fixed
   line, so nothing leaks today. Keep it that way explicitly: if any diagnostic is added there,
   it uses the same exit-code-plus-placeholder form. Its `.curlerr` file is likewise never
   printed.

6. **Change nothing else in the script.** Not the exit codes (`4` remains the single fetch-
   failure code for all four shapes), not the sha256 comparison, not the commit walk, not the
   sidecar's report-only role, not the `nginx.conf` line.

7. **Extend the selftest's fixture server** with a redirect control, matching the existing
   `404-<name>` / `override-<name>` shape: when `$CONTROL_DIR/redirect-<name>` exists, answer a
   request for `/<name>` with a 302 and that file's contents as `Location`. Use a target that is
   *not* the fixture URL, so the case proves the target is withheld rather than proving the
   base URL happens to be absent.

8. **Add two failure cases and the hygiene assertion**, in the existing case shape (`reset_control`,
   capture `out_caseN` with `2>&1`, `report` a named PASS/FAIL line):
   - **connection failure** — set `FORQSITE_HELP_SITE_URL` to an ephemeral 127.0.0.1 port with
     nothing listening (allocate it with the same python one-liner the port setup uses, and do
     not start a server on it); expect exit 4.
   - **redirect** — `$CONTROL_DIR/redirect-index.html`; expect exit 4.
   - The existing 404 case (case 5) is the non-2xx case; do not duplicate it.

   For each of those three cases assert that the captured output contains **zero** occurrences
   of the configured base URL in force for that case, of the host `127.0.0.1`, and of that
   case's port. Derive all three from the variables the selftest already holds — never type a
   literal. If the bare-port grep proves ambiguous against a failure block that legitimately
   contains digits, narrow it to the port with its `:` prefix and leave a one-line comment
   saying why. Also assert each case's output still names its distinguishing reason (the curl
   exit code or label for the connection failure; the 3xx status for the redirect; `404`/`HTTP`
   for the non-2xx) — this is the half of the Ensures that a pure-suppression "fix" would fail.

9. **Timeout is not a selftest case**, deliberately: `--max-time 60` makes it a minute-long test
   for no additional coverage, since it enters the same `status -ne 0` branch as the connection
   failure and differs only in the exit-code label. Note this in a comment beside the connection-
   failure case so a reviewer does not read it as an omission.

10. **Update the selftest header's case list** to include the new cases, and update
    `drift-check.sh`'s header note about redirects (which currently says the `Location` is
    reported) so the comment matches the behaviour.

*(Ideology note, Step 4a: the fix routes around § Name the class, not the instance rather than
through it — the configured value stays out of the printed block entirely instead of being
printed under a caveat. § Assert the invariant, not a proxy for it is preserved by Instruction
6: nothing about what the check asserts changes here.)*

*(Spec-preflight note: the scan reports two constant warnings and no `scope:` finding. Both
warnings are intentional — `FORQSITE_HELP_SITE_URL` is an environment/config variable name with
no in-tree definition by design (INFRA-007 recorded the same warning), and `HTTP` is a word in
an output message, not a constant.)*

*(Proportionality note: `story_class: code`, two files, five failure paths each needing a named
diagnostic that survives redaction, plus a forbidden proxy — "print less" — that the obvious
fix walks straight into. The length is spent there.)*

## Tests

```bash
cd /mnt/work/forqsite.help && ./scripts/drift-check-selftest.sh
cd /mnt/work/forqsite.help && ./scripts/deploy-selftest.sh
cd /mnt/work/forqsite.help && ./scripts/provenance-selftest.sh
```

Acceptance: all three green. `drift-check-selftest.sh` reports its original seven cases plus
the connection-failure and redirect cases, and the per-case hygiene assertion passes for the
connection-failure, non-2xx and redirect cases. The other two selftests are regression evidence
— this story touches neither script, so anything but green there is a finding. Paste all three
outputs into the build note.

Then, with the selftest's fixture URL still in mind, confirm by reading that no failure-path
message in `scripts/drift-check.sh` interpolates `BASE_URL`, `$url`, or `redirect_url` into
anything written to stdout or stderr.

## Out of scope

- **`scripts/deploy.sh`'s failure paths — checked, and they do leak, but not here.** Its own
  `echo` lines name only the bundle (`deploy-selftest.sh` already asserts the success block is
  clean), yet its six `ssh` invocations run with inherited stderr, so `ssh`'s own failure text
  ("could not resolve hostname `<alias>`") and the remote shell's (`cd: <dir>: No such file or
  directory`) reach the terminal unfiltered — the alias and the remote directory both. It is a
  **separate row**, for two reasons stated rather than silently widened into this story: the
  forcing function differs — nothing directs an operator to paste deploy output into a committed
  file, which is the whole reason CER-020 is being fixed inside the phase instead of deferred —
  and the fix shape differs, since capturing `ssh`'s stderr changes its interactive behaviour
  (password and host-key prompts), which is a design question this story has no room to decide.
  Recommend filing it as a new CER row; this story files nothing (`docs/cer/backlog.md` is not
  in `touches:`).
- **CER-021, CER-023, CER-024** — the other CP-11 findings against these two scripts
  (`--max-filesize`/`--proto`, remote staging, `source`-ing config). Backlog, untouched here.
- **`docs/ideology.md`, `README.md`, `docs/architecture.md` and the URL scrub** — CONTENT-029.
  This story changes no documentation.
- **Wiring the hygiene assertion into any gate.** It lives in the selftest, run by hand like
  the rest of this phase's evidence.
