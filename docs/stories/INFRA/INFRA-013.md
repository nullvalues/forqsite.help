---
id: INFRA-013
rail: INFRA
title: Read the deploy config as data, never execute it
status: complete
phase: "11"
auth_gated: false
schema_introduces: false
primary_files:
  - scripts/deploy.sh
  - scripts/drift-check.sh
  - scripts/read-deploy-env.sh
touches:
  - scripts/deploy-selftest.sh
  - scripts/drift-check-selftest.sh
  - scripts/provenance-selftest.sh
  - scripts/deploy.env.example
  - docs/architecture.md
narrative_roles: []
---

## Context

CER-024: `scripts/deploy.sh` and `scripts/drift-check.sh` both `cd` to the root of the
repository that contains the caller's cwd. When the environment does not supply their
settings, they then `source scripts/deploy.env`. So running either script from inside an
untrusted clone that ships a `scripts/deploy.env` executes that file. The phase doc chose
the fix: parse the file as `KEY=value` data. It did not choose the other option, refusing a
repo root that is not the script's own. That option would break every selftest, because
each one runs this repository's scripts with cwd in a fixture repo. The file's location
stays where it is. Only the way the file is read changes. One parser serves both scripts.
It lives in a new helper, `scripts/read-deploy-env.sh`, sourced from the script's own
directory, so it has the same trust as the script itself. The alternative was two copies
of the same security-relevant parsing, which could drift apart. INFRA-010, INFRA-011 and
INFRA-012 have already changed both scripts. This story builds on that code. INFRA-014 then
builds on the new loader.

## Requires

