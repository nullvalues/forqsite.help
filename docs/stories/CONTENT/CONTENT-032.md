---
id: CONTENT-032
rail: CONTENT
title: Re-verify and restamp every remaining claim, and pin the pages to one release commit
status: complete
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
  - gap-handoff.html
touches:
  - docs/claims-manifest.json
  - docs/cer/backlog.md
narrative_roles: []
---

## Context

After CONTENT-031, the Known gaps stamps (S-01, S-06, S-07) carry the release commit that
CONTENT-030 pinned in `docs/claims-manifest.json`. The four other stamps still carry older
commits: the Operations "Upgrade" and "Provider packs (condensed)" footers and the
Promoting a change footer (all `7089b9dc`), and the `gap-handoff.html` intro ordering
assumption (`17b78645`, CER-029). This story re-verifies every claim those stamps cover at
the release commit, corrects the page where forqsite has moved, and restamps them. Both
pages then name one forqsite commit, and the release is deployed. Deployment happens after
merge. It faces the public, so only the orchestrator runs it, and only once the operator
confirms.

## Requires

- CONTENT-031 is merged. Every stamp whose base `commit` equals `release.commit[:8]` is
  treated as already verified and is left alone.
- A fetched forqsite clone contains `release.commit`, and its path is passed on the
  command line as `FORQSITE_CLONE`. The path is never written into the repo.
- `python3 scripts/bundle-template.py verify` passes on both bundles.

## Ensures

**Pre-merge (reviewer).** Scope is derived, not listed. It covers every base-manifest stamp
whose `commit` is not the release short sha, and every claim that cites one of those stamps.
Every stamp in the manifest and in both extracted templates reads
`nullvalues/forqsite@<release.commit[:8]>`. The signal is one check per page:
`extract` + `grep -oE 'nullvalues/forqsite@[0-9a-f]{7,40}' | sort -u` prints exactly one
line. The stamps in scope carry the verification date inside their text. Each claim in scope
has a `result` of `open`, `changed` or `unverified`:
- `open`: the page quote is unchanged.
- `changed`: the note starts with `CHANGED:` and the quote is new to the page.
- `unverified`: the note starts with `UNVERIFIED:` and gives the reason, and a `marker`
  field holds a new on-page phrase containing "not verified".

A claim that had a `MISMATCH:` note is now `changed`. Every evidence literal is a
`git grep -F` hit at the release commit. Every `absent` entry is a verified miss there. Every
`counts` entry matches `git ls-tree` there and its number appears in the quote. Stamps,
claims and `closed` records outside scope are byte-identical to the base manifest. CER-029
carries a resolution marker. A new CER row records the stale restore example (see
Instructions 5). Both bundles verify, and their scripts pass `node --check`. The rendered
DOM of `index.html`, `index.html#ops`, `index.html#promote` and `gap-handoff.html`, with
`<script>` stripped first (CER-005, CER-012), names only the release commit and shows every
in-scope stamp's text.

**Post-merge (orchestrator, operator-confirmed).** After merge, `scripts/drift-check.sh
--ref <deployed sha>` exits 0 against the deployed site. Its `provenance` line names that
same sha, and that sha's bundles are byte-identical to the CONTENT-032 merge's.

Forbidden proxy:
- a stamp rewritten without a per-claim `result` behind it
- a claim that could not be verified carrying a fresh stamp and no on-page marker
- the one-commit check run over the JSON-escaped bundle instead of the `extract` output
- "deployed" asserted from `deploy.sh` exiting 0 or from the sidecar alone, rather than from
  a drift check of the served bytes

## Instructions

1. **Workflow.** Follow `docs/architecture.md` § Editing procedure: `verify`, then `extract`
   into a scratch directory outside the repo, edit only there, then `inject` and `verify`.
   Never hand-splice a bundle.
