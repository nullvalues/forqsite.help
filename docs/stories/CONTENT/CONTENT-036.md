---
id: CONTENT-036
rail: CONTENT
title: Checkpoint bookkeeping and backlog grooming pulled into cp-12
status: draft
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - docs/cer/backlog.md
touches:
  - docs/checkpoints.md
  - docs/ideology.md
narrative_roles: []
---

## Context

cp-12's gates passed. The operator decided on 2026-09-25 to clear four pieces of
bookkeeping in the same checkpoint rather than leave them in the backlog:

- **(a) CER-032.** `docs/checkpoints.md` has no cp-10 section, although the `cp-10` tag
  exists.
- **(b) CER-005.** The row says `index.html`'s `sc-for` gap ledger does not render.
  Its last re-run loaded `index.html#gaps`, and no route has that id. The ledger lives on
  the `pipeline` route (`nav('pipeline')`, "Dev → Prod pipeline"). So the finding may
  measure a wrong fragment, not a defect. This story settles it by serving the page over
  `http://` and over `file://`.
- **(c) CER-011, CER-012 and CER-017.** These are one lesson about spec-authoring, filed
  three times. They are recorded once, as a convention.
- **(d) The backlog.** It gains five Do Later rows and a set of phase-dependency
  annotations. The stale Do Now placeholder row is removed.

No page, manifest or stamp changes.

## Requires

- CONTENT-035 is merged, so the backlog holds the CER rows up to CER-044.
- The `cp-10` tag is present locally.

## Ensures

**Files that must not change.** `index.html`, `gap-handoff.html` and
`docs/claims-manifest.json` are byte-identical to `git merge-base HEAD main`.

**`docs/checkpoints.md`.**
- It has a `## cp-10` section between cp-9 and cp-11, in their shape: Phase, Tag command,
  Acceptance, Gates, plus any lesson the record states.
- The section is built only from recorded evidence: the tag (`f4e4e5c`, 2026-09-21) and
  `docs/phases/phase-10.md`, including its "Filled in at CP-10, 2026-09-21" gate record.
- It says plainly that it was written after the fact, on 2026-09-25.
- There is no `## cp-12` section.

**`docs/ideology.md`.** It has one `### … convention …` section. For each of CER-011,
CER-012 and CER-017 it names the defect and the invariant the check should assert
instead. CER-011, CER-012, CER-017 and CER-032 carry `**RESOLVED Phase 12 — CONTENT-036.**`,
and the first three name that section.

**CER-005 depends on the Tests script's measurement.** The script loads
`index.html#pipeline` over `http://127.0.0.1` and over `file://`. It strips `<script>` and
`<style>` blocks, then checks whether every ledger row's ID and summary is in the rendered
text.
- If every row renders at both origins, CER-005 carries the resolution marker and the
  evidence.
- If not, CER-005 stays open, and a diagnosis naming this story is appended.

**Annotations.** Each is appended to its row's finding cell. The old text is kept as a
prefix, and the Source, Date and Phase cells are unchanged.
- CER-011 and CER-012 name the Phase 13 checker constraint.
- CER-031, CER-034, CER-035 and CER-037 name Phase 14's release job and stay open.
- CER-031 and CER-037 each name the other.

**Rows.**
- Five new open Do Later rows take the next free IDs (CER-045 to CER-049) with Phase `12`.
  One of them records that the Process supervision route's systemd units still point
  `EnvironmentFile=` at `/etc/forqsite/env`, a file forqsite does not define. Another
  records that GAP-013's fix text in `gap-handoff.html` runs `dotenv` without `-o`, while
  `index.html`'s backup, cron and restore blocks use `dotenv -o`.
- Do Now no longer has the `*(none)*` placeholder row. Do Much Later keeps its own.
- No other row changes.

Forbidden proxy:
- a cp-10 figure that is not in the recorded evidence
- CER-005 closed or kept open without the measurement
- counting `GAP-0NN` matches in inert `<script>` source as rendered rows (CER-012)

## Instructions

1. **cp-10.** Read `docs/phases/phase-10.md`: the title, the Stories table, and the CP-10
   checklist and gate record near its end. Read the tag with `git show -s cp-10`. Write the
   section in the cp-9/cp-11 shape. Open it with one line saying it was written on
   2026-09-25 from the tag and the phase-10 record, because the section was missed at tag
   time (CER-032). State only what those two sources record, such as the stories, their
   count, and the gate verdicts including the docs remediation `15967e2`. Do not reconstruct
   a drift check that was not recorded. The cp-12 section is the orchestrator's, written at
   tag time.
