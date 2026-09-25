---
id: CONTENT-033
rail: CONTENT
title: Correct the restore example, its row-count comment and the prestart-drift sentence in index.html
status: complete
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
touches:
  - docs/cer/backlog.md
narrative_roles: []
---

## Context

The cp-12 checkpoint gate refused because CER-038 is in Do Now. The operator decided on
2026-09-25 to fix it inside Phase 12 as a correction story, not in a new phase. CER-038 is
the Backup & recovery "Restore procedure" block in `index.html`. It calls
`scripts/restore.sh` with only the dump file. forqsite `1ab2405c` (SEC-078) made a second
argument mandatory. At the release commit
`1fda3228322d5ad779f44c321c4013ccd247b3fa`, the script checks `"$#" -lt 2`, prints its
usage line and exits 1. CONTENT-032's builder found a second stale sentence. The Operations
route's "Incidents — where to look first" entry for "App errors / 500s" says the "prestart
check will refuse to boot on drift". At the release commit, both prestart migration checks
are advisory and exit 0 (see claim C-004, including `check-migration-hashes.ts --advisory`).
While this spec was being written, a third stale line turned up in the same restore block.
Its comment `# prints row counts: organisations / sub_tenants / pages / blocks` names
`sub_tenants`, but at the release commit `restore.sh` counts `tenants`. The operator widened
the story to include it (2026-09-25). This story corrects the three passages and records
them in the backlog. Nothing else changes.

## Requires

- CONTENT-032 is merged. Both pages name exactly one forqsite commit in their stamps.
- A fetched forqsite clone contains the release commit, and its path is passed on the
  command line as `FORQSITE_CLONE`. The path is never written into the repo.
- `python3 scripts/bundle-template.py verify index.html` passes.

## Ensures

Compared with `git merge-base HEAD main`, the extracted `index.html` template differs in
only three places, and `gap-handoff.html` and `docs/claims-manifest.json` are
byte-identical, so no stamp changes. The three places:
- The restore block's single `scripts/restore.sh` line passes the dump file and, as its
  second argument, the database named on the block's `createdb` line. At most two added
  lines sit next to it, inside the same `<pre>`, and one of them quotes the release
  commit's usage text `scripts/restore.sh <backup-file.sql.gz> <expected-database-name>`
  verbatim.
- The block's single `# prints row counts:` comment lists, in order and separated by
  ` / `, the tables that the `(SELECT count(*) FROM <table>)` lines in `restore.sh` count
  at the release commit: `organisations / tenants / pages / blocks`. Each name is a
  `git grep -F` hit there.
- The "App errors / 500s" `fix` string no longer says "refuse to boot", and it says the
  checks exit 0.

In `docs/cer/backlog.md`, CER-038 carries `**RESOLVED Phase 12 — CONTENT-033.**`. Two new
Do Now rows carry the same marker and Phase `12`. CER-039 records the prestart sentence,
with Source `CONTENT-032 builder`. CER-040 records the row-count comment, with Source
`CONTENT-033 spec-writer`. No other backlog line changes. The rendered DOM of
`index.html#backup` and `index.html#ops`, with `<script>` stripped first (CER-005,
CER-012), shows the new text and not the old.

Forbidden proxy:
- argument names written from memory or from CER-038's prose instead of taken from the
  script at the release commit
- byte-identity asserted on the JSON-escaped bundle instead of on `extract` output

## Instructions

1. **Workflow.** Follow `docs/architecture.md` § Editing procedure: `verify`, then
   `extract` into a scratch directory outside the repo, edit only there, then `inject`
   and `verify`. Never hand-splice the bundle.
2. **Take the usage from the script.** In the clone, run
   `git grep -n -F 'Usage: scripts/restore.sh' <release> -- scripts/restore.sh`. Copy
   the argument text from that hit exactly. In the extracted template, append the
   database name from the block's `createdb` line to the `restore.sh` line. Add one
   comment line that quotes the usage (HTML-escape `<` and `>` as `&lt;` `&gt;` inside the
   `<pre>`). The comment says what the second argument guards: `restore.sh` refuses when
   `DATABASE_URL` resolves to a different database. Read that from the script's own header
   comment at the release commit. Leave every other line of the block alone, except the
   row-count comment (step 3).
3. **The row-count comment.** In the clone, run
   `git grep -n -F 'SELECT count(*) FROM' <release> -- scripts/restore.sh`. Rewrite only
   the table list in `# prints row counts: … — sanity-check them`. Use the names from
   those hits, in the script's order, separated by ` / `. Check all four names, not only
   `sub_tenants`. Keep the `# prints row counts: ` prefix so the check can find the line.
