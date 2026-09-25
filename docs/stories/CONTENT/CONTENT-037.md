---
id: CONTENT-037
rail: CONTENT
title: Scrub operator-local absolute paths from tracked docs, and record the cp-12 security findings
status: complete
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - docs/cer/backlog.md
  - docs/ideology.md
  - docs/phases/phase-2.md
  - docs/phases/phase-5.md
  - docs/exemplars/EXEMPLAR-000.md
touches:
  - docs/stories/CONTENT/CONTENT-001.md
  - docs/stories/CONTENT/CONTENT-002.md
  - docs/stories/CONTENT/CONTENT-005.md
  - docs/stories/CONTENT/CONTENT-008.md
  - docs/stories/CONTENT/CONTENT-016.md
  - docs/stories/CONTENT/CONTENT-017.md
  - docs/stories/CONTENT/CONTENT-018.md
  - docs/stories/CONTENT/CONTENT-019.md
  - docs/stories/CONTENT/CONTENT-020.md
  - docs/stories/CONTENT/CONTENT-021.md
  - docs/stories/CONTENT/CONTENT-024.md
  - docs/stories/CONTENT/CONTENT-025.md
  - docs/stories/CONTENT/CONTENT-029.md
  - docs/stories/INFRA/INFRA-006.md
  - docs/stories/INFRA/INFRA-007.md
  - docs/stories/INFRA/INFRA-008.md
  - docs/stories/INFRA/INFRA-009.md
  - docs/stories/INFRA/INFRA-010.md
  - docs/stories/INFRA/INFRA-011.md
  - docs/stories/INFRA/INFRA-012.md
  - docs/stories/INFRA/INFRA-013.md
  - docs/stories/INFRA/INFRA-014.md
narrative_roles: []
---

## Context

The CP-12 security re-audit found operator-local absolute paths in tracked docs. This
repository is public. On 2026-09-25 the operator decided to scrub two classes before
tagging cp-12:

- **(A) Planning docs:** `docs/ideology.md`, `docs/phases/phase-2.md`,
  `docs/phases/phase-5.md` and `docs/exemplars/EXEMPLAR-000.md`. They name the local
  forqsite clone's path, report a path on the original build machine, or use the same
  prefix in an illustrative `--path` example.
- **(B) Completed story specs:** the 22 in `touches:`. Their Requires, Instructions or
  Tests name the clone's path, this repository's own path (`cd` lines and `file://` render
  URLs), or the old build-machine path.

The rule is "Name the class, not the instance" (`docs/ideology.md`). The same audit left
two smaller findings, which are recorded here as backlog rows. No page, stamp or manifest
changes. The files are completed historical records, so each edit replaces only the
identifier and keeps its meaning.

## Requires

- CONTENT-036 is merged, so the backlog's highest ID is CER-049.
- The local forqsite clone is on disk. The Tests script takes its path from
  `FORQSITE_CLONE` and never spells it.

## Ensures

After the scrub, no tracked file names this repository's absolute path, the forqsite
clone's path, their parent directory, or the operator's home directory. Each changed line
in the 26 scrubbed files differs from base only in the identifier's own tokens. Class C
files and the pages, manifest and `scripts/` are byte-identical to base. The backlog gains
exactly CER-050 (the leak, resolved) and CER-051 (U+200B, Do Later), plus an appended note
on CER-049. The Tests script checks all of this and prints `OK` then `DONE`.

## Instructions

1. **Find the occurrences.** Run `git grep -n -F` for the clone's path, for this
   repository's path and for their parent directory. Build the patterns from your own
   environment, as the Tests script does. The hits must be exactly the 26 files in
   `primary_files`/`touches` (minus the backlog). Test 0 in the script asserts this.
