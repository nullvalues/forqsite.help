---
id: CONTENT-005
rail: CONTENT
title: Drift re-sweep: re-check index.html/gap-handoff.html against current forqsite source and fix drift
status: draft
phase: "3"
story_class: code
auth_gated: false
schema_introduces: false
test_gate: none
touches: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Requires

- Phase 2 (`CONTENT-001..004`, `INFRA-001`) complete. Those stories were the last
  content sync; both bundles were last touched at the Phase 2 checkpoint,
  `forqsite.help@3289ab1` (2026-07-16 23:41 -0400).
- `/mnt/work/forqsite` present on disk, on `main`. **This repo is READ-ONLY for this
  story.** Never write, stage, commit, checkout, stash or `git clean` in it. Its working
  tree is currently dirty with unrelated harness edits (`.claude/agents/*.md`); leave
  them alone and do not let them enter your reasoning about product drift.
- `python3` available (stdlib only — no third-party packages, no build step).

**Baseline correction (read this before diffing).** The phase doc calls the last sync
"2026-07-22". That date is the pairmode-0.3.0 migration activity in the *source* repo,
not the last content sync of this site. The bundles were last synced 2026-07-16. The
correct diff baseline in `/mnt/work/forqsite` is therefore:

```bash
BASE=90b64b99   # 2026-07-16 23:19 -0400, last forqsite commit before forqsite.help@3289ab1
```

Using the later 2026-07-22 baseline would silently skip four product commits
(`b1e6ee73`, `cbec03f2`, `c1e49f7f`, `06d72442`), one of which is confirmed drift (see
`## Ensures`).

## Ensures

Scope note: every assertion below is about **correcting stale claims** in the two
bundles. Adding coverage of upstream features the site never claimed to document is
explicitly out of scope (see `## Out of scope`).

**Drift corrections (the known finding):**

1. `index.html`'s `prereqs` array no longer claims pnpm `'8+'`. Upstream pinned
   `"packageManager": "pnpm@9.15.9"` in `package.json` (commit `b1e6ee73`,
   story INFRA-019, after the sync baseline). The `min` field states a version
   consistent with that pin, and the `note` still tells the operator how to get it.
   Verify: decoded `index.html` contains `9.15.9` and does not contain `min: '8+'`
   on the pnpm row.

2. Any *further* stale claim found by the sweep below is corrected in place, and the
   commit message names the upstream `file:line` or commit sha that makes the old
   claim false. No claim is changed without such a citation.

**Claims re-verified and left unchanged (regression guards — these must still hold):**

3. `index.html`'s "What the scheduler owns" section still says **Ten** jobs and
   `schedulerJobs` still has 10 entries; `grep -c "name: '" /mnt/work/forqsite/scripts/scheduler.ts`
   returns `10`. If the counts diverge, both the prose word and the array are corrected
   together.
4. The gap-ledger ID set is unchanged and consistent across both files: the `id:` values
   in `index.html`'s `ledger` array are exactly `GAP-002, GAP-003, GAP-004, GAP-005,
   GAP-006, GAP-007, GAP-008, GAP-009, GAP-010, GAP-011`, and the same set appears in
   `gap-handoff.html`. An item is pruned from **both** files only if the builder can cite
   the upstream commit that closed it. (Expected outcome: no prunes — GAP-002's
   `file:/mnt/work/ud/…` tarballs and GAP-005's `next dev -p 6020` are both still present
   in `/mnt/work/forqsite/package.json`.)
5. `index.html`'s `ENV` array is unchanged unless the builder cites an upstream env-key
   change; no file that reads environment configuration appears in the baseline diff.

**Integrity (zero-dependency constraint — must hold after any edit):**

6. For both `index.html` and `gap-handoff.html`, the
   `<script type="__bundler/template">` block still parses as a single JSON string
   (round-trip command in `## Tests` exits 0 for both files).
7. `git diff --stat` shows changes confined to the two HTML files, and within them only
   inside the template block: the `__bundler/manifest` and `__bundler/ext_resources`
   blocks are byte-identical to the pre-edit versions.
