---
id: CONTENT-035
rail: CONTENT
title: New GAP entries for the upstream backup/restore defects found during Phase 12
status: complete
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - gap-handoff.html
  - index.html
touches:
  - docs/claims-manifest.json
  - docs/cer/backlog.md
narrative_roles: []
---

## Context

CONTENT-034 corrects this site's own blocks. The same defects exist upstream in forqsite at
the release commit `1fda3228322d5ad779f44c321c4013ccd247b3fa`, and the Known gaps list does
not have them.

(a) `docs/operator-runbook.md` §11.1 and §11.2 use
`export DATABASE_URL=$(grep DATABASE_URL .env.local | cut -d= -f2-)`. forqsite's own
first-run copies `.env.local.example` to `.env.local`, and against that file the line
returns four lines. The key extraction in the same block matches one line and is fine.

(b) `scripts/backup.sh` says in its header that "the password must NOT appear on the
command line". It then runs `pg_dump "${DATABASE_URL}"`, and `restore.sh` runs
`psql … "${DATABASE_URL}"` three times. So the URL, password included, is in each child's
argv.

The other half of (b) is the `set -x` after `pg_dump`, which turns tracing on. GAP-009
already covers that. CONTENT-031 narrowed GAP-009 to `backup.sh`, and its text says the
same thing, so that half is not repeated here. The argv exposure is a different defect with
a different fix, so it gets its own entry and GAP-009 stays as it is.

The Backup & recovery caption on this site repeats the script's false promise ("Passwords
come via PGPASSWORD/~/.pgpass, never on the command line"), so it is corrected here too.
The new entries fall under the `gap-handoff.html` footer stamp, so they need manifest
claims.

## Requires

- CONTENT-034 is merged.
- A fetched forqsite clone contains the release commit. Its path is passed on the command
  line as `FORQSITE_CLONE` and is never written into the repo.
- `python3 scripts/bundle-template.py verify` passes on both bundles.

## Ensures

`gap-handoff.html` has exactly two new GAP entries, both numbered above every ID used so
far (GAP-013 and GAP-014 unless the builder finds those taken). The index ledger, the
priority chip counts, the intro's count word and the TL;DR all match the new list. Every
stamp record and every stamp occurrence is unchanged, except that the footer stamp's
`scope` field is rewritten without a GAP-ID range.

Every base claim is byte-identical, except the Known-gaps claim's `evidence`. That is
recomputed as the union of the footer stamp's claims. Each new entry has one new claim with
`result: "added"`, the footer stamp, and a note starting `ADDED:` that gives the date it was
verified. Its quote is new to the page, and each evidence literal is a `git grep -F` hit at
the release commit.

The Tests script runs both defects at the release commit:
- The runbook's line, applied to `.env.local.example`, yields more than one line. The
  entry states that count.
- The real `backup.sh` and `restore.sh` pass the URL, password included, in every
  `pg_dump`/`psql` argv.

In `index.html`, only the ledger array and the one backup caption line change. The caption
no longer says "never on the command line". It names `pg_dump` and links the new argv
entry. The rendered DOM, with `<script>` stripped first, shows both entries on
`gap-handoff.html`, both ledger rows on `index.html#pipeline` (the route that holds the
ledger), and the corrected caption on `#backup`. The backlog gains one resolved Do Now row,
CER-044, for the caption.

Forbidden proxy:
- a new entry that describes our deployment instead of the class of defect
- a claim that the argv exposure or the multi-line value breaks something that was not
  executed (`pg_dump` against a real server was not run)
- a hand-edited Known-gaps union

## Instructions

1. **Workflow.** Follow `docs/architecture.md` § Editing procedure for both pages.
2. **GAP-013, the runbook's env extraction.** Use P2 `CORRECTNESS` and place it after GAP-012.
   - Problem: the runbook's §11.1 and §11.2 extraction matches comment lines too, against the
     example file that forqsite's own install copies into place. Say that it returns
     *N lines* (N measured; four at the release commit).
   - Evidence rows: cite the runbook line, `cp .env.local.example .env.local`, and a
     `.env.local.example` comment line containing `DATABASE_URL`.
   - Fix: run the scripts under the loader forqsite already uses
     (`pnpm exec dotenv -e .env.local -- scripts/backup.sh`).
   - Done-when: two or three checkable lines.
   - Do not claim the key extraction is broken. It matches one line.