- INFRA-010, INFRA-011 and INFRA-012 merged (complete).
- `dash` on the build host (`deploy-selftest.sh`'s stub remote shell).

## Ensures

After this story:

- Neither script sources, evaluates or executes `scripts/deploy.env`. Both read it through
  the shared parser in `scripts/read-deploy-env.sh`. That parser accepts these lines:
  - blank lines;
  - lines whose first non-blank character is `#`;
  - `[export ]KEY=value` lines where `KEY` is one of `FORQSITE_HELP_DEPLOY_HOST`,
    `FORQSITE_HELP_DEPLOY_DIR` or `FORQSITE_HELP_SITE_URL`.

  Both scripts accept all three keys, because they share one file.
- A value can take one of three forms: a double-quoted string, a single-quoted string, or a
  bare token with no whitespace and no quote characters. The value is taken literally.
  `$(...)`, backticks and `$VAR` in the file stay literal text and are never expanded.
- Any other line makes the script exit 2 before any network contact. The message names the
  line number and not the line's content, so no part of the value is printed.
- Precedence is unchanged, in both scripts:
  - The file is opened only when the environment is missing at least one of that script's
    required values. If the environment supplies them all, a malformed file is never read
    and is not an error.
  - When the file is read, a non-empty value from the file replaces the environment's value
    for that key. An empty or absent key leaves the environment's value in place. This is
    exactly what `source` followed by `${VAR:-$prev}` did.
- `deploy-selftest.sh`, `drift-check-selftest.sh` and `provenance-selftest.sh` all pass. The
  first two gain file-read cases for these points.
- Every assignment line in `scripts/deploy.env.example`, once uncommented and filled in,
  parses cleanly.
- Added after attempt 1's review (2026-09-22): the selftests pass *deterministically*. INFRA-012
  refuses a deploy whose one-second backup stamp already exists in the target, so no two
  `deploy.sh` runs in `deploy-selftest.sh` may hit the same target directory unless the target
  is reset between them (`fresh_target`, or clearing its `.bak-*` and `.deploy-verified-*`),
  or the test is expressly asserting that refusal. Every consecutive pair of deploy calls in the
  file, old cases included, is checked for this, not only the new ones.

Forbidden proxies:
- Removing the literal word `source` while the parser still hands file text to `eval`,
  `declare`, `export "$line"`, `printf -v "$key_from_file"` with an unvalidated key, or any
  other evaluator. The `printf -v` target must come from the fixed allowlist.
- A test that asserts only "the script exited non-zero" on a command-substitution payload.
  The evidence is that the payload's marker file does not exist afterwards.

## Instructions

1. **`scripts/read-deploy-env.sh`** (new; function definitions only, with no top-level side
   effects, not executable). Define one function, such as `read_deploy_env <file> <caller>`.
   It reads the file line by line with `while IFS= read -r line || [ -n "$line" ]`, strips
   one trailing `\r`, and applies the grammar in Ensures with bash `[[ =~ ]]`.
   - For an accepted key, store the literal value in a variable named from the allowlist.
     Duplicates: last one wins, as with `source`.
   - For any other line, print `<caller>: scripts/deploy.env line <N> is not a KEY=value
     line for a known key` to stderr and return 2.
   - Use no `eval`, `source`/`.`, or unquoted expansion of file text.
   - State in a header comment why the file is read as data (CER-024).
2. **Both scripts.** Resolve `SELF_DIR` from `BASH_SOURCE[0]` *before* `cd "$REPO_ROOT"`.
   `deploy.sh` already does this. `drift-check.sh` needs it added. Source
   `"$SELF_DIR/read-deploy-env.sh"`, never anything under `$REPO_ROOT`. Replace each
   `source "scripts/deploy.env"` block with a call to the parser, keeping the precedence in
   Ensures, and exit 2 if the parser refuses the file. Leave the existing missing-config
   message and the alias validation unchanged. In each header, update the "Reads ...
   configuration" bullet (read as `KEY=value` data, never executed) and the exit-2 line
   (configuration missing *or unreadable*).
3. **`scripts/deploy.env.example`.** Add one header sentence on the format: `KEY=value`,
   quotes optional, contents literal (`$` is not expanded), and any other non-comment line
   is refused. The placeholders stay as they are.
4. **Selftests.** The fixture repo may have no `scripts/` directory, so create it. Write the
   fixture `deploy.env` with env unset for the keys under test, and remove it after each
   case. Put marker files under `$WORK_DIR`. Add:
   - **`deploy-selftest.sh`:**
     - (a) A file in the example's form, meaning double-quoted HOST and DIR, a comment, a
       blank line and a SITE_URL line, plus one single-quoted and one bare value across
       runs. Expect exit 0 and the bytes landed in the target.
     - (b) DIR, and separately SITE_URL, set to `"$(touch M1)"` and `` `touch M2` `` in
       double quotes. Expect M1 and M2 absent, whatever the exit code.
     - (c) Line 3 is `touch M3`. Expect exit 2, output contains `line 3`, output does not
       contain `touch`, M3 absent, and ssh never invoked.
     - (d) Line 2 is `UNKNOWN_KEY=<distinct value>`. Expect exit 2, `line 2` named, and the
       value not printed.
     - (e) Env HOST and DIR both set, and a malformed file present. Expect exit 0.
     - (f) Env DIR set to a nonexistent path, HOST unset, and the file sets both. Expect
       exit 0 into the file's DIR (the precedence is pinned).
   - **`drift-check-selftest.sh`:** the equivalents of (a) with URL, (b), (c) and (e).

   Update both headers' case lists. `provenance-selftest.sh` should need no change. Run it
   to confirm.
5. **`docs/architecture.md`** § Deployment, "Configuration surface": add one sentence saying
   the file is parsed as `KEY=value` data for the known keys, never executed, and any other
   line is refused by line number. Use class language only.

Ideology check: no conflict. The refusal names a line number and never the content, so no
configured value reaches output (§ Name the class, not the instance). The tests assert the
invariant, which is that the payload never ran (marker absent), not a proxy for it such as
an exit code or grepping the source for `source` (§ Assert the invariant, not a proxy for it).

Spec-preflight note: its constant warnings are intentional. The three `FORQSITE_HELP_*`
names are environment and config keys, and `SELF_DIR` is an existing shell variable in
`deploy.sh`. `KEY` is grammar notation.

*(Proportionality: this story covers two scripts, a new shared helper and two selftests,
plus a precedence rule that must be pinned exactly. The case list is most of the length.)*

## Tests

There is no test suite (`test_command` is `true`). The selftests are the acceptance
evidence. Paste their full output into the build note.

```bash
cd /mnt/work/forqsite.help && ./scripts/deploy-selftest.sh && ./scripts/drift-check-selftest.sh && ./scripts/provenance-selftest.sh
bash -n scripts/deploy.sh scripts/drift-check.sh scripts/read-deploy-env.sh
grep -nE 'source[[:space:]]+"?scripts/deploy\.env|\beval\b' scripts/deploy.sh scripts/drift-check.sh scripts/read-deploy-env.sh   # expect no output
```

Acceptance:
- all three selftests report every case PASS, including the new ones;
- the grep prints nothing;
- the build note confirms, by hand and once, that case (b) or (c) fails against the
  pre-change `deploy.sh`, meaning the marker is created.

## Out of scope

- Moving the config file out of the caller's repo root, or refusing a repo root that is not
  the script's own. The file stays where it is. Only how it is read changes.
- Changing the precedence between environment and file, or making `BACKUP_KEEP` or any other
  constant configurable.
- Validating value shapes beyond the grammar. The alias check stays in `deploy.sh` (INFRA-011),
  and the scheme restriction stays in `drift-check.sh` (INFRA-010).
- File ownership or permission checks on `scripts/deploy.env`.
- Redacting `ssh`'s stderr on transport failures (INFRA-014).
- `docs/checkpoints.md`. Its only reference is "run `scripts/drift-check.sh` and record the
  result", which this story does not change.