2. **Replace each occurrence in place, using its class.** Keep the line, its wrapping, and
   every other word. Do not re-wrap, even when a line gets longer.
   - **The clone.** In runnable commands, use `"$FORQSITE_CLONE"`, for example
     `cd "$FORQSITE_CLONE"`, `git -C "$FORQSITE_CLONE" status` or
     `"$FORQSITE_CLONE"/scripts/scheduler.ts`. In prose and Requires bullets, write
     "the local forqsite clone" and drop the backticks.
   - **This repository.** In a `cd` line, only the path token changes:
     `cd "$(git rev-parse --show-toplevel)"`, which keeps any `&& ./scripts/...` tail.
     In prose, write "the repository root". Known limitation: CONTENT-005's Step 1 block
     changes into the clone. A reader who runs its later blocks in the same shell must
     return to the repository root first. Leave this unfixed, because the fix would reword
     a historical spec.
   - **`file://` render URLs.** Use `file://$PWD/index.html#…` (or `gap-handoff.html#…`).
     In a command, change the surrounding single quotes to double quotes so that `$PWD`
     expands. These run from the repository root.
   - **The old build machine's path** (`file:` plus the old prefix, in phase-5, CONTENT-005
     and CONTENT-008). Use a class description that keeps the historical meaning. For
     example, "a `file:` URL, an absolute path on the original build machine", or "the
     original build machine's path is gone from both bundles" for phase-5's gate line.
   - **EXEMPLAR-000's `--path` example.** The paragraph already names the path `P`, so use
     `--path P/` and `--path P`.
3. **Leave alone:**
   - The flex tooling path (`~/flex-marketplace-cache/...`) wherever it appears.
   - CONTENT-025's `~/flex-findings-…` operator-file references.
   - The host-path regexes in CONTENT-030 to CONTENT-036.
   - Every `status:` field.
4. **Backlog** (`docs/cer/backlog.md`). Use Date `2026-09-25`, Phase `12`, and Source
   `security-auditor (CP-12 re-run)`.
   - **CER-050, Do Now.** Operator-local absolute paths in tracked planning docs and
     completed story specs, described by class: the local forqsite clone, this repository's
     own path in `cd` lines and `file://` render URLs, and a path on the original build
     machine. Then `**RESOLVED Phase 12 — CONTENT-037.**` and how each class was replaced.
     Say that the flex tooling path was left alone as tooling configuration.
   - **CER-051, Do Later, open.** In `index.html`, each copy-paste block that opens with a
     comment line begins that line with U+200B. At the release commit that is 5 blocks
     (confirm the count with `bundle-template.py extract`). Pasted into bash, the line runs
     as a command and prints `…#: command not found`. This is harmless, but it is a wart in
     "safe to copy". Fix shape: drop the U+200B, or put it somewhere else.
   - **CER-049, appended note.** Keep the Source, Date and Phase cells unchanged. Attribute
     the note inline, for example "(security-auditor, CP-12 re-run)". The note says that the
     backup caption's "the dump comes from the database the app runs against" does not
     strictly hold when a process manager also sets `DATABASE_URL`. The app's `start` omits
     `-o` and the page's backup uses it, so this is the same `-o` reconciliation. No segment
     may start with RESOLVED, SUPERSEDED or OBSOLETE.
   - No other row changes. Neither the new text nor this story may name an identifier or the
     operator's username. Describe by class only (see "A partial scrub is not a scrub").
5. `docs/exemplars/EXEMPLAR-000.md` is rendered from flex's own template, so a future flex
   sync may bring the illustrative path back. That is a tooling matter. It gets no backlog
   row (no CERs for tooling), and Test 1 will catch it if it happens.

Ideology: this applies "Name the class, not the instance" and redacts the finding that
reports the leak. The completed specs stay historical records: only the identifier token
changes, which Test 3 enforces token by token.

Preflight notes: `DATABASE_URL` is a forqsite environment variable quoted in CER-049's note,
and `DONE` is the Tests script's sentinel line. Neither is defined in this tree.

Length: past ~100 lines, because the Tests script has to prove the scrub mechanically
without spelling what it scrubs.

## Tests

The project has no test suite. Save this block to a scratch file outside the repo, then run
it from the repository root with `FORQSITE_CLONE=<path to the local forqsite clone> bash <file>`.
It builds every search needle at run time, from `$PWD`, the main checkout's root,
`$FORQSITE_CLONE`, `$HOME` and their parent directories, and never prints them. On `main`
before the build, it fails at test 1 and lists the leaking files by path.

