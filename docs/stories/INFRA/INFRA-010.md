---
id: INFRA-010
rail: INFRA
title: Make the drift check's output and fetches safe against a hostile origin
status: complete
phase: "11"
auth_gated: false
schema_introduces: false
primary_files:
  - scripts/drift-check.sh
touches:
  - scripts/drift-check-selftest.sh
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

`scripts/drift-check.sh` treats the origin it checks as trustworthy in two places the CP-11
security audit found. **CER-026:** the provenance sidecar's four fields (`repo_commit`,
`deployed_at`, and the two per-bundle sha256 claims) are pulled out with `sed` patterns that
exclude only `"`, then printed straight into the report block, so an origin can put ANSI escape
sequences, carriage returns or other control bytes into the block the operator reads and then
pastes into a committed checkpoint record. **CER-021:** neither `curl` call sets
`--max-filesize` or `--proto`, so an origin can stream into the scratch directory for the whole
60-second budget, and a `file://` base URL is accepted. That turns the check into a local-file
reader that reports `ok` against planted files. Both are fixed here without weakening what the
check asserts. Every decision is still made on the raw bytes, and sanitising only ever touches
what is printed.

## Requires

- INFRA-009 and CONTENT-029 complete (round-2 order, phase doc § Story ordering).
- `scripts/drift-check-selftest.sh` (9 cases), `scripts/provenance-selftest.sh` and
  `scripts/deploy-selftest.sh` all green before any change, so that a later failure can be
  traced to this story.

## Ensures

- Every sidecar field `drift-check.sh` prints is a display copy reduced to that field's class:
  `[0-9a-f]` for `repo_commit` and both sha256 claims, `[0-9TZ:-]` for `deployed_at`. Against a
  sidecar whose fields carry ESC/CSI sequences, CR and BEL, the captured stdout+stderr contains
  no byte in 0x00–0x1F other than `\n`, and no 0x7F.
- The contradiction decision compares the **raw** extracted claim, not the display copy, to the
  served sha256. A claim of `ESC[m` followed by the correct served sha256 must still exit 6.
  Forbidden proxy: this claim sanitises to the exact served hash, so a check that compares the
  display copy would print `ok` and exit 0.
- If any field's display copy differs from its raw value, the report prints one fixed line
  saying that characters outside the field's class were removed. The line contains nothing taken
  from the origin.
- Both fetches pass `--proto '=http,https'`. A `file://` base URL pointing at a directory that
  holds the ref's own bundle bytes exits 4, not 0. The message names the refused scheme, and the
  output contains no part of the configured path.
- Bundle fetches pass a `--max-filesize` bound, and the sidecar fetch passes a much smaller one.
  If the origin streams an unbounded body with no `Content-Length`, the bundle fetch exits 4 with
  a size-limit label, well before `--max-time` expires. Forbidden proxy: a test that sends
  `Content-Length`, which only shows that curl refuses up front. The sidecar under the same
  stream prints the existing `absent or unreadable` line and leaves the exit code unchanged.
- Everything else from INFRA-007 and INFRA-009 is unchanged: bundle hashes are still taken from
  the raw fetched files, exit codes 0/2/3/4/5/6/64 mean what they meant, and the failure-path
  hygiene still holds. All three selftests are green.

## Instructions

1. **Fetch bounds, in both `fetch_bundle` and `fetch_provenance`.** Add `--proto '=http,https'`.
   Add `--max-filesize`: about 16 MiB for bundles (roughly 30 times the largest bundle today;
   they are self-contained and inline their fonts) and 64 KiB for the sidecar (it is a few
   hundred bytes). Define each bound once as a named variable near `BUNDLES`, with a one-line
   reason. In `curl_failure_label`, map `1` to a label naming the refused scheme (http/https
   only) and `63` to a size-limit label. Neither label may interpolate a configured value.
2. **Size enforcement depends on the curl version.** curl ≥ 8.4 enforces `--max-filesize`
   mid-transfer. Older versions check only a declared `Content-Length`. The selftest case in
   step 6 is the proof on the machine that runs it. State this dependency in the header notes.
   Do not add a version gate.
