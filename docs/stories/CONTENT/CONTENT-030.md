---
id: CONTENT-030
rail: CONTENT
title: Inventory every stamped claim into a committed claims manifest
status: draft
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - docs/claims-manifest.json
touches:
  - docs/phases/phase-12.md
  - docs/architecture.md
narrative_roles: []
---

## Context

Both published pages stamp their claims about forqsite with `nullvalues/forqsite@<sha>` and a
date, and the stamps have drifted apart. As of this spec there are 4 in `index.html` (1 ×
`17b78645`, 3 × `7089b9dc`) and 3 in `gap-handoff.html` (2 × `17b78645`, 1 × `7089b9dc`).
CONTENT-031 and CONTENT-032 re-verify and restamp them. Both need a list of what each stamp
covers, where each claim's evidence lives in forqsite, and one forqsite commit to verify
against. This story builds that list and pins that commit. It verifies nothing and
changes neither page.

## Requires

- Phase 12 is specced (`docs/phases/phase-12.md`). No earlier Phase 12 story needs to be done.
- `python3 scripts/bundle-template.py verify` passes on both bundles.
- A local clone of `nullvalues/forqsite`, fetched, is available on the build host.

## Ensures

`docs/claims-manifest.json` exists. It has one stamp record for each
`nullvalues/forqsite@<hex>` occurrence in each page's extracted template, and each record's
exact `text` is present in that template. Every stamp is cited by at least one claim. Every
claim cites an existing stamp, has a `quote` that appears word for word in its page's
template, and gives evidence as a forqsite repo-relative path plus a symbol or behaviour.
The manifest pins one 40-hex release commit with its commit date, and
`docs/phases/phase-12.md` records the same commit. Neither the manifest nor the phase doc
contains a host path. `index.html` and `gap-handoff.html` are byte-identical to `main`.
Forbidden proxy: stamp counts or claims taken by grepping the bundles rather than the
`extract` output, and claim text that paraphrases a page claim with no `quote` behind it.

## Instructions

1. **Extract, don't grep.** Run `python3 scripts/bundle-template.py extract <page> <scratch>`
   for both pages into a scratch directory outside the repo, and work only from those
   templates. The JSON-escaped bundle hides `/` as `/`, so grepping it for stamps
   undercounts.
2. **Pin the release commit.** In the forqsite clone, run `git fetch` and then take the tip
   of `origin/main`. Record the full sha (`git rev-parse`), its commit date
   (`git log -1 --format=%cs`) and today's date as the pin date. Put them in the manifest's
   `release` object and in a new `## Release commit` section of `docs/phases/phase-12.md`,
   placed just above `## Stories`. That section gives the commit and both dates and names
   the manifest as the authoritative copy. Never write where the clone lives: the manifest
   and phase doc say "the forqsite repository" or `nullvalues/forqsite@<sha>`, per
   `docs/ideology.md` § "Name the class, not the instance".
3. **Manifest shape.** Use JSON so that a later checker needs only the Python standard library:
   ```json
   {
     "release": {"repo": "nullvalues/forqsite", "commit": "<40 hex>", "committed": "YYYY-MM-DD", "pinned": "YYYY-MM-DD"},
     "stamps": [{"id": "S-01", "page": "index.html", "location": "<route/section/element, human-readable>",
                 "text": "<exact template substring containing the forqsite@<sha> token>",
                 "commit": "<sha as printed>", "date": "YYYY-MM-DD", "scope": "<what this stamp covers>"}],
     "claims": [{"id": "C-001", "page": "gap-handoff.html", "location": "...", "claim": "<one sentence>",
                 "quote": "<short verbatim template substring that makes the claim>",
                 "evidence": [{"path": "<forqsite repo-relative path>", "symbol": "<symbol or behaviour>"}],
                 "stamp": "S-01"}]
   }
   ```
   A claim points to its stamp by `stamp` id. Store the commit and date on the stamp record
   only, not on each claim, so the same fact is not kept in two places.
4. **What each stamp covers.** A section-footer stamp covers the claims in that section, back
   to the previous heading or stamp. An inline stamp covers its own sentence or paragraph.
   A table-row stamp, such as the `checked at this commit` row in `gap-handoff.html`, covers
   the rows above it in that table. The `gap-handoff.html` footer stamp covers every GAP
   entry. The `index.html` sidebar stamp under "Known gaps →" is the Known gaps callout. Give
   it one claim, "the linked gaps list is current at this commit", and let that claim's
   evidence be the union of the GAP claims' evidence. When a stamp's reach is ambiguous, say
   which reading you took in its `scope` field.