```bash
set -e
: "${FORQSITE_CLONE:?run as FORQSITE_CLONE=<path to the local forqsite clone> bash <file>, from the repository root}"
BASE=$(git merge-base HEAD main)
ROOT=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
python3 - "$BASE" "$ROOT" <<'EOF'
import difflib, os, re, subprocess, sys
BASE, ROOT = sys.argv[1:3]
CLONE = os.environ['FORQSITE_CLONE']
def git(*a): return subprocess.run(['git', *a], capture_output=True, text=True).stdout
def at_base(p): return git('show', f'{BASE}:{p}')
# Needles come from the command line and the environment; none is spelled here.
cands = {os.getcwd(), ROOT, CLONE, os.path.realpath(CLONE), os.environ['HOME']}
cands |= {os.path.dirname(c.rstrip('/')) for c in list(cands)}
NEEDLES = sorted({c.rstrip('/') for c in cands if c.rstrip('/').count('/') >= 2})
USER = os.path.basename(os.environ['HOME'].rstrip('/'))
assert NEEDLES, 'no identifier to search for'
print(f'searching for {len(NEEDLES)} identifiers (not printed)')
has = lambda s: any(n in s for n in NEEDLES)
SCRUB = ['docs/ideology.md', 'docs/phases/phase-2.md', 'docs/phases/phase-5.md', 'docs/exemplars/EXEMPLAR-000.md'] + \
  [f'docs/stories/CONTENT/CONTENT-{n:03d}.md' for n in (1, 2, 5, 8, 16, 17, 18, 19, 20, 21, 24, 25, 29)] + \
  [f'docs/stories/INFRA/INFRA-{n:03d}.md' for n in range(6, 15)]
OWN = {'docs/cer/backlog.md', 'docs/stories/CONTENT/CONTENT-037.md', 'docs/phases/phase-12.md'}
ALLOWED = set()   # files allowed to keep an identifier, by path; expected empty
grep = lambda *a: set(git('grep', '-F', '-l', *sum((['-e', n] for n in NEEDLES), []), *a).split())
# 0. the scrub list is exactly the set of files that named an identifier at base
assert grep(BASE) == {f'{BASE}:{p}' for p in SCRUB}, 'scrub list drifted: ' + ', '.join(sorted(x.split(':', 1)[1] for x in grep(BASE)))
# 1. no tracked or new file names an identifier, outside ALLOWED
hits = grep('--untracked') - ALLOWED
assert not hits, 'identifier still present in: ' + ', '.join(sorted(hits))
# 2. class C: tooling-path files byte-identical; tooling-path lines in scrubbed files unchanged
C = ['CLAUDE.md', 'CLAUDE.build.md', '.claude', 'docs/phases/phase-9.md'] + \
    [f'docs/stories/CONTENT/CONTENT-{n}.md' for n in (26, 27, 28)]
assert subprocess.run(['git', 'diff', '--quiet', BASE, '--', *C]).returncode == 0, 'a class C file changed'
tool = lambda t: sorted(l for l in t.splitlines() if 'flex-marketplace-cache' in l or 'flex-findings' in l)
for p in SCRUB: assert tool(open(p).read()) == tool(at_base(p)), f'{p}: a tooling-path line changed'
# 4. pages, manifest and scripts/ untouched; nothing outside the declared set changed
assert subprocess.run(['git', 'diff', '--quiet', BASE, '--', 'index.html', 'gap-handoff.html',
                       'docs/claims-manifest.json', 'scripts']).returncode == 0, 'a page, the manifest or scripts/ changed'
changed = set(git('diff', '--name-only', BASE).split()) | set(git('ls-files', '--others', '--exclude-standard').split())
assert changed <= set(SCRUB) | OWN, f'unexpected files changed: {sorted(changed - set(SCRUB) - OWN)}'
# 3 + 5. only identifier-bearing lines change, and within them only the identifier's own tokens;
# host-path checks look only at what this story adds (CER-034's lesson), never at pre-existing text
HOSTPATH = re.compile(r'/mnt/|/home/|~/')
added = []
for p in SCRUB:
    o, n = at_base(p).splitlines(), open(p).read().splitlines()
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, o, n, autojunk=False).get_opcodes():
        if tag == 'equal': continue
        assert tag == 'replace' and i2 - i1 == j2 - j1, f'{p}:{i1+1}: lines added, removed or reflowed'
        for k, (ol, nl) in enumerate(zip(o[i1:i2], n[j1:j2])):
            assert has(ol), f'{p}:{i1+k+1}: a line without an identifier changed'
            ot, nt = ol.split(), nl.split()
            for t2, a1, a2, b1, b2 in difflib.SequenceMatcher(None, ot, nt, autojunk=False).get_opcodes():
                if t2 == 'equal': continue
                assert a1 == a2 or has(' '.join(ot[a1:a2])), f'{p}:{i1+k+1}: reworded beyond the identifier'
                added.append((p, ' '.join(nt[b1:b2])))
# backlog: two new rows, one appended note, nothing else
MARK = re.compile(r'(?:^|\|\s*|[.!?]\s+|\*\*|\(|\[)(resolved|superseded|obsolete)\b', re.I)
def rows(t): return {l.split('|')[1].strip(): l for l in t.splitlines() if re.match(r'\| CER-\d+ ', l)}
def section(t, h): return t.split(f'## {h}')[1].split('\n## ')[0]
cell = lambda l: l.split('|', 2)[2].rsplit('|', 4)[0].rstrip()
tail = lambda l: [c.strip() for c in l.split('|')[-4:-1]]   # Source, Date, Phase
new, old = open('docs/cer/backlog.md').read(), at_base('docs/cer/backlog.md')
N, O = rows(new), rows(old)
for i in O: assert i == 'CER-049' or N.get(i) == O[i], f'{i}: changed'
nx = max(int(i[4:]) for i in O)
fresh = sorted(i for i in N if i not in O)
assert fresh == [f'CER-{nx+1:03d}', f'CER-{nx+2:03d}'], f'new rows must take the next two free IDs, got {fresh}'
leak, zw = N[fresh[0]], N[fresh[1]]
src = ['security-auditor (CP-12 re-run)', '2026-09-25', '12']
assert leak in section(new, 'Do Now') and '**RESOLVED Phase 12 — CONTENT-037.**' in leak and tail(leak) == src, 'path-leak row'
assert zw in section(new, 'Do Later') and 'U+200B' in zw and not MARK.search(cell(zw)) and tail(zw) == src, 'U+200B row'
o49, n49 = cell(O['CER-049']), cell(N['CER-049'])
note = n49[len(o49):]
assert n49.startswith(o49) and tail(N['CER-049']) == tail(O['CER-049']), 'CER-049: rewritten, not appended'
assert all(k in note for k in ('security-auditor', 'CP-12 re-run', 'DATABASE_URL', '-o')) and not MARK.search(note), 'CER-049 note'
added += [('docs/cer/backlog.md', cell(leak)), ('docs/cer/backlog.md', cell(zw)), ('docs/cer/backlog.md', note)]
for p, a in added: assert not HOSTPATH.search(a) and not has(a), f'{p}: host path in added text'
# the story's own text is redacted too (a partial scrub is not a scrub)
spec = open('docs/stories/CONTENT/CONTENT-037.md').read()
sec = open('docs/phases/phase-12.md').read().split('### CONTENT-037')[1].split('\n## ')[0]
for name, t in (('CONTENT-037.md', spec), ('phase-12 CONTENT-037 section', sec), ('new backlog text', cell(leak) + cell(zw) + note)):
    assert not has(t) and USER not in t, f'{name} names an identifier or the username'
print('OK', fresh)
EOF
echo DONE
```

Pass means the script prints `OK ['CER-050', 'CER-051']`, then `DONE`, and exits 0. The
reviewer also reads the diff of the 26 files and checks each replacement against the class
rule in Instructions step 2. A test can prove that a replacement is confined to the
identifier's tokens, but it cannot prove that the class chosen is the right one. The reviewer
also reads CER-051's block count against the extracted template.

## Out of scope

- Class C: the flex tooling install path in `CLAUDE.md`, `CLAUDE.build.md`, `.claude/`,
  `docs/phases/phase-9.md`, CONTENT-020, CONTENT-024 to CONTENT-028 and EXEMPLAR-000's
  header comment. This is tooling configuration.
- CONTENT-025's `~/flex-findings-…` operator-file references. They are home-relative and
  name no user. The operator rules on them separately.
- The public repository slug in the page stamps and the manifest. It is the project's
  published identity, not a host path.
- Fixing the U+200B wart or the `-o` caption. This story only records them.
- Any change to either page, the manifest, a stamp, or `scripts/`.
- Re-running `CONTENT-005`'s blocks, or restructuring them for single-shell runnability.