8. No new external asset reference is introduced: the count of `src="http` and
   `href="http` occurrences in each file is unchanged from the pre-edit count.
9. `git -C /mnt/work/forqsite status --porcelain` output is byte-identical before and
   after the build (proves the source repo was treated read-only).

## Instructions

**Step 1 — establish the diff surface.** In `/mnt/work/forqsite`, read-only:

```bash
cd /mnt/work/forqsite
BASE=90b64b99
git log --oneline $BASE..HEAD -- src scripts package.json docs/architecture.md drizzle
git diff --name-only $BASE..HEAD -- src scripts package.json docs/architecture.md drizzle
```

The product-surface diff is 16 files. Classify them before reading any of them:

- **Operator/self-hoster facing (in scope for claim checking):** `package.json`,
  `src/db/migrations/0090_page_publications_is_homepage.sql`,
  `src/db/migrations/meta/_journal.json`, `src/db/schema/content.ts`,
  `docs/architecture.md`.
- **Product/content-authoring facing (out of scope — this site documents running
  forqsite, not authoring in it):** `src/app/actions/pages.ts`, the four
  `src/app/admin/.../pages/*.tsx` files, `src/app/[[...slug]]/page.tsx`,
  `src/services/content/pages.ts`, `src/services/migration/bundle.ts`,
  `src/block-providers/core/index.ts`, `src/components/blocks/nav-block-client.tsx`,
  `src/lib/theme/types.ts`.
- Everything else in `$BASE..HEAD` (`.companion/`, `.claude/`, `docs/phases/`,
  `docs/stories/`, `CLAUDE*.md`, `tests/`) is pairmode-harness churn, not product
  behaviour. Ignore it entirely.

**Step 2 — unpack both bundles.** The HTML files are single-file bundles: the readable
page content is a JSON-encoded string inside `<script type="__bundler/template">`.
Decode to a scratch file, edit the *decoded* text, then re-encode. Never hand-edit the
escaped JSON in place.

```bash
cd /mnt/work/forqsite.help
python3 - <<'PY'
import json
MARK = '<script type="__bundler/template">'
for f in ('index.html', 'gap-handoff.html'):
    s = open(f, encoding='utf-8').read()
    i = s.index(MARK) + len(MARK); j = s.index('</script>', i)
    open('/tmp/' + f + '.txt', 'w', encoding='utf-8').write(json.loads(s[i:j]))
PY
```

Re-encode with the mirror script (`json.dumps(text)` written back between the same two
offsets) so the manifest and ext_resources blocks are never touched.

**Step 3 — check the claims.** The claim-bearing content in the decoded `index.html` is
concentrated in JS data arrays near the end of the template — `prereqs`, `devTrouble`,
`cheats`, `incidents`, `schedulerJobs`, `ENV`, `sections`, `stages`, `ledger` — plus the
prose sections above them. For each in-scope diff file from Step 1, grep the decoded text
for the claim it could falsify, and check it. Confirmed finding to fix: the `prereqs`
pnpm row (Ensures 1). Confirmed non-findings to re-verify, not re-litigate:
scheduler job count (Ensures 3), gap ledger (Ensures 4), ENV table (Ensures 5).

**Step 4 — apply the minimum edit.** Change only the words that are false. Do not
rewrite surrounding prose, do not restyle, do not touch markup or the visual theme —
Phase 2's CONTENT-004 already did the prose pass and re-running it here makes the drift
correction untraceable.