2. **CER-005.** Run the Tests script's measurement yourself before editing. Append to the
   row the date, the route actually used (`#pipeline`), both origins, and the result.
   - If every row rendered at both origins: explain that the earlier re-run loaded `#gaps`,
     which matches no route, so it measured an empty screen. Then close the row with
     `**RESOLVED Phase 12 — CONTENT-036.**`.
   - If not: record which origin failed and what rendered, and leave the row open. Do not
     fix the page in this story.

   Either way, keep the row's existing text.
3. **The convention.** Under `## Accepted constraints`, directly after "Assert the invariant,
   not a proxy for it", add one section, for example
   `### Spec-authoring convention for mechanical checks`, with one short entry per defect:
   - **Soft-wrapped phrases (CER-011).** Normalise whitespace before matching prose, or
     assert on a structural anchor.
   - **Inert source counted as rendered (CER-012).** Strip `<script>`/`<style>` before
     asserting a render, or assert on a marker only the renderer emits. Hold every other
     variable constant.
   - **Self-closing ranges (CER-017).** Bound a range on the block's own fields, or count
     them directly, and state the method next to the number.

   Then append `**RESOLVED Phase 12 — CONTENT-036.**` and the section's name to CER-011,
   CER-012 and CER-017.
4. **Annotations.** These rows stay open. Append without starting a segment with RESOLVED,
   SUPERSEDED or OBSOLETE: the marker grammar in the backlog header would read that as
   closed (CER-018's lesson).
   - CER-011 and CER-012: these are design constraints for Phase 13's stale-claim checker.
     Quote matching must tolerate soft-wraps, and inert script source must not count as
     rendered.
   - CER-031, CER-034, CER-035 and CER-037: each is a prerequisite of Phase 14's unattended
     release job.
   - CER-031 and CER-037: they are handled as a pair, because a rollback needs a truthful
     list of backups.
5. **New Do Later rows.** Use Date `2026-09-25`, Phase `12`, and Source
   `cold-eyes triage (CP-12)`.
   - **Claims-manifest schema.** The field vocabulary (`result`, `absent`, `counts`,
     `closed_by`, `marker`, the top-level `closed` array) is defined only in the
     CONTENT-030 to CONTENT-032 specs. The manifest has no `closed` array today. The
     Known-gaps claim is the only claim without a `result` (confirm before writing).
     Phase 13's checker needs a schema reference and fixture tests for the `unverified`
     marker path and the `closed` array.
   - **Command blocks outside the manifest.** The manifest covers stamped claims only.
     Every Phase 12 content finding outside the Known gaps list was in an unstamped command
     block and was found incidentally: CER-038 to CER-040 and the CONTENT-034 rows. Bring
     command blocks into the manifest, with runbook evidence, so Phase 13 can check them.
   - **pgvector on restore.** A restore by a non-superuser of a plain `pg_dump` may stop at
     `COMMENT ON EXTENSION vector` ("must be owner"). This is untested, because no
     Postgres was available. Verify it before the page claims a clean restore.
   - **systemd units point at an undefined file.** Both units on the Process supervision
     route (`forqsite.service` and `forqsite-scheduler.service`) carry
     `EnvironmentFile=/etc/forqsite/env`. forqsite does not define that file. At the release
     commit `1fda3228`, `git grep -F /etc/forqsite/env` finds nothing, and the only
     `/etc/forqsite` path in the repository is `/etc/forqsite/providers.json` in
     `tests/lib/config.test.ts`. This is the same stale-claim class as the cron line
     CONTENT-034 fixed (CER-043). The units' own caption says `pnpm start` loads
     `.env.local` through dotenv regardless. Use the Source `CONTENT-034 spec-writer`
     for this row. Confirm the grep yourself before writing it.
   - **GAP-013's fix text omits `-o`.** GAP-013's proposed fix in `gap-handoff.html` tells
     forqsite to run `pnpm exec dotenv -e .env.local -- scripts/backup.sh`, without `-o`.
     `index.html`'s own backup, cron and restore blocks (CONTENT-034) use
     `dotenv -o -e .env.local`, because without `-o` a value already exported in the shell
     wins over the file. forqsite's dotenv-cli help says `-o, --override  override system
     variables`. The two documents disagree, and one of them should be reconciled in a
     later content pass. Use the Source `CONTENT-035 reviewer` for this row.
6. **Remove** the `| — | *(none)* | — | — | — |` row from Do Now only. Leave the file's
   "Last updated" line alone. Name no host, directory or URL of ours.

Ideology: the convention section extends "Assert the invariant, not a proxy for it"
instead of restating it. CER-005 is settled by measurement, and the measurement strips
inert source.

Preflight notes: `docs/claims-manifest.json` is named only to assert that it does not change,
and `docs/phases/phase-10.md` is read as evidence, never edited; neither is in `touches:`.

Length: past ~100 lines, because the Tests script decides the CER-005 branch mechanically
and checks the append-only rule for nine rows.

## Tests

The project has no test suite. Save this block to a scratch file outside the repo, then run
it from the repo root with `bash <file>`. It needs no forqsite clone. It serves copies of the
bundles from a temporary directory on a free localhost port and stops the server on exit.

```bash
set -e
S=$(mktemp -d); BASE=$(git merge-base HEAD main)
git diff --quiet $BASE -- index.html gap-handoff.html docs/claims-manifest.json
git show $BASE:docs/cer/backlog.md > $S/base-backlog.md
cp index.html gap-handoff.html $S/
python3 scripts/bundle-template.py extract index.html $S/tpl.html
PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
python3 -m http.server $PORT --bind 127.0.0.1 -d $S >/dev/null 2>&1 & SRV=$!
trap 'kill $SRV 2>/dev/null' EXIT
python3 -c "import time,urllib.request as u
for _ in range(100):
    try: u.urlopen('http://127.0.0.1:$PORT/index.html'); break
    except Exception: time.sleep(0.1)"
timeout 60 chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 --dump-dom "http://127.0.0.1:$PORT/index.html#pipeline" > $S/dom-http 2>/dev/null
timeout 60 chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 --dump-dom "file://$S/index.html#pipeline" > $S/dom-file 2>/dev/null
CP10=$(git rev-parse 'cp-10^{commit}')
python3 - "$S" "$CP10" <<'EOF'
import html, re, sys
S, cp10 = sys.argv[1], sys.argv[2]
MARK = re.compile(r'(?:^|\|\s*|[.!?]\s+|\*\*|\(|\[)(resolved|superseded|obsolete)\b', re.I)
def rows(text): return {l.split('|')[1].strip(): l for l in text.splitlines() if re.match(r'\| CER-\d+ ', l)}
def section(text, h): return text.split(f'## {h}')[1].split('\n## ')[0]
new, old = open('docs/cer/backlog.md').read(), open(f'{S}/base-backlog.md').read()
N, O = rows(new), rows(old)
closed = lambda i: bool(MARK.search(N[i].split('|', 2)[2].rsplit('|', 4)[0]))
# 1. CER-005: the diagnosis decides the row
tpl = open(f'{S}/tpl.html').read()
ledger = [(g, re.sub(r'\\u([0-9a-fA-F]{4})', lambda u: chr(int(u.group(1), 16)), s.replace("\\'", "'")))
          for g, s in re.findall(r"\{ id: '(GAP-\d+)',[^}]*sum: '((?:[^'\\]|\\.)*)'", tpl)]
assert ledger, 'no ledger rows in the template'
def rendered(f):
    d = html.unescape(re.sub(r'<[^>]+>', '', re.sub(r'(?is)<(script|style)\b.*?</\1>', '', open(f).read())))
    return all(g in d and s in d for g, s in ledger)
at_http, at_file = rendered(f'{S}/dom-http'), rendered(f'{S}/dom-file')
print(f'ledger rows rendered: http={at_http} file={at_file}')
assert 'CONTENT-036' in N['CER-005'] and N['CER-005'].startswith(O['CER-005'].rsplit('|', 4)[0].rstrip()), 'CER-005 not annotated in place'
if at_http and at_file: assert '**RESOLVED Phase 12 — CONTENT-036.**' in N['CER-005'], 'rows render: CER-005 should be resolved'
else: assert not closed('CER-005'), 'rows do not render: CER-005 must stay open'
# 2. resolutions and annotations
for i in ('CER-011', 'CER-012', 'CER-017', 'CER-032'): assert '**RESOLVED Phase 12 — CONTENT-036.**' in N[i], i
for i in ('CER-011', 'CER-012'): assert 'Phase 13' in N[i], f'{i}: no Phase 13 checker note'
for i in ('CER-031', 'CER-034', 'CER-035', 'CER-037'): assert 'Phase 14' in N[i] and not closed(i), f'{i}: annotation missing or closes the row'
for i in ('CER-031', 'CER-037'): assert ('CER-037' if i == 'CER-031' else 'CER-031') in N[i], f'{i}: pair not named'
touched = {'CER-005', 'CER-011', 'CER-012', 'CER-017', 'CER-032', 'CER-031', 'CER-034', 'CER-035', 'CER-037'}
cell = lambda l: l.split('|', 2)[2].rsplit('|', 4)[0].rstrip()
for i in O:
    if i in touched: assert cell(N[i]).startswith(cell(O[i])) and N[i].split('|')[-4:] == O[i].split('|')[-4:], f'{i}: rewritten, not appended'
    else: assert N[i] == O[i], f'{i}: changed'
fresh = [i for i in N if i not in O]
dl = section(new, 'Do Later')
assert len(fresh) == 5 and all(N[i] in dl and not closed(i) and '| 12 |' in N[i] for i in fresh), 'five open Do Later rows'
assert 'EnvironmentFile=/etc/forqsite/env' in tpl, 'the systemd units no longer carry the line the row describes'
assert sum('/etc/forqsite/env' in N[i] and 'EnvironmentFile' in N[i] and '1fda3228' in N[i] for i in fresh) == 1, 'no systemd EnvironmentFile row'
gh, ix = open('gap-handoff.html').read(), open('index.html').read()
assert 'dotenv -e .env.local -- scripts' in gh and 'dotenv -o -e .env.local' in ix, 'the -o disagreement the row describes is gone'
assert sum('GAP-013' in N[i] and 'gap-handoff.html' in N[i] and '-o' in N[i] and 'CONTENT-035 reviewer' in N[i] for i in fresh) == 1, 'no GAP-013 dotenv -o row'
assert int(min(fresh)[4:]) == max(int(i[4:]) for i in O) + 1, 'new rows do not take the next free IDs'
assert '*(none)*' not in section(new, 'Do Now') and '*(none)*' in section(new, 'Do Much Later'), 'placeholder rows'
# 3. docs/checkpoints.md: a cp-10 section, after cp-9 and before cp-11, and no cp-12 section
ck = open('docs/checkpoints.md').read()
assert ck.index('## cp-9') < ck.index('## cp-10') < ck.index('## cp-11') and '## cp-12' not in ck
c10 = section(ck, 'cp-10')
assert cp10.startswith('f4e4e5c') and 'f4e4e5c' in c10 and '2026-09-21' in c10 and '2026-09-25' in c10, 'cp-10 section evidence'
for f in ('**Phase:**', '**Tag command:**', '**Acceptance:**', '**Gates:**'): assert f in c10, f'cp-10 section lacks {f}'
# 4. docs/ideology.md: one convention section naming all three, each resolved row pointing at it
ideo = open('docs/ideology.md').read()
h = [l for l in ideo.splitlines() if l.startswith('### ') and 'convention' in l.lower()]
assert len(h) == 1, 'expected one convention section'
body = ideo.split(h[0])[1].split('\n### ')[0].split('\n## ')[0]
for i in ('CER-011', 'CER-012', 'CER-017'): assert i in body and h[0][4:].strip() in N[i], f'{i}: not recorded in, or not pointing at, the section'
print('OK', fresh)
EOF
git diff $BASE --word-diff=porcelain -U0 -- docs/cer/backlog.md docs/checkpoints.md docs/ideology.md | grep '^+' | grep -vE '^\+\+\+' | grep -nE '/mnt/|/home/|~/' && exit 1
echo DONE
```

Pass means the script prints `ledger rows rendered: http=… file=…`, then `OK` with the five
new IDs, then `DONE`, and exits 0. The reviewer also reads the cp-10 section against
`docs/phases/phase-10.md` and the tag, figure by figure, and reads each new Do Later row
for accuracy, including the `-o` quotes in the GAP-013 row against both pages. For the systemd row, the reviewer checks the release-commit evidence against
the clone.

## Out of scope

- The cp-12 section of `docs/checkpoints.md`. The orchestrator writes it at tag time,
  together with the drift-check block.
- Any page fix for CER-005, and any change to either bundle or the manifest.
- Acting on the new Do Later rows, and closing CER-031, CER-034, CER-035 or CER-037.
- Re-triaging any other backlog row.
