---
id: CONTENT-031
rail: CONTENT
title: Re-verify and restamp the Known gaps list in both pages
status: draft
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
  - gap-handoff.html
touches:
  - docs/claims-manifest.json
narrative_roles: []
---

## Context

The Known gaps list appears twice. `gap-handoff.html` has the full GAP entries under a
footer stamp, and GAP-012's evidence rows carry their own table-row stamp. `index.html` has
the Known gaps ledger and the sidebar "Known gaps →" callout, whose stamp says the linked
list is current. All three stamps predate the release commit that CONTENT-030 pinned in
`docs/claims-manifest.json`. This story re-checks every gap entry against that commit and
decides whether each one is still open, has changed or has closed. It corrects the page
where forqsite has moved, restamps those three stamps, and records each decision in the
manifest, so the restamp can be checked rather than taken on trust. Everything else on
both pages belongs to CONTENT-032.

## Requires

- CONTENT-030 is merged, so `docs/claims-manifest.json` exists and pins `release.commit`.
- A fetched forqsite clone contains `release.commit`, and its path is passed on the
  command line as `FORQSITE_CLONE`.
- `python3 scripts/bundle-template.py verify` passes on both bundles.

## Ensures

Scope is derived, not listed. It covers the index.html Known-gaps claim (the one whose note
names a gap-handoff stamp) and every gap-handoff claim whose `location` starts with `GAP-`.
Every stamp those claims cite is restamped to `nullvalues/forqsite@<release.commit[:8]>`
with one shared verification date. Each claim in scope other than the Known-gaps claim
carries a `result` of `open`, `changed` or `added`. No claim in scope keeps a `MISMATCH:`
note, and a claim that had one is `changed`. Every evidence symbol is a `git grep -F` hit at the release commit, and every
`absent` entry is a verified miss there. A `changed` claim has a `CHANGED:` note and a
`quote` that does not appear in the base template. A closed gap is gone from both pages,
and it and any partly-closed claim record a `closed_by` commit: an ancestor of the release
commit, not an ancestor of the old stamp's commit, and one that touches the named path.
The index ledger, the pipeline gap tags and the `gap-handoff.html#gap-…` links match the
`gap-handoff.html` list, and the priority chip counts match it too. Every `path:line`
evidence row in `gap-handoff.html` names a line that holds a cited symbol. The Known-gaps
evidence is still the union of the footer stamp's claims. Every stamp and claim outside
scope is byte-identical to the base manifest. Both bundles verify, their scripts pass
`node --check`, and the rendered DOM, once `<script>` is stripped, shows the new stamp.

Forbidden proxy: a stamp rewritten without a per-claim `result` behind it, a `changed` label
on text that did not change, or a gap dropped from the page with no `closed_by` record.

## Instructions

1. **Workflow.** Follow `docs/architecture.md` § Editing procedure. Run `verify`, then
   `extract` each page into a scratch directory outside the repo. Edit only the extracted
   templates. Then run `inject` and `verify` again. Never hand-splice a bundle.
2. **Re-verify each gap entry at `release.commit`.** Work from the forqsite clone with
   `git grep -F`, `git show <release>:<path>` and
   `git log <old stamp commit>..<release> -- <paths>`. Re-read every sentence and evidence
   row in each GAP entry, not just the literals the manifest already holds. Decide one of:
   - `open`: the page is right as written.
   - `changed`: correct the page to match forqsite, choose a `quote` that contains the
     corrected text, and write a `note` that starts with `CHANGED:` and gives the old and
     new wording.
   - closed: forqsite has fixed the gap. Remove the entry from `gap-handoff.html`. In
     `index.html`, remove its ledger row, its pipeline tag (the step becomes `ok`), and
     every mention and link, including TL;DR bullets that use the bare number. Move each
     of its claims from `claims` into a top-level `closed` array as
     `{id, gap, claim, closed_by: {commit, path}, evidence}`. `commit` is the full sha of
     the forqsite commit that closed the gap, and `evidence` holds literals at the release
     commit that show the fix.

   Where a gap entry claims something is missing ("no Dockerfile", "no entry for X"),
   record that as `absent: [{path, symbol}]`. It passes only if the path exists and the
   literal is not found there. For "this path does not exist", give `{path}` alone. Add
   `absent` entries for GAP-003, GAP-004, GAP-007 and GAP-010.
