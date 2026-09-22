---
id: INFRA-011
rail: INFRA
title: Make the deploy's remote command safe to construct
status: complete
phase: "11"
auth_gated: false
schema_introduces: false
primary_files:
  - scripts/deploy.sh
touches:
  - scripts/deploy-selftest.sh
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

The CP-11 security audit filed two findings against how `scripts/deploy.sh` builds its `ssh`
calls. CER-019: the configured alias is passed to `ssh` as its first argument unvalidated, so a
value beginning with `-` (e.g. `-oProxyCommand=...`) is parsed as an option — local command
execution before any connection. CER-025: every value interpolated into the remote command is
quoted with bash's `printf '%q'`, which emits bash-only `$'...'` quoting for some inputs (a tab,
a newline, other non-printables); the far account's login shell may be POSIX `sh`, where that
quoting silently stops protecting the command. The operator pulled both into Phase 11 round 2.
This story is only alias validation and POSIX-safe quoting; INFRA-012 (staging/backups) and
INFRA-014 (transport errors) change `deploy.sh` after it, and INFRA-013 replaces the config
loader.

## Requires

- INFRA-010 merged (phase doc § Story ordering: round-2 stories build in table order).
- `dash` installed on the build host (`command -v dash`); the selftest uses it as the stand-in
  far shell.

## Ensures

`deploy.sh` refuses, with exit 2, a message naming `FORQSITE_HELP_DEPLOY_HOST` but not its value,
and no `ssh` invocation (dry run included), any alias not matching
`^[A-Za-z0-9._][A-Za-z0-9._-]*$`; `grep -c "printf '%q'" scripts/deploy.sh` is `0` and every value
spliced into a remote command goes through one POSIX single-quote helper; and
`scripts/deploy-selftest.sh`, whose stub `ssh` now runs the remote command under `dash`, passes
all its existing cases plus a hostile-alias case and a happy-path deploy into a directory whose
name contains a space, a single quote and a tab (forbidden proxy: a stub that runs the command
under `bash`, where `$'...'` works and the old quoting would pass too).

## Instructions

1. **Alias validation.** Immediately after the configuration block resolves `HOST` and `DIR`
   (and before the dirty check, the dry-run branch, or any `ssh`), test `HOST` against
   `^[A-Za-z0-9._][A-Za-z0-9._-]*$` with bash `[[ =~ ]]`. On failure print to stderr that
   `FORQSITE_HELP_DEPLOY_HOST` is not a valid ssh alias (letters, digits, `.`, `_`, `-`; may not
   begin with `-`) and exit 2. Never echo the value — the naming rule and INFRA-014's intent
   both forbid it. Do not add `--` to the `ssh` calls: validation is the fix, and the
   selftest's stub treats its first argument as the alias.
2. **POSIX quoting.** Add one helper that wraps a value in single quotes and renders each
   embedded `'` as `'\''` — e.g. `sq() { local s=${1//\'/\'\\\'\'}; printf "'%s'" "$s"; }`
   (checked under `dash` with a value holding a space, tab, `'` and trailing newline: bytes
   round-trip exactly). Replace every `$(printf '%q' ...)` in the six remote command strings
   with it. Existing values behave the same — `%q` already escaped `~`, so tilde expansion did
   not happen before and still does not.
3. **Selftest.** In `scripts/deploy-selftest.sh`:
   - change the stub `ssh` to run its command with `dash -c` instead of `bash -c`, and fail the
     selftest loudly (not skip) if `dash` is absent;
   - add case "hostile alias": `FORQSITE_HELP_DEPLOY_HOST='-oProxyCommand=touch <marker>'` →
     exit 2, stub-ssh marker absent, `<marker>` absent, output does not contain the value; repeat
     with `--dry-run` and with an alias containing a space;
   - add case "POSIX quoting": point `FORQSITE_HELP_DEPLOY_DIR` at a fixture directory named with
     a space, a `'` and a tab (pre-populated like case 3) → exit 0 and both bundles match the
     committed bytes. Confirm by hand once that this case fails against the pre-change
     `deploy.sh` under the `dash` stub, and say so in the build note.
   - update the header comment's case list.
4. Update `deploy.sh`'s header to note the alias constraint under exit code 2.

Ideology check: no conflict. Refusal messages name the variable, never the value (§ Name the
class, not the instance); the selftest asserts the far-shell property itself under a real POSIX
shell rather than a bash proxy (§ Assert the invariant, not a proxy for it).

Spec-preflight note: its four constant warnings (`HOST`, `DIR`, `FORQSITE_HELP_DEPLOY_HOST`,
`FORQSITE_HELP_DEPLOY_DIR`) are false positives — all are shell variables already defined in
`scripts/deploy.sh`'s configuration block.

## Tests

No test suite exists (`test_command` is `true`); the selftest is the acceptance evidence. Paste
its full output into the build note.

```bash
cd /mnt/work/forqsite.help && ./scripts/deploy-selftest.sh
grep -c "printf '%q'" scripts/deploy.sh   # expect 0
bash -n scripts/deploy.sh && bash -n scripts/deploy-selftest.sh
```

Acceptance: selftest reports every case PASS (the five existing plus the two new ones), `0`
from the grep. "A configuration that deploys today still deploys" is checked without printing
the value — run from the main project directory, where the gitignored config lives:

```bash
cd /mnt/work/forqsite.help && ( h="${FORQSITE_HELP_DEPLOY_HOST:-}"; [ -z "$h" ] && [ -f scripts/deploy.env ] && h="$(. scripts/deploy.env; printf '%s' "${FORQSITE_HELP_DEPLOY_HOST:-}")"
  if [ -z "$h" ]; then echo "NOT CONFIGURED HERE"; elif [[ "$h" =~ ^[A-Za-z0-9._][A-Za-z0-9._-]*$ ]]; then echo PASS; else echo FAIL; fi )
```

Acceptance: `PASS`, or `NOT CONFIGURED HERE` recorded in the build note for the operator to
confirm. `FAIL` means the class is wrong for a live config and the story stops for the operator.

## Out of scope

- Staging names and backup retention (INFRA-012), the config loader and `source` (INFRA-013),
  and redacting `ssh`'s own stderr (INFRA-014).
- Validating `FORQSITE_HELP_DEPLOY_DIR`'s shape: it is now quoted safely for any content, which
  is this story's claim; restricting its character set is not.
- `user@host` or `host:port` forms — the configuration is an ssh alias (INFRA-006); a login or
  port belongs in the operator's ssh config.
- `scripts/drift-check.sh`, which makes no `ssh` call.