2. **Re-verify each claim in scope at `release.commit`.** Use `git grep -F`,
   `git show <release>:<path>` and `git log <old stamp commit>..<release> -- <paths>` in the
   clone. Re-read the whole covered section, not just the literals the manifest holds, and
   record `open`, `changed` or `unverified` using CONTENT-031's conventions (`quote`, a
   `CHANGED:` note giving the old and new wording, `absent` for "there is no X"). A claim
   whose truth is a file count gets
   `"counts": [{"path": "<dir>", "suffix": "<ext>", "n": N}]`. Found while writing this
   spec; confirm each yourself:
   - The "Upgrade" paragraph's `95 forward` migrations carries a `MISMATCH:` note. The
     release has 100 `.sql` files. Correct the count and add a `counts` entry.
   - The Promoting-a-change manifest claim notes that `config/providers.json` is not
     committed. Verify what the build resolves and keep that note if it still holds.
   - The GAP entries are already verified. Do not re-open them.
3. **CER-029: the ordering assumption.** It is the page's own premise, not a forqsite fact.
   Verify it as "at the release commit, forqsite's production documentation still treats
   Postgres and MinIO as network services and compose as a development convenience". Weigh
   `docs/deployment/docker-compose.rolling.yml` and `scripts/rolling-restart.sh`, which
   exist at the release commit. If forqsite now documents docker as a supported production
   path, and the gap ordering would need re-sequencing, stop and report to the orchestrator.
   Re-sequencing is a content decision this story does not take. Otherwise record `open` or
   `changed` with evidence. Then add `**RESOLVED Phase 12 — CONTENT-032.**` and one sentence
   of outcome to the CER-029 row in `docs/cer/backlog.md`.
4. **Unverifiable claims.** Mark the page next to the claim with a short phrase containing
   "not verified" and the reason. Record the phrase as `marker` and set
   `result: "unverified"` with a note that starts with `UNVERIFIED:`. The covering stamp
   still reads the release commit, so the page names one commit. The marker is what stops
   the stamp from vouching for that claim. If correcting a claim would mean deleting it
   outright, stop and report instead.
5. **The restore example is out of scope, and gets recorded.** The Backup & recovery
   "Restore procedure" block in `index.html` calls `scripts/restore.sh` with only the dump
   file. forqsite commit `1ab2405c` (SEC-078) made a second `<expected-database-name>`
   argument mandatory. No stamp covers that route, so the example is not a stamped claim.
   Leave it unchanged. Add a new row, CER-038, to the **Do Now** section of
   `docs/cer/backlog.md`: the published restore command now fails its usage check, Source
   `CONTENT-031 builder`, Phase `12`. The operator may re-triage it at the checkpoint CER
   review.
6. **Restamp** S-02 to S-05 with the release commit's first 8 hex characters and today's
   date, keeping each stamp's own format. Update each record's `text`, `commit` and `date`.
   No note may name a claim ID. Name no host, directory or URL anywhere.