3. **Sidecar fields: keep the raw value, derive a display copy.** Keep the existing `sed`
   extraction as the raw value. Derive each display copy with `LC_ALL=C tr -dc '<class>'`. This
   also collapses a value that matched on several lines. Cap the display lengths: 64 characters
   for a sha, 20 for `deployed_at`, and keep the existing `:0:7` for the commit. The emptiness
   test and the `CLAIMED_SHA` vs `SERVED_SHA` comparison stay on the **raw** values. Every
   `printf` of a claim prints only the display copy. If any display copy differs from its raw
   value, print the fixed line required by Ensures once.
4. Update the header's notes and exit-code descriptions to match: the scheme restriction, the
   size bounds, and the raw-versus-display rule, including why comparing the display copy would
   be a proxy. Change nothing else in the script.
5. **Extend the selftest fixture server** in the same control-file shape as the existing
   controls: when `$CONTROL_DIR/stream-<name>` exists, send 200 with no `Content-Length` and
   write chunks until the client disconnects, catching `BrokenPipeError`/`ConnectionResetError`.
   Add `stream-*` to `reset_control`.
6. **Add cases to `scripts/drift-check-selftest.sh`**, following the existing case shape and
   updating its header list:
   - **hostile sidecar.** In `override-site-provenance.json`, give each of the four fields
     ESC/CSI, CR and BEL bytes, with the `index.html` claim set to `\033[m` followed by the real
     served sha. Expect exit 6, no control bytes in the output (strip `\n`, then
     `LC_ALL=C grep '[[:cntrl:]]'` must not match), and the removed-characters line present.
   - **file:// refused.** Put copies of the fixture's HEAD bundles under `$WORK_DIR/plant`, and
     set `FORQSITE_HELP_SITE_URL=file://$WORK_DIR/plant`. Expect exit 4, the output names the
     scheme refusal, and `$WORK_DIR` does not appear in the output.
   - **oversized bundle.** Use `stream-index.html`. Expect exit 4, the size-limit label, and not
     `timed out`.
   - **oversized sidecar.** Use `stream-site-provenance.json` with matching bundles. Expect exit
     0 and the `absent or unreadable` line.
   Add the new outputs to the captured-output dump at the end of the file.

*(Ideology note, Step 4a: the raw-versus-display split in step 3 keeps § Assert the invariant,
not a proxy for it intact: sanitising changes what the operator sees and never what the check
decides. The file:// hygiene assertion carries § Name the class, not the instance forward from
INFRA-009.)*

*(Spec-preflight note: three constant warnings, `BUNDLES`, `CLAIMED_SHA` and `SERVED_SHA`, are
false positives. All three are bash variables defined in `scripts/drift-check.sh`, and the
scanner does not read bash definitions. No `scope:` finding.)*

*(Proportionality note: this is a `code` story over two files. It fixes two findings, and each
has a trap that an obvious fix walks into: comparing the sanitised copy, and testing the size
bound with a `Content-Length` response. Those traps are where the length goes.)*

## Tests

```bash
cd /mnt/work/forqsite.help && ./scripts/drift-check-selftest.sh
cd /mnt/work/forqsite.help && ./scripts/provenance-selftest.sh
cd /mnt/work/forqsite.help && ./scripts/deploy-selftest.sh
```

Acceptance: all three are green. `drift-check-selftest.sh` reports its nine original cases plus
the four new ones. `provenance-selftest.sh` is the regression evidence that an honest sidecar
still reports and a lying one still exits 6. Paste all three outputs into the build note.

## Out of scope

- **`scripts/deploy.sh`** is covered by INFRA-011, INFRA-012 and INFRA-014.
- **Replacing `source scripts/deploy.env`** in either script belongs to INFRA-013 (CER-024).
- **Parsing the sidecar as real JSON or adding `jq`.** The fixed shape and the `sed` extraction
  stay. Only what is printed from it changes.
- **Refusing to run on curl < 8.4.** The dependency is documented, not gated.
- **Marking CER-021/CER-026 resolved in `docs/cer/backlog.md`, and any documentation change.**
  Neither file is in `touches:`.