**Step 5 — re-encode, verify, report.** Run everything in `## Tests`. If the sweep found
nothing beyond Ensures 1, say so explicitly in the commit body ("re-verified: scheduler
job count, gap ledger IDs, ENV keys — no drift") rather than leaving it implicit. A
negative result is the point of a re-sweep and must be recorded.

*Preflight note:* `spec-preflight` flags `BASE` and `MARK` as undefined constants. Both
are locals defined inside this story's own shell/python snippets, not references to
codebase constants — no action needed.

**Ideology note (resolved inline, per spec-writer Step 4a).** `docs/ideology.md`'s
*Generated-artifact discipline* constraint says these bundles are not hand-edited. This
story hand-edits them, under the same reasoning as the recorded Phase 2 exception: every
edit goes through the reviewed pairmode loop, cites exact upstream evidence, and is
traceable to this spec, so the silent-untraceable-drift risk the rule protects against
does not apply. Ensures 6-8 exist to preserve the *Zero runtime dependencies*
constraint, which has no override path, across those edits. Keeping the diff minimal
(Step 4) is what keeps a future re-export reconciliation cheap.

## Tests

`test_gate: none` — this is a static, zero-dependency HTML site with no test suite.
Verification is grep- and inspection-shaped. Run all of these; all must pass.

```bash
cd /mnt/work/forqsite.help

# T1 — bundle round-trip: both templates still parse as one JSON string (exit 0)
python3 - <<'PY'
import json
MARK = '<script type="__bundler/template">'
for f in ('index.html', 'gap-handoff.html'):
    s = open(f, encoding='utf-8').read()
    i = s.index(MARK) + len(MARK); j = s.index('</script>', i)
    t = json.loads(s[i:j]); assert isinstance(t, str) and len(t) > 10000, f
    print('OK', f, len(t))
PY

# T2 — pnpm claim corrected (Ensures 1): first grep hits, second returns 0
grep -c '9\.15\.9' index.html
grep -c "min: '8+'" index.html    # must be 0

# T3 — scheduler job count still 10 on both sides (Ensures 3)
grep -c "name: '" /mnt/work/forqsite/scripts/scheduler.ts        # expect 10
grep -o "name: '[a-z-]*', schedule" index.html | wc -l           # expect 10

# T4 — gap ledger ID set identical across both bundles (Ensures 4)
diff <(grep -o 'GAP-0[0-9][0-9]' index.html | sort -u) \
     <(grep -o 'GAP-0[0-9][0-9]' gap-handoff.html | sort -u)     # expect no output

# T5 — no new external asset refs (Ensures 8)
for f in index.html gap-handoff.html; do
  echo "$f now:  $(grep -o 'src="http\|href="http' $f | wc -l)"
  echo "$f base: $(git show HEAD:$f | grep -o 'src="http\|href="http' | wc -l)"
done

# T6 — diff confined to the two bundles (Ensures 7)
git status --porcelain            # expect only ' M index.html' and/or ' M gap-handoff.html'

# T7 — source repo untouched (Ensures 9)
git -C /mnt/work/forqsite status --porcelain   # expect the same 3 .claude/agents/*.md lines as before
```

Acceptance: T1 exits 0 for both files; T2 shows a non-zero hit and a zero; T3 prints 10
and 10; T4 prints nothing; T5 shows equal counts; T6 lists no file outside the two
bundles; T7 is unchanged from the pre-build snapshot.

Manual check: open `index.html` from `file://` in a browser with the network disabled.
The page must unpack and render (no "Unpacking..." stall, no `__bundler_err` overlay),
and the Prerequisites table must show the corrected pnpm version.

## Out of scope

- **Documenting the new homepage-designation feature** (`0090_page_publications_is_homepage`,
  the source-aware resolver, the admin Set-Homepage UI, `is_homepage` bundle round-trip).
  Both bundles currently contain zero occurrences of "homepage" — the site documents
  operating and self-hosting forqsite, not per-tenant content authoring, so this is a
  coverage gap by design, not drift. The exception: if the builder finds an *existing*
  claim that the new resolver contradicts (e.g. anything asserting how the root path
  resolves to a page), that claim **is** in scope and must be corrected.
- **Pruning resolved GAP items on speculation.** No gap item may be removed without a
  cited upstream commit that closes it. GAP-002 and GAP-005 are confirmed still open.
- **Prose/style work.** CONTENT-004 owns em-dash and word-tic cleanup; this story only
  changes text that is factually wrong.
- **Re-export from the source design session, or building an auto-sync tool.** Still
  unbuilt (see `docs/phases/phase-2.md`); this remains a loop-mediated hand-patch.
- **`README.md`** — INFRA-001 owns its framing; not part of this drift sweep.
- **Any write to `/mnt/work/forqsite`**, including committing its unrelated dirty
  `.claude/agents/*.md` files.