4. **The incident sentence.** Replace only "prestart check will refuse to boot on drift."
   with a sentence that agrees with C-004's wording on the Upgrade section: both prestart
   migration checks only report and exit 0, so drift does not stop a start. Point at the
   start log's `check-migration` lines. The `fix` value is a single-quoted JS string. Do
   not add an unescaped `'`.
5. **Manifest: no change.** CONTENT-030's rule is "stamped claims only". No stamp covers
   any of the three passages. The restore block is on the Backup & recovery route, which
   has no stamp, and the Incidents section follows S-03's footer. So none of them gets a
   manifest entry, and no stamp text, commit or date changes. CONTENT-032's
   one-commit-per-page invariant therefore still holds.
6. **Backlog.** Append ` **RESOLVED Phase 12 — CONTENT-033.**` and one sentence of
   outcome to the CER-038 finding cell. In Do Now, add CER-039 (the prestart sentence,
   Source `CONTENT-032 builder`) and then CER-040 (the row-count comment, Source
   `CONTENT-033 spec-writer`) directly below CER-038. Each row gives the stale text and the
   release-commit fact, and ends with the same marker. CER-039 and CER-040 were the next
   free IDs when this spec was written. If either is taken by the time you build, use the
   next free IDs and say so in your report. Leave the file's
   "Last updated" line alone. Name no host, directory or URL.

Ideology: the corrected passages cite forqsite's own script, as written ("Cite the source
that makes a claim checkable"). Byte-identity is asserted on extracted templates ("Assert
the invariant, not a proxy for it"). The bundle changes only through `bundle-template.py`
(Generated-artifact discipline).

Preflight notes: `docs/claims-manifest.json` is named only to assert that it does not
change, so it is deliberately left out of `touches:`. `DATABASE_URL` is a forqsite
environment variable, not a constant in this repo.

Length: this spec runs past the ~100-line guideline for a doc story. The Tests script is
the only mechanical proof of the three-place scope. It fixes both defects in CONTENT-032's
Tests: it counts stamp occurrences instead of distinct texts, and it greps only added lines
for host paths.

## Tests

The project has no test suite. The reviewer's Bash guard blocks typed `git show`/`git grep`.
Save this block to a scratch file outside the repo, then run it from the repo root with
`FORQSITE_CLONE=<clone path> bash <file>`. Do not source `scripts/deploy.env`.