3. **GAP-014, the credential in argv.** Use P3 `HYGIENE` and place it after GAP-010.
   - Problem: `backup.sh`'s header promises the password never appears on the command line,
     yet `pg_dump` and `restore.sh`'s `psql` calls receive `DATABASE_URL` as an argument.
     Anyone who can list processes on that host can read the argument while the command
     runs.
   - Fix, phrased as a proposal: pass the password through `PGPASSWORD` or `~/.pgpass`
     rather than the URL, as the header intends.
   - Cross-reference GAP-009 in one clause. Do not restate it.
4. **Both pages.** In `index.html`'s ledger, add a `{ id, pri, priColor, sum }` row for each
   entry, in the `gap-handoff.html` order. Use literal characters, not `\u` escapes. In
   `gap-handoff.html`:
   - Update the P2/P3 chip counts.
   - Change "nine of them" to the new count.
   - Put 013 in the "006 and 008 whenever" TL;DR bullet and 014 in the "009 and 010 last"
     bullet, adjusting the wording. This places new items. It does not re-sequence the list.
5. **The caption.** In `#backup`, replace only "Passwords come via PGPASSWORD/~/.pgpass,
   never on the command line." Say instead that `backup.sh` hands `DATABASE_URL`, password
   included, to `pg_dump` as an argument, and link `gap-handoff.html#gap-014` in the style
   of the page's other gap links.
6. **Manifest.**
   - New claims take the next unused `C-` numbers. Each has `location: "GAP-01N entry,
     problem and evidence"`, `stamp` = the footer stamp, `result: "added"`, a `quote`, and
     `evidence` literals.
   - Cite `the password must NOT appear on the command line`, not the full header line, so
     no manifest string contains `~/`.
   - Each note starts `ADDED:` and records the verification date. It stays honest that the
     footer stamp's printed date is the earlier one.
   - Rewrite the footer stamp's `scope` as "every GAP entry on the page …", with no ID range
     that the next addition would make stale. Leave its `text`, `commit` and `date` alone:
     every stamp keeps `1fda3228`, and a claim verified at the release commit keeps the
     one-commit invariant.
   - Recompute the Known-gaps claim's `evidence` as the deduplicated union of every footer
     stamp claim's evidence. No note names a claim ID.
7. **Backlog.** Add CER-044 below the CONTENT-034 rows in Do Now: the caption's false
   sentence, the release-commit fact and the fix, Source `CONTENT-035 spec-writer`, Date
   `2026-09-25`, Phase `12`, ending `**RESOLVED Phase 12 — CONTENT-035.**`. If the ID is
   taken, use the next free one.