3. **Decisions already found for the MISMATCH notes.** These were observed while writing
   this spec. Confirm each one yourself; do not copy it on trust.
   - **GAP-003.** The runbook references pm2 only in §12. Change the evidence row
     `§7/§12 reference pm2` to say §12. Result: `changed`.
   - **GAP-005.** Correct the Caddyfile row to the file's literal,
     `reverse_proxy * forqsite_a:3000 forqsite_b:3000`. Result: `changed`.
   - **GAP-009.** `scripts/restore.sh` no longer turns tracing back on: it has `set +x`
     three times and no `set -x`. `git log` on that file shows the SEC-078 commit.
     Narrow the entry to `backup.sh` everywhere it appears: title, problem, the
     restore.sh evidence row, fix, done-when, and the index ledger summary. Give the
     claim a `closed_by` for the restore.sh half and an
     `absent: [{"path": "scripts/restore.sh", "symbol": "set -x"}]`. Result: `changed`.
   - **GAP-010.** Quote the first-run line exactly, as
     `sudo apt-get install -y postgresql-18-pgvector`. Move the claim that three keys are
     missing from `docs/configuration.md` into `absent` entries, and drop that remark from
     the note. Result: `changed`.
4. **New gaps.** If re-checking an entry's evidence turns up a gap that the list does not
   have, add it to both pages in the same format as the others. Its claim gets
   `location: "GAP-0NN entry, …"`, the footer stamp, `result: "added"`, and the next unused
   `C-` number. This is not a fresh audit of forqsite. When a gap closes, its ID is retired
   and never reused.
5. **Restamp** the three stamps in scope (the sidebar callout, the GAP-012 row and the
   footer) with the release commit's first 8 hex characters and today's date. Keep each
   stamp's date format, for example `24 september 2026` in the footer. Update each record's
   `text`, `commit` and `date`, and update the footer's `scope` if the list of gaps
   changed. Rebuild the Known-gaps claim's `evidence` as the deduplicated union described
   in CONTENT-030. No note may name a claim ID.