Ideology: forqsite citations stay as written ("Cite the source that makes a claim
checkable"). The manifest, the backlog and this story name no deployment instance ("Name
the class, not the instance"). The one-commit check runs over `extract` output, and deploy
is judged by served bytes ("Assert the invariant, not a proxy for it"). Bundles change only
through `bundle-template.py` (Generated-artifact discipline).

Length: this spec runs past the ~100-line guideline for doc stories. The Tests script is
the only mechanical proof that the restamp was checked, and it follows CONTENT-031's
pattern.

## Tests

The project has no test suite. Run this from the repo root with
`FORQSITE_CLONE=<clone path> bash <this block>`. Do not source `scripts/deploy.env`.

```bash
set -e
: "${FORQSITE_CLONE:?set FORQSITE_CLONE to the local forqsite clone}"
S=$(mktemp -d); BASE=$(git merge-base HEAD main)
git show $BASE:docs/claims-manifest.json > $S/base-manifest.json
SHORT=$(python3 -c "import json; print(json.load(open('docs/claims-manifest.json'))['release']['commit'][:8])")
for p in index.html gap-handoff.html; do
  python3 scripts/bundle-template.py verify $p
  python3 scripts/bundle-template.py extract $p $S/$p
  test "$(grep -oE 'nullvalues/forqsite@[0-9a-f]{7,40}' $S/$p | sort -u)" = "nullvalues/forqsite@$SHORT"
  git show $BASE:$p > $S/base-bundle-$p
  python3 scripts/bundle-template.py extract $S/base-bundle-$p $S/base.$p
  python3 -c "import re; [open(f'$S/$p.{i}.js','w').write(b) for i,b in enumerate(re.findall(r'<script type=\"text/x-dc\"[^>]*>(.*?)</script>', open('$S/$p').read(), re.S))]"
  for f in $S/$p.*.js; do node --check $f; done
done
for v in index.html index.html#ops index.html#promote gap-handoff.html; do
  timeout 60 chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 --dump-dom "file://$PWD/$v" > "$S/dom-${v//#/_}" 2>/dev/null
done
python3 - "$S" <<'EOF'
import glob, html, json, os, re, subprocess, sys
S = sys.argv[1]; clone = os.environ['FORQSITE_CLONE']
m = json.load(open('docs/claims-manifest.json')); b = json.load(open(f'{S}/base-manifest.json'))
rel = m['release']['commit']; short = rel[:8]
assert m['release'] == b['release'], 'release pin changed'
def git(*a): return subprocess.run(['git', '-C', clone, *a], capture_output=True, text=True, errors='replace')
def grep(sym, path): return git('grep', '-q', '-F', '-e', sym, rel, '--', path).returncode
T = {p: open(f'{S}/{p}').read() for p in ('index.html', 'gap-handoff.html')}
B = {p: open(f'{S}/base.{p}').read() for p in T}
stamps = {s['id']: s for s in m['stamps']}; bs = {s['id']: s for s in b['stamps']}; bc = {c['id']: c for c in b['claims']}
for p, t in T.items():
    mine = [s for s in stamps.values() if s['page'] == p]
    n = len(re.findall(r'nullvalues/forqsite@[0-9a-f]{7,40}', t))
    assert n == len(mine) == sum(t.count(x) for x in {s['text'] for s in mine}), f'{p}: stamps in template and manifest differ'
sc_stamps = {i for i, s in bs.items() if s['commit'] != short}
assert sc_stamps and set(stamps) == set(bs), 'stamp set changed or nothing in scope'
for s in m['stamps']:
    assert s['commit'] == short and f'nullvalues/forqsite@{short}' in s['text'], f"{s['id']}: not the release commit"
    if s['id'] in sc_stamps: assert s['date'] in s['text'], f"{s['id']}: date not in stamp text"
    else: assert s == bs[s['id']], f"{s['id']}: out of scope but changed"
scope = {c['id'] for c in b['claims'] if c['stamp'] in sc_stamps}
assert scope == {c['id'] for c in m['claims'] if c['stamp'] in sc_stamps}, 'in-scope claim set changed'
for c in m['claims']:
    if c['id'] not in scope: assert c == bc[c['id']], f"{c['id']}: out of scope but changed"
assert m.get('closed', []) == b.get('closed', []), 'closed records changed'
for c in m['claims']:
    if c['id'] not in scope: continue
    i, t, bt = c['id'], T[c['page']], B[c['page']]
    assert not c.get('note', '').startswith('MISMATCH:'), f'{i}: MISMATCH unresolved'
    for e in c['evidence']: assert grep(e['symbol'], e['path']) == 0, f"{i}: {e['symbol']!r} not in {e['path']} at release"
    for a in c.get('absent', []):
        if a.get('symbol'):
            assert git('cat-file', '-e', f"{rel}:{a['path']}").returncode == 0 and grep(a['symbol'], a['path']) == 1, f"{i}: absent {a} not a verified miss"
        else: assert git('cat-file', '-e', f"{rel}:{a['path']}").returncode != 0, f"{i}: {a['path']} exists"
    for k in c.get('counts', []):
        names = git('ls-tree', '--name-only', rel, k['path'].rstrip('/') + '/').stdout.split()
        assert sum(n.endswith(k['suffix']) for n in names) == k['n'] and str(k['n']) in c['quote'], f'{i}: count wrong'
    r = c.get('result'); assert r in ('open', 'changed', 'unverified'), f'{i}: no verification result'
    if bc[i].get('note', '').startswith('MISMATCH:'): assert r == 'changed', f'{i}: MISMATCH resolved without a page change'
    assert c['quote'] in t, f'{i}: quote not on page'
    if r == 'open': assert c['quote'] in bt, f'{i}: open but quote changed'
    if r == 'changed': assert c['quote'] not in bt and c.get('note', '').startswith('CHANGED:'), f'{i}: changed claim not evidenced'
    if r == 'unverified':
        mk = c.get('marker', '')
        assert c.get('note', '').startswith('UNVERIFIED:') and 'not verified' in mk.lower() and mk in t and mk not in bt, f'{i}: unverified without marker'
for x in m['claims'] + m['stamps']:
    assert not re.search(r'\bC-\d+', x.get('note', '')), f"{x['id']}: note references a claim ID"
flat = lambda s: html.unescape(re.sub(r'<[^>]+>', '', s))
seen = ''
for f in glob.glob(f'{S}/dom-*'):
    d = re.sub(r'(?is)<script\b.*?</script>', '', open(f).read())
    assert set(re.findall(r'nullvalues/forqsite@([0-9a-f]{7,40})', d)) == {short}, f'{f}: rendered stamps not the release commit alone'
    seen += flat(d)
for i in sc_stamps: assert flat(stamps[i]['text']) in seen, f'{i}: stamp not rendered'
print('OK', len(scope), 'claims in scope,', len(sc_stamps), 'stamps restamped')
EOF
if grep -nE '/mnt/|/home/|~/' docs/claims-manifest.json; then exit 1; fi
if git diff -U0 $BASE -- docs/cer/backlog.md | grep '^+' | grep -vE '^\+\+\+' | grep -nE '/mnt/|/home/|~/'; then exit 1; fi
grep -E '^\| CER-029 ' docs/cer/backlog.md | grep -qF '**RESOLVED Phase 12 — CONTENT-032'
grep -E '^\| CER-038 ' docs/cer/backlog.md | grep -q 'restore.sh'
```

Pass means the script prints `OK` and every line exits 0. The reviewer also reads each
covered section against the clone at the release commit. For each `open` claim, the reviewer
confirms the prose still holds, not only the literals. For CER-029, the reviewer confirms
that the recorded evidence supports the non-docker premise. The reviewer never runs
`deploy.sh` or `drift-check.sh`.

## Post-merge: deploy (orchestrator only, after operator confirmation)

Run this step after CONTENT-032 and its merge-status sync are on `main`. Ask the operator
first, and wait for an explicit yes. From a clean tree on this host, with the gitignored
`scripts/deploy.env` in place:

```bash
REF=$(git rev-parse main)
git diff --quiet $(git log -1 --format=%H --grep='story-CONTENT-032') $REF -- index.html gap-handoff.html
scripts/deploy.sh --ref $REF
scripts/drift-check.sh --ref $REF
```

Done means `drift-check.sh` exits 0 and its `provenance` line reads `claims $REF deployed
…`. Record the deployed sha, the date and the exit status in the phase-12 checkpoint
record. Name the site by class ("the public site"), never by host, directory or URL. If the
drift check fails, the deploy is not done: report the exit code to the operator and do not
retry blind.

## Out of scope

- Correcting the Backup & recovery restore example. It is unstamped and filed as CER-038
  (Instructions 5).
- The Known gaps entries and stamps S-01, S-06 and S-07, which CONTENT-031 handled.
- Unstamped prose, rewording that re-verification does not require, and re-sequencing the
  gap list.
- Any change to `scripts/deploy.sh`, `scripts/drift-check.sh`, `scripts/deploy.env` or its
  example, and any deploy by the builder or reviewer.
- A committed checker script, a release trigger or any automation (Phase 13).
- Changing the manifest's `release` pin.