5. **Evidence.** Where the page already cites a path, use it. Otherwise find the evidence
   in the forqsite clone at the stamp's own commit (`git -C <clone> grep` /
   `git show <sha>:<path>`). Record a repo-relative path plus a symbol or behaviour, and no
   line numbers, because line numbers drift. This is locating evidence, not re-verifying
   the claim. Whether the claim still holds at the release commit is for CONTENT-031 and
   CONTENT-032 to decide. If a claim has no findable evidence, keep it, use `"evidence": []`,
   and add a `"note"` saying why.
6. **Claims and quotes.** List only claims the pages make. Don't split one sentence into
   several claims, and don't list unstamped content. Each `quote` must be long enough to
   point at the claim clearly but short enough to stay stable.
7. **`docs/architecture.md`.** Add `docs/claims-manifest.json` to § Module structure. Add
   one or two sentences after the Editing procedure saying what it is and that the stories
   that re-verify claims update it. Do not describe its schema there, because the file
   already shows it.

Ideology check: this story leaves the bundles alone (Generated-artifact discipline) and
changes no page. The manifest keeps the pages' forqsite source citations, which "Cite the
source that makes a claim checkable" requires. It names no path on our own hosts, which
"Name the class, not the instance" forbids. The Tests section counts from `extract` output,
because counting from the bundle would be the proxy that "Assert the invariant, not a
proxy for it" rules out.

Preflight notes: `scripts/bundle-template.py` and `docs/ideology.md` are only read, so they
are not listed in `touches:`. `YYYY` is a date placeholder, not a constant. Length: this spec
runs past the ~100-line doc-story guideline because it has to fix a schema that two later
stories and a later checker all depend on. The Tests script is its acceptance check.

## Tests

The project has no test suite. Run this from the repo root:

```bash
S=$(mktemp -d)
for p in index.html gap-handoff.html; do python3 scripts/bundle-template.py verify $p && python3 scripts/bundle-template.py extract $p $S/$p; done
python3 - "$S" <<'EOF'
import json, re, sys
S = sys.argv[1]; m = json.load(open('docs/claims-manifest.json'))
r = m['release']; assert re.fullmatch(r'[0-9a-f]{40}', r['commit']) and r['committed'] and r['pinned']
assert r['commit'] in open('docs/phases/phase-12.md').read(), 'release commit not in phase doc'
stamps = {s['id']: s for s in m['stamps']}
for page in ('index.html', 'gap-handoff.html'):
    t = open(f'{S}/{page}').read()
    found = len(re.findall(r'nullvalues/forqsite@[0-9a-f]{7,40}', t))
    mine = [s for s in stamps.values() if s['page'] == page]
    assert found == len(mine), f'{page}: {found} stamps in template, {len(mine)} in manifest'
    assert sum(t.count(s['text']) for s in mine) == found, f'{page}: stamp text mismatch'
    for c in m['claims']:
        if c['page'] == page: assert c['quote'] in t, f"{c['id']}: quote not in {page}"
cited = {c['stamp'] for c in m['claims']}
assert cited <= set(stamps), 'claim cites unknown stamp'
assert set(stamps) <= cited, f'uncovered stamps: {set(stamps) - cited}'
for c in m['claims']:
    assert c['evidence'] or c.get('note'), c['id']
    for e in c['evidence']: assert e['path'] and not e['path'].startswith(('/', '~')) and e['symbol'], c['id']
print('OK', len(stamps), 'stamps,', len(m['claims']), 'claims')
EOF
grep -nE '/mnt/|/home/|~/' docs/claims-manifest.json docs/phases/phase-12.md; test $? -eq 1
git diff --quiet main -- index.html gap-handoff.html
```

Pass means the script prints `OK`, the host-path grep finds nothing, and `git diff` exits
0. The reviewer also reads every claim against its `location` and checks that none is
invented.

## Out of scope

- Re-verifying any claim, closing any gap or changing any stamp. That is CONTENT-031 (Known
  gaps) and CONTENT-032 (everything else).
- Editing either bundle.
- Listing claims that carry no stamp.
- A committed checker script or any automation. The Tests snippet is for review only; a
  stale-claim checker is Phase 13 work.
- Resolving CER-029, which is taken over by the phase as a whole and closed by CONTENT-032.