Ideology: the page keeps its forqsite `path:line` citations ("Cite the source that makes a
claim checkable"). The manifest names no host path ("Name the class, not the instance").
The bundles are changed only through the reviewed loop and `bundle-template.py`
(Generated-artifact discipline, Phase 2 exception).

Length: this spec runs past the ~100-line guideline for doc stories. The Tests script is
the only mechanical proof that the restamp was checked, and CONTENT-030 failed review
twice for lacking such a proof.

## Tests

The project has no test suite. Run this from the repo root with
`FORQSITE_CLONE=<clone path> bash <this block>`. Never write the clone path into the repo.

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
  python3 -c "import re,sys; [open(f'$S/$p.{i}.js','w').write(b) for i,b in enumerate(re.findall(r'<script type=\"text/x-dc\"[^>]*>(.*?)</script>', open('$S/$p').read(), re.S))]"
  for f in $S/$p.*.js; do node --check $f; done
  timeout 60 chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 --dump-dom "file://$PWD/$p" > $S/dom-$p 2>/dev/null
done
python3 - "$S" <<'EOF'
import datetime, json, os, re, subprocess, sys
S = sys.argv[1]; clone = os.environ['FORQSITE_CLONE']
m = json.load(open('docs/claims-manifest.json')); b = json.load(open(f'{S}/base-manifest.json'))
rel = m['release']['commit']; short = rel[:8]
assert m['release'] == b['release'], 'release pin changed'
def git(*a): return subprocess.run(['git', '-C', clone, *a], capture_output=True, text=True, errors='replace')
def show(path):
    p = git('show', f'{rel}:{path}'); assert p.returncode == 0, f'{path} not at release commit'; return p.stdout
def grep(sym, path): return git('grep', '-q', '-F', '-e', sym, rel, '--', path).returncode
T = {p: open(f'{S}/{p}').read() for p in ('index.html', 'gap-handoff.html')}
B = {p: open(f'{S}/base.{p}').read() for p in T}
stamps = {s['id']: s for s in m['stamps']}; bs = {s['id']: s for s in b['stamps']}; bc = {c['id']: c for c in b['claims']}
for p, t in T.items():
    mine = [s for s in stamps.values() if s['page'] == p]
    n = len(re.findall(r'nullvalues/forqsite@[0-9a-f]{7,40}', t))
    assert n == len(mine) == sum(t.count(s['text']) for s in mine), f'{p}: stamps in template and manifest differ'
gh = {s['id'] for s in m['stamps'] if s['page'] == 'gap-handoff.html'}
kg = [c for c in m['claims'] if c['page'] == 'index.html' and set(re.findall(r'\bS-\d+\b', c.get('note', ''))) & gh]
assert len(kg) == 1, 'expected one Known-gaps claim'; kg = kg[0]
scope = {c['id'] for c in m['claims'] if c['page'] == 'gap-handoff.html' and c['location'].startswith('GAP-')} | {kg['id']}
sc_stamps = {c['stamp'] for c in m['claims'] if c['id'] in scope}
dates = set()
for sid in sc_stamps:
    s = stamps[sid]; d = datetime.date.fromisoformat(s['date']); dates.add(d)
    assert s['commit'] == short and f'nullvalues/forqsite@{short}' in s['text'], f'{sid}: not restamped to the release commit'
    assert s['date'] in s['text'] or f"{d.day} {d.strftime('%B').lower()} {d.year}" in s['text'], f'{sid}: date not in stamp text'
assert len(dates) == 1, 'in-scope stamps carry different dates'
for s in m['stamps']:
    if s['id'] not in sc_stamps: assert s == bs.get(s['id']), f"{s['id']}: out of scope but changed"
for c in m['claims']:
    if c['id'] not in scope: assert c == bc.get(c['id']), f"{c['id']}: out of scope but changed"
def located(c):
    for e in c['evidence']: assert grep(e['symbol'], e['path']) == 0, f"{c['id']}: {e['symbol']!r} not found in {e['path']} at release"
    for a in c.get('absent', []):
        if a.get('symbol'):
            show(a['path']); assert grep(a['symbol'], a['path']) == 1, f"{c['id']}: {a['symbol']!r} is present in {a['path']}"
        else: assert git('cat-file', '-e', f"{rel}:{a['path']}").returncode != 0, f"{c['id']}: {a['path']} exists"
def closer(x):
    cb = x['closed_by']; old = bs[bc[x['id']]['stamp']]['commit']
    assert re.fullmatch(r'[0-9a-f]{40}', cb['commit']), f"{x['id']}: closed_by commit not full sha"
    assert git('merge-base', '--is-ancestor', cb['commit'], rel).returncode == 0, f"{x['id']}: closer not in release"
    assert git('merge-base', '--is-ancestor', cb['commit'], old).returncode != 0, f"{x['id']}: closer predates old stamp"
    assert cb['path'] in git('show', '--name-only', '--format=', cb['commit']).stdout.split(), f"{x['id']}: closer does not touch {cb['path']}"
for c in m['claims']:
    if c['id'] not in scope: continue
    assert not c.get('note', '').startswith('MISMATCH:'), f"{c['id']}: MISMATCH unresolved"
    located(c)
    if c is kg: continue
    r = c.get('result'); assert r in ('open', 'changed', 'added'), f"{c['id']}: no verification result"
    if bc.get(c['id'], {}).get('note', '').startswith('MISMATCH:'): assert r == 'changed', f"{c['id']}: MISMATCH resolved without a page change"
    assert c['quote'] in T['gap-handoff.html'], f"{c['id']}: quote not on page"
    if r in ('changed', 'added'): assert c['quote'] not in B['gap-handoff.html'], f"{c['id']}: {r} but quote unchanged"
    if r == 'changed': assert c.get('note', '').startswith('CHANGED:'), f"{c['id']}: changed without CHANGED: note"
    if r == 'added': assert c['id'] not in bc, f"{c['id']}: added reuses an ID"
    if 'closed_by' in c: closer(c)
closed = m.get('closed', [])
for x in closed:
    assert x['id'] in bc and x['id'] not in {c['id'] for c in m['claims']}, f"{x['id']}: bad closed record"
    assert x['gap'] in B['gap-handoff.html'] and all(x['gap'] not in t for t in T.values()), f"{x['gap']}: closed but still listed"
    closer(x); located(x)
base_scope = {c['id'] for c in b['claims'] if c['page'] == 'gap-handoff.html' and c['location'].startswith('GAP-')}
assert base_scope <= scope | {x['id'] for x in closed}, 'a gap claim vanished without a closed record'
foot = (set(re.findall(r'\bS-\d+\b', kg['note'])) & gh).pop(); key = lambda e: (e['path'], e['symbol'])
union = {key(e) for c in m['claims'] if c['stamp'] == foot for e in c['evidence']}
got = [key(e) for e in kg['evidence']]
assert union and len(got) == len(set(got)) and set(got) == union, 'Known-gaps evidence is not the footer-stamp union'
for x in m['claims'] + m['stamps'] + closed:
    assert not re.search(r'\bC-\d+', x.get('note', '')), f"{x['id']}: note references a claim ID"
ids = re.findall(r"mk\('(GAP-\d+)'", T['gap-handoff.html'])
assert ids == re.findall(r"\{ id: '(GAP-\d+)'", T['index.html']), 'index ledger differs from gap-handoff list'
assert set(re.findall(r"gap: '(GAP-\d+)'", T['index.html'])) <= set(ids), 'pipeline tags a gap not listed'
assert set(re.findall(r'gap-handoff\.html#(gap-\d+)', T['index.html'])) <= {i.lower() for i in ids}, 'index links a gap not listed'
pri = re.findall(r"mk\('GAP-\d+', '(P\d)'", T['gap-handoff.html'])
for p, n in re.findall(r'(P\d) — [^<×]*× (\d+)', T['gap-handoff.html']): assert pri.count(p) == int(n), f'{p} chip count wrong'
for path, n in re.findall(r"\['([\w./-]+):(\d+)(?:-\d+)?'", T['gap-handoff.html']):
    line = show(path).splitlines()[int(n) - 1]
    syms = [e['symbol'] for c in m['claims'] if c['id'] in scope for e in c['evidence'] if e['path'] == path]
    assert any(s in line for s in syms), f'{path}:{n} holds no cited symbol at release'
for p in T:
    d = re.sub(r'(?is)<script\b.*?</script>', '', open(f'{S}/dom-{p}').read())
    assert f'nullvalues/forqsite@{short}' in d, f'{p}: release stamp not rendered'
d = re.sub(r'(?is)<script\b.*?</script>', '', open(f'{S}/dom-gap-handoff.html').read())
assert set(re.findall(r'GAP-\d{3}', d)) == set(ids), 'rendered gap list differs from template list'
print('OK', len(scope), 'claims in scope,', len(closed), 'closed')
EOF
! grep -nE '/mnt/|/home/|~/' docs/claims-manifest.json
```

Pass means the script prints `OK` and exits 0. The reviewer also reads each gap entry
against the forqsite clone at the release commit. For every `open` result, the reviewer
confirms that the entry's prose, not only its literals, still holds. The reviewer also
confirms the page's parenthetical `(:357)` citation in GAP-012.

## Out of scope

- Claims outside the Known gaps entries: the Operations and Promoting a change stamps and
  the `gap-handoff.html` intro ordering assumption (CER-029). Those belong to CONTENT-032,
  and so does the one-commit-per-page pin. `gap-handoff.html` keeps its old intro stamp
  until CONTENT-032.
- Unstamped `index.html` prose that mentions a gap, except where a gap has closed or its
  entry changed as described above.
- Rewording that re-verification does not require, and a fresh audit of forqsite for gaps.
- Deploying, a committed checker script, or any automation (Phase 13).
- Changing the manifest's `release` pin or the schema of claims outside scope.