```bash
set -e
: "${FORQSITE_CLONE:?set FORQSITE_CLONE to the local forqsite clone}"
S=$(mktemp -d); BASE=$(git merge-base HEAD main)
git diff --quiet $BASE -- gap-handoff.html docs/claims-manifest.json
python3 scripts/bundle-template.py verify index.html
python3 scripts/bundle-template.py extract index.html $S/new.html
git show $BASE:index.html > $S/base-bundle.html
python3 scripts/bundle-template.py extract $S/base-bundle.html $S/base.html
for f in new base; do grep -oE 'nullvalues/forqsite@[0-9a-f]{7,40}' $S/$f.html > $S/$f.stamps; done
cmp $S/new.stamps $S/base.stamps
test "$(sort -u $S/new.stamps | wc -l)" = 1
python3 -c "import re; [open(f'$S/s{i}.js','w').write(b) for i,b in enumerate(re.findall(r'<script type=\"text/x-dc\"[^>]*>(.*?)</script>', open('$S/new.html').read(), re.S))]"
for f in $S/s*.js; do node --check $f; done
for v in backup ops; do
  timeout 60 chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 --dump-dom "file://$PWD/index.html#$v" > $S/dom-$v 2>/dev/null
done
git diff -U0 $BASE -- docs/cer/backlog.md > $S/backlog.diff
python3 - "$S" <<'EOF'
import difflib, html, os, re, subprocess, sys
S = sys.argv[1]; clone = os.environ['FORQSITE_CLONE']
REL = '1fda3228322d5ad779f44c321c4013ccd247b3fa'
USAGE = 'scripts/restore.sh <backup-file.sql.gz> <expected-database-name>'
for path, lit in [('scripts/restore.sh', 'Usage: ' + USAGE), ('scripts/restore.sh', 'if [ "$#" -lt 2 ]; then'),
                  ('package.json', 'tsx scripts/check-migration-hashes.ts --advisory"'),
                  ('scripts/check-migrations.ts', '// Always exit 0: missing tables produce a WARN but must not block startup.'),
                  ('scripts/check-migration-hashes.ts', 'exits 0 after printing')]:
    assert subprocess.run(['git', '-C', clone, 'grep', '-q', '-F', '-e', lit, REL, '--', path]).returncode == 0, f'{lit!r} not in {path} at release'
B = open(f'{S}/base.html').read().splitlines(True); N = open(f'{S}/new.html').read().splitlines(True)
RC = '# prints row counts: '
ri = [i for i, l in enumerate(B) if l.startswith('scripts/restore.sh ')]
ci = [i for i, l in enumerate(B) if l.startswith(RC)]
ii = [i for i, l in enumerate(B) if "sym: 'App errors / 500s'" in l]
assert len(ri) == len(ci) == len(ii) == 1 and ci[0] == ri[0] + 1, 'base anchors not unique or not adjacent'
r, c, x = ri[0], ci[0], ii[0]
assert len(N) - len(B) <= 2, 'more than two lines added'
for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, B, N, autojunk=False).get_opcodes():
    if tag == 'equal': continue
    if i1 == x: assert (i2, j2 - j1) == (x + 1, 1), 'incident line not replaced one-for-one'
    else: assert r <= i1 and i2 <= c + 1, f'change outside the three passages at base lines {i1}-{i2}'
assert B[r] not in N and B[c] not in N and B[x] not in N, 'a passage was not changed'
src = subprocess.run(['git', '-C', clone, 'show', f'{REL}:scripts/restore.sh'], capture_output=True, text=True, check=True).stdout
want = re.findall(r'\(SELECT count\(\*\) FROM (\w+)\)', src)
assert want, 'no row counts found in restore.sh'
rc = [l for l in N if l.startswith(RC)]; assert len(rc) == 1, 'row-count comment count'
got = [n.strip() for n in rc[0][len(RC):].split(' — ')[0].split('/')]
assert got == want, f'row-count comment lists {got}, restore.sh counts {want}'
for n in got:
    assert subprocess.run(['git', '-C', clone, 'grep', '-q', '-F', '-e', f'(SELECT count(*) FROM {n})', REL, '--', 'scripts/restore.sh']).returncode == 0, f'{n} not counted at release'
inv = [l for l in N if l.startswith('scripts/restore.sh ')]; assert len(inv) == 1, 'restore invocation count'
db = [l.split()[1] for l in N if l.startswith('createdb ')]; assert len(db) == 1
tok = inv[0].split('#')[0].split()
assert len(tok) == 3 and tok[1].endswith('.sql.gz') and tok[2] == db[0], f'invocation {tok} does not match usage'
fix = [l for l in N if "sym: 'App errors / 500s'" in l][0]
fixtxt = re.search(r"fix: '((?:[^'\\]|\\.)*)'", fix).group(1).replace("\\'", "'")
assert 'refuse to boot' not in fixtxt and 'exit 0' in fixtxt, 'incident sentence not corrected'
flat = lambda f: html.unescape(re.sub(r'<[^>]+>', '', re.sub(r'(?is)<script\b.*?</script>', '', open(f).read())))
bk, ops = flat(f'{S}/dom-backup'), flat(f'{S}/dom-ops')
assert USAGE in bk and f'{tok[1]} {tok[2]}' in bk and ' / '.join(want) in bk and 'sub_tenants' not in bk, 'restore block not rendered'
assert fixtxt in ops and 'refuse to boot' not in ops, 'incident entry not rendered'
d = open(f'{S}/backlog.diff').read().splitlines()
minus = [l for l in d if l.startswith('-') and not l.startswith('---')]
plus = [l for l in d if l.startswith('+') and not l.startswith('+++')]
assert len(minus) == 1 and minus[0].startswith('-| CER-038 ') and len(plus) == 3, 'backlog changed beyond CER-038/039/040'
row = {l[1:].split('|')[1].strip(): l for l in plus}
assert '**RESOLVED Phase 12 — CONTENT-033.**' in row['CER-038']
c39 = row['CER-039']
assert '**RESOLVED Phase 12 — CONTENT-033.**' in c39 and '| CONTENT-032 builder |' in c39 and c39.rstrip().endswith('| 12 |')
c40 = row['CER-040']
assert '**RESOLVED Phase 12 — CONTENT-033.**' in c40 and '| CONTENT-033 spec-writer |' in c40 and c40.rstrip().endswith('| 12 |')
added = plus + [l for l in N if l not in B]
for l in added:
    assert not re.search(r'/mnt/|/home/|~/', l) and clone not in l, f'host path in added line: {l[:80]}'
print('OK')
EOF
test "$(grep -c '^| CER-039 ' docs/cer/backlog.md)" = 1
test "$(grep -c '^| CER-040 ' docs/cer/backlog.md)" = 1
```

Pass means the script prints `OK` and every line exits 0. The reviewer also reads the
restore block and the incident entry against the clone at the release commit. The
explanatory comment and the new sentence must say what the script does, not only contain
the checked literals. If the builder had to use IDs other than CER-039 and CER-040, the
reviewer changes those IDs in the checks to match.

## Out of scope

- Adding a stamp to the Backup & recovery route or the Incidents section, and any manifest
  change.
- Any other prose on either page, and `gap-handoff.html`'s GAP-008 entry.
- Deploy. The post-merge deploy step that CONTENT-032 defines covers it, and the
  orchestrator runs it.