Ideology: the entries describe the class ("a documented extraction that matches comment
lines"), never our deployment ("Name the class, not the instance"). Their evidence is
forqsite's own `path` and literal ("Cite the source that makes a claim checkable"). Both
defects are proven by execution ("Assert the invariant, not a proxy for it").

Preflight notes: `CORRECTNESS` and `HYGIENE` are GAP area labels in the page's `mk(...)`
calls; `DATABASE_URL` and `PGPASSWORD` are forqsite/libpq environment variables. `~/.pgpass` is the libpq convention the page and script already quote, not
a host path. The Tests script's host-path check excludes it by name. Length: past ~100
lines, because the Tests script carries the manifest invariants from CONTENT-031 plus the
two executions.

## Tests

The project has no test suite. Save this block to a scratch file outside the repo, then run
it from the repo root with `FORQSITE_CLONE=<clone path> bash <file>`.

```bash
set -e
: "${FORQSITE_CLONE:?set FORQSITE_CLONE to the local forqsite clone}"
S=$(mktemp -d); BASE=$(git merge-base HEAD main)
git show $BASE:docs/claims-manifest.json > $S/base-manifest.json
for p in index.html gap-handoff.html; do
  python3 scripts/bundle-template.py verify $p
  python3 scripts/bundle-template.py extract $p $S/$p
  git show $BASE:$p > $S/base-bundle-$p
  python3 scripts/bundle-template.py extract $S/base-bundle-$p $S/base.$p
  python3 -c "import re; [open(f'$S/$p.{i}.js','w').write(b) for i,b in enumerate(re.findall(r'<script type=\"text/x-dc\"[^>]*>(.*?)</script>', open('$S/$p').read(), re.S))]"
  for f in $S/$p.*.js; do node --check $f; done
done
for v in gap-handoff.html index.html#pipeline index.html#backup; do
  timeout 60 chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 --dump-dom "file://$PWD/$v" > "$S/dom-${v//#/_}" 2>/dev/null
done
git diff -U0 $BASE -- docs/cer/backlog.md > $S/backlog.diff
python3 - "$S" <<'EOF'
import difflib, gzip, html, json, os, re, subprocess, sys
S = sys.argv[1]; clone = os.environ['FORQSITE_CLONE']
m = json.load(open('docs/claims-manifest.json')); b = json.load(open(f'{S}/base-manifest.json'))
rel = m['release']['commit']; assert m['release'] == b['release'], 'release pin changed'
def git(*a): return subprocess.run(['git', '-C', clone, *a], capture_output=True, text=True, errors='replace')
def show(path): p = git('show', f'{rel}:{path}'); assert p.returncode == 0, path; return p.stdout
def grep(sym, path): return git('grep', '-q', '-F', '-e', sym, rel, '--', path).returncode
T = {p: open(f'{S}/{p}').read() for p in ('index.html', 'gap-handoff.html')}
B = {p: open(f'{S}/base.{p}').read() for p in T}
# 1. stamps: byte-identical except S-07's scope, which lists no GAP range
bs = {s['id']: s for s in b['stamps']}; ms = {s['id']: s for s in m['stamps']}
assert set(ms) == set(bs)
foot = [i for i, s in bs.items() if s['page'] == 'gap-handoff.html' and 'every GAP entry' in s['scope']]; assert len(foot) == 1; foot = foot[0]
for i in ms:
    x, y = dict(ms[i]), dict(bs[i])
    if i == foot: x.pop('scope'); y.pop('scope'); assert not re.search(r'GAP-\d+ to GAP-\d+', ms[i]['scope']), 'footer scope keeps a GAP range'
    assert x == y, f'{i}: stamp changed'
for p in T: assert re.findall(r'nullvalues/forqsite@[0-9a-f]{7,40}', T[p]) == re.findall(r'nullvalues/forqsite@[0-9a-f]{7,40}', B[p]), f'{p}: stamps moved'
# 2. claims: every base claim byte-identical except the derived Known-gaps union; new claims are added GAP claims
bc = {c['id']: c for c in b['claims']}; mc = {c['id']: c for c in m['claims']}
gh = {i for i, s in ms.items() if s['page'] == 'gap-handoff.html'}
kg = [c for c in m['claims'] if c['page'] == 'index.html' and set(re.findall(r'\bS-\d+\b', c.get('note', ''))) & gh]; assert len(kg) == 1; kg = kg[0]
for i, c in bc.items():
    if i != kg['id']: assert mc.get(i) == c, f'{i}: changed'
    else: assert {k: v for k, v in mc[i].items() if k != 'evidence'} == {k: v for k, v in c.items() if k != 'evidence'}, f'{i}: changed beyond evidence'
new = [c for c in m['claims'] if c['id'] not in bc]
assert m.get('closed', []) == b.get('closed', [])
ids = re.findall(r"mk\('(GAP-\d+)'", T['gap-handoff.html']); bids = re.findall(r"mk\('(GAP-\d+)'", B['gap-handoff.html'])
added = [g for g in ids if g not in bids]
assert set(bids) <= set(ids) and len(added) == 2, f'expected two new GAP entries, found {added}'
assert all(int(g[4:]) > max(int(x[4:]) for x in bids + ['GAP-012']) for g in added), 'a GAP ID was reused'
assert sorted(c['location'].split()[0] for c in new) == sorted(added), 'one new claim per new GAP entry'
for c in new:
    assert c['page'] == 'gap-handoff.html' and c['stamp'] == foot and c['result'] == 'added' and c.get('note', '').startswith('ADDED:'), c['id']
    assert c['quote'] in T['gap-handoff.html'] and c['quote'] not in B['gap-handoff.html'], f"{c['id']}: quote"
    for e in c['evidence']: assert grep(e['symbol'], e['path']) == 0, f"{c['id']}: {e['symbol']!r} not in {e['path']} at release"
    for a in c.get('absent', []): assert grep(a['symbol'], a['path']) == 1 and git('cat-file', '-e', f"{rel}:{a['path']}").returncode == 0, a
key = lambda e: (e['path'], e['symbol'])
union = {key(e) for c in m['claims'] if c['stamp'] == foot for e in c['evidence']}
got = [key(e) for e in kg['evidence']]
assert len(got) == len(set(got)) and set(got) == union, 'Known-gaps evidence is not the footer-stamp union'
for x in m['claims'] + m['stamps']: assert not re.search(r'\bC-\d+', x.get('note', '')), f"{x['id']}: note names a claim ID"
# 3. the defects, executed at the release commit
ex = show('.env.local.example'); rb = show('docs/operator-runbook.md')
line = 'export DATABASE_URL=$(grep DATABASE_URL .env.local | cut -d= -f2-)'
assert line in rb and 'cp .env.local.example .env.local' in rb
os.makedirs(f'{S}/rb'); open(f'{S}/rb/.env.local', 'w').write(ex)
out = subprocess.run(['bash', '-c', line + '; printf %s "$DATABASE_URL"'], cwd=f'{S}/rb', capture_output=True, text=True).stdout
n = len(out.splitlines()); assert n > 1, 'runbook extraction yields one line'
words = {2: 'two', 3: 'three', 4: 'four', 5: 'five'}
assert re.search(rf'\b({words[n]}|{n}) lines\b', T['gap-handoff.html']), f'the new entry does not say the extraction returns {n} lines'
os.makedirs(f'{S}/argv/bin'); rec = f'{S}/argv/rec'
for tool, extra in (('pg_dump', ''), ('psql', 'case "$*" in *current_database*) echo "target|127.0.0.1|5432";; esac')):
    open(f'{S}/argv/bin/{tool}', 'w').write(f'#!/bin/sh\necho "@@{tool} $*" >> {rec}\n{extra}\ncat >/dev/null 2>&1 || true\n'); os.chmod(f'{S}/argv/bin/{tool}', 0o755)
for s in ('backup', 'restore'): open(f'{S}/argv/{s}.sh', 'w').write(show(f'scripts/{s}.sh'))
gzip.open(f'{S}/argv/d.sql.gz', 'wb').close()
env = dict(os.environ, PATH=f'{S}/argv/bin:' + os.environ['PATH'], DATABASE_URL='postgresql://u:Pw0rdSecret@127.0.0.1:5432/target',
           BACKUP_DEST_DIR=f'{S}/argv/out', AI_CREDENTIAL_ENCRYPTION_KEY='k')
env.pop('BACKUP_S3_TARGET', None)
assert subprocess.run(['bash', f'{S}/argv/backup.sh'], env=env, capture_output=True).returncode == 0
assert subprocess.run(['bash', f'{S}/argv/restore.sh', f'{S}/argv/d.sql.gz', 'target'], env=env, capture_output=True, stdin=subprocess.DEVNULL).returncode == 0
calls = open(rec).read().split('@@')[1:]
assert any(c.startswith('pg_dump ') for c in calls) and all('Pw0rdSecret' in c for c in calls), calls
assert 'the password must NOT appear on the command line' in show('scripts/backup.sh')
# 4. pages: the ledger matches the list, chip counts and the count word match, only the expected passages moved
assert ids == re.findall(r"\{ id: '(GAP-\d+)'", T['index.html']), 'index ledger differs from gap-handoff list'
pri = re.findall(r"mk\('GAP-\d+', '(P\d)'", T['gap-handoff.html'])
for p, k in re.findall(r'(P\d) — [^<×]*× (\d+)', T['gap-handoff.html']): assert pri.count(p) == int(k), f'{p} chip count wrong'
nums = {9: 'nine', 10: 'ten', 11: 'eleven', 12: 'twelve'}
assert f'{nums[len(ids)]} of them' in T['gap-handoff.html'], 'intro count word'
for g in added: assert re.search(rf'<strong>[^<]*\b{g[4:]}\b', T['gap-handoff.html'].split('TL;DR')[1].split('P1 —')[0]), f'{g} not placed in the TL;DR'
BL = B['index.html'].splitlines(True); NL = T['index.html'].splitlines(True)
lo = [k for k, l in enumerate(BL) if 'const ledger = [' in l]; assert len(lo) == 1; lo = lo[0]
hi = next((k for k in range(lo + 1, len(BL)) if BL[k].lstrip().startswith(']')), None); assert hi is not None and BL[hi].strip().startswith('].map((it) =>'), 'ledger array end not found'
cap = [k for k, l in enumerate(BL) if 'never on the command line' in l]; assert len(cap) == 1; cap = cap[0]
for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, BL, NL, autojunk=False).get_opcodes():
    if tag != 'equal': assert (lo < i1 <= hi and i2 <= hi) or (i1, i2) == (cap, cap + 1), f'index.html change outside the ledger and the caption at {i1}-{i2}'
newcap = [l for l in NL if 'pg_dump' in l and l not in BL and not l.lstrip().startswith('{ id:')]
assert 'never on the command line' not in T['index.html'] and len(newcap) == 1 and any(f'#{g.lower()}' in newcap[0] for g in added), 'backup caption not corrected'
# 5. rendered DOM, <script> stripped first (CER-005, CER-012)
flat = lambda f: html.unescape(re.sub(r'<[^>]+>', '', re.sub(r'(?is)<(script|style)\b.*?</\1>', '', open(f).read())))
gd, pd, kd = flat(f'{S}/dom-gap-handoff.html'), flat(f'{S}/dom-index.html_pipeline'), flat(f'{S}/dom-index.html_backup')
assert set(re.findall(r'GAP-\d{3}', gd)) == set(ids), 'rendered gap list differs'
for g, s in re.findall(r"\{ id: '(GAP-\d+)',[^}]*sum: '((?:[^'\\]|\\.)*)'", T['index.html']):
    s = re.sub(r'\\u([0-9a-fA-F]{4})', lambda u: chr(int(u.group(1), 16)), s.replace("\\'", "'"))
    if g in added: assert g in pd and html.unescape(s) in pd, f'{g} ledger row not rendered'
assert 'never on the command line' not in kd
# 6. backlog: one new resolved Do Now row
d = open(f'{S}/backlog.diff').read().splitlines()
minus = [l for l in d if l.startswith('-') and not l.startswith('---')]; plus = [l for l in d if l.startswith('+') and not l.startswith('+++')]
assert not minus and len(plus) == 1 and '**RESOLVED Phase 12 — CONTENT-035.**' in plus[0] and '| CONTENT-035 spec-writer |' in plus[0], 'backlog row'
bl = open('docs/cer/backlog.md').read(); assert bl.index(plus[0][1:]) < bl.index('## Do Later')
hostpath = re.compile(r'/mnt/|/home/|~/(?!\.pgpass)')
added_lines = plus + [l for p in T for l in T[p].splitlines() if l not in B[p]] + json.dumps(m, indent=1, ensure_ascii=False).splitlines()
for l in added_lines: assert not hostpath.search(l) and clone not in l, f'host path: {l[:80]}'
print('OK', added)
EOF
```

Pass means the script prints `OK` with the two new IDs and exits 0. The reviewer also reads
both new entries against the clone at the release commit, and confirms the prose claims
nothing the script did not execute. If the builder used a CER ID other than CER-044, the
reviewer adjusts nothing: the backlog check finds the row by its marker and Source.

## Out of scope

- GAP-009's wording. The tracing half of finding (b) is already recorded there.
- A pipeline-stage tag for either new gap, and any other `index.html` prose.
- Restamping. Every stamp stays at `1fda3228`, with its current date.
- Whether a restore run by a non-superuser stops on pgvector's extension comment. It is
  untested and becomes a Do Later row in CONTENT-036, not a GAP.
- Deploy, which runs after CONTENT-036 merges.
