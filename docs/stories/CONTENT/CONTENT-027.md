---
id: CONTENT-027
rail: CONTENT
title: "Close the two stale findings: the duplicated gap wording, and the disproved air-gap claim"
status: draft
phase: "10"
story_class: doc
auth_gated: false
schema_introduces: false
touches:
  - docs/cer/backlog.md
  - gap-handoff.html
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

Two of the seven findings this phase disposes of had already expired before anyone
re-read them. CER-001 asks for one half of a near-identical pair of gap sentences to be
reworded; its twin, GAP-011, was pruned from the bundle in Phase 5 — three phases before
the row was re-read — so the row outlived its own target. CER-005 claims the bundle's
ledger list does not hydrate from `file://` under headless Chromium, which if true would
break the project's first non-negotiable; it was tested under every condition it
describes, including with all DNS blackholed, and the site renders completely. This story
closes both: CER-001 as `SUPERSEDED`, CER-005 as `OBSOLETE`, each carrying the evidence
that closed it. It is the phase's last story, and the last two open rows the phase owns.

## Requires

- CONTENT-023 complete — `docs/cer/backlog.md`'s header carries the resolution-marker
  convention that `cer.is_resolution_marked` reads. Without it the only closing move is
  deletion, which this phase forbids.
- `chromium` on `PATH` (present at `/usr/bin/chromium`, checked 2026-09-21) and
  `python3` for the control origin. Both reproduction commands are run by the builder.

## Recon (done; the builder does not repeat it, but re-runs the reproduction)

**CER-001 — no live duplicate remains.** Checked against the current bundle at `aab2434`
on 2026-09-21, not against the row's own description:

- `grep -o 'GAP-0[0-9][0-9]' gap-handoff.html | sort -u` returns GAP-003..GAP-010 and
  GAP-012. **GAP-011 is not in the bundle at all**, and neither is GAP-002.
- `grep -c 'exactly the case' gap-handoff.html` returns **1**. The single surviving
  occurrence is inside GAP-006 ("…the check reports \"is set\" — exactly the case the
  check exists to catch."). There is no second sentence to be near-identical to.
- `git log -S'GAP-011' -- gap-handoff.html` returns `3f16dcc` ("Phase 5: SDK 5.0.0 and the
  generated-registry ingestion path") as the commit that removed it, confirming the phase
  doc's account.
- `index.html` also contains one `exactly the case`, but it is unrelated prose ("…where it
  is exactly the case you are about to run", in the standup/staging callout). It is not
  the "exists to catch / covers" construction, it is in the other bundle, and it is not
  CER-001's subject.

So the expected path is the SUPERSEDED close with **no bundle edit**. The contingency
path is specified anyway (Instructions step 2) so a builder whose own re-check disagrees
with this recon is not stuck.

**CER-005 — nine ledger rows.** `index.html` defines `const ledger = [...]` with nine
entries (GAP-003..GAP-010, GAP-012) and renders them through
`sc-for list="{{ ledger }}"`. Nine is therefore the expected rendered-row count, and it
is the count the phase doc's observation refers to.

**Marker forms verified** against the real `cer.is_resolution_marked` on 2026-09-21: the
two replacement rows in Instructions step 3 both return `True`; CER-006, CER-008,
CER-009, CER-010 and CER-011 all return `False` as they currently stand and must still
return `False` after the build.

## Ensures

The builder ran both reproduction commands itself and reported the output it actually
observed — exit 0, nine ledger rows rendered, zero unexpanded `{{ … }}` template tags,
zero error banners, and the two runs' DOM equivalent apart from the blob-URL prefix
(forbidden proxy: transcribing the phase doc's recorded results, or any paraphrase of
them, in place of running the commands); `cer.is_resolution_marked` returns `True` for
the rewritten CER-001 and CER-005 rows and `False` for CER-006, CER-008, CER-009, CER-010
and CER-011 (forbidden proxy: closing a neighbouring row because this story happened to
touch the file); both rewritten rows keep their ID, quadrant, ordering, source, date and
phase, their pre-marker text is byte-identical to its pre-build form, and the
`| CER-NNN |` row count is not less than before the build; each marker carries a
date-and-commit stamp naming the date the reproduction/re-check was run and the short SHA
it was run at; and `index.html` and `gap-handoff.html` are byte-identical to their
pre-build form unless the builder's own re-check found a live duplicate, in which case
`gap-handoff.html`'s diff is the single reworded sentence and nothing else, the bundle
still names no host, absolute path or machine identifier, and the reproduction is re-run
after the edit with the same nine-row result.

## Instructions

1. **Re-run the reproduction. Do not copy it.** The phase doc says in terms: "Re-run both
   before closing the finding; do not close it on this record alone." Copy the bundle to
   an empty scratch directory first, so nothing in the repo is touched, then run both:

   ```bash
   D=$(mktemp -d); cp index.html gap-handoff.html "$D/"
   # air-gapped, from disk: every DNS lookup blackholed
   chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=8000 \
     --host-resolver-rules="MAP * 0.0.0.0" --disable-features=NetworkService \
     --dump-dom "file://$D/index.html#gaps" > "$D/air.html"; echo "exit=$?"
   # control: same bundle served over a loopback static origin
   python3 -m http.server 8731 --directory "$D" >/dev/null 2>&1 & SRV=$!
   chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=6000 \
     --dump-dom "http://127.0.0.1:8731/index.html" > "$D/net.html"; echo "exit=$?"
   kill $SRV
   ```

   Then check, and **report the numbers you got**, not the numbers above:

   - both `exit=0`;
   - all nine ledger rows present in `$D/air.html` —
     `grep -o 'GAP-0[0-9][0-9]' "$D/air.html" | sort -u | wc -l` is `9`;
   - zero unexpanded template tags — `grep -c '{{' "$D/air.html"` is `0`;
   - zero error banners — no rendered error/failure banner in the dumped DOM;
   - the two dumps equivalent apart from the blob-URL prefix:
     `diff <(sed 's#blob:[^"]*#blob:X#g' "$D/air.html") <(sed 's#blob:[^"]*#blob:X#g' "$D/net.html")`
     prints nothing.

   Also confirm the `unpkg.com` strings are resource-map keys rather than fetches — the
   air-gapped run rendering completely with every lookup blackholed *is* that evidence.
   If any observation disagrees with the phase doc's record, **stop and report it**: that
   makes CER-005 a live finding again, and closing it would be the failure this story
   exists to avoid.

2. **Re-check CER-001 against the current bundle** (the Recon above is the measured
   position; confirm it, do not re-derive it):
   `grep -c 'exactly the case' gap-handoff.html` and
   `grep -o 'GAP-0[0-9][0-9]' gap-handoff.html | sort -u`.
   - **If one occurrence and no GAP-011 (expected):** make **no bundle edit**. CER-001
     closes as `SUPERSEDED`.
   - **If a live duplicate does remain:** the phase's "What is NOT in scope" permits
     exactly one sentence of bundle edit for this and nothing more. Reword the *later* of
     the two sentences only, keeping the same JS string-literal escaping the surrounding
     entries use (`/` for `/`, escaped quotes), change no ID, no ordering and no
     other field; then re-run step 1's air-gapped command and confirm the same nine rows,
     zero unexpanded tags, zero error banners. The row then closes as `RESOLVED`, naming
     the reworded GAP id, rather than `SUPERSEDED`.
   - *Ideology note (Step 4a, resolved inline):* a hand-edit to `gap-handoff.html` would
     touch a generated artifact. It is permitted here under that constraint's own override
     path (a trivial, urgent fix) as extended by its recorded Phase 2 exception for
     loop-mediated, spec-cited, reviewed edits — which is why the edit is capped at one
     sentence and why re-running the render check afterwards is mandatory, not optional.

3. **`docs/cer/backlog.md`** — replace exactly these two rows and nothing else. Substitute
   the date you actually ran step 1 and the short SHA of `HEAD` at that moment for
   `2026-09-21`/`aab2434` if either has moved; the stamp must name the commit the claim
   was checked at, per the phase's Verification obligation. Each marker names its evidence
   and does not restate reasoning that lives elsewhere.

   ```
   | CER-001 | CONTENT-004 missed one named acceptance-criterion line item: reword one of GAP-006/GAP-011's near-identical 'exactly the case ... exists to catch/covers' construction in gap-handoff.html. Both phrases still present verbatim. Suggested fix for GAP-011: '...requires the same restart the admin banner already flags.' **SUPERSEDED cp-10 — re-checked against the current gap-handoff.html on 2026-09-21 at aab2434, not against this row's own description: GAP-011 was pruned from the bundle in Phase 5 (3f16dcc), leaving one occurrence of the construction, in GAP-006. The pair the finding names no longer exists, so there is nothing to reword. The row outlived its target because it was filed against a bundle state that changed three phases before anyone re-read it (CONTENT-027).** | intent-reviewer (Phase 2 checkpoint) | 2026-07-16 | 2 |
   ```

   ```
   | CER-005 | index.html's `sc-for` ledger list does not hydrate under headless Chromium at a `file://` origin, so ledger rows can be verified in source but not in a render. Pre-existing, reproduced on the pre-story bundle. Limits reviewer verification coverage for any story touching that list. **OBSOLETE cp-10 — disproved by re-running the reproduction recorded in docs/phases/phase-10.md, on 2026-09-21 at aab2434. Opened from disk, headless, with every DNS lookup blackholed (`--host-resolver-rules="MAP * 0.0.0.0"`), the ledger hydrates: exit 0, all nine rows rendered, no unexpanded template tag, no error banner, and the DOM equivalent to the same bundle served from a loopback origin apart from the blob-URL prefix. The `unpkg.com` strings are keys in a resource map, not fetches — the embedded React resolves to local blob URLs, so the zero-dependency guarantee holds (CONTENT-027).** | reviewer (CONTENT-019, accepted deviation) | 2026-09-18 | 8 |
   ```

4. **Stamp convention note.** CER-010, filed 2026-09-21 from CONTENT-025's review,
   proposes extending the date-and-commit stamp to harness-telemetry claims. That is a
   **proposal, not in force**, and it changes nothing this story does: both closures make
   claims about forqsite's own behaviour, which the Phase 6 convention already covers, and
   CER-010 itself stays open and unmarked.

5. Proportionality note: this spec runs longer than a one-file doc story usually would
   because it carries an executable reproduction with five observations, a conditional
   second build path, and a negative acceptance criterion (a bundle that must not change).

**Declared-scope note.** `gap-handoff.html` is in `touches:` for the step 2 contingency
only. On the expected path its diff is empty; declaring it means the permitted edit is in
scope if the builder's re-check disagrees with Recon, not that an edit is expected.

**Spec-preflight note.** The scan reports no route and no `scope:` findings. Its nine
constant warnings — `CER`, `CONTENT`, `GAP`, `SUPERSEDED`, `OBSOLETE`, `DNS`, `DOM`,
`MAP`, `SRV` — are all intentional: rail and backlog-row prefixes, marker keywords defined
in the build harness (`cer.RESOLUTION_MARKERS`) rather than in this repo, two ordinary
acronyms, and two shell locals from the reproduction block.

## Tests

No test suite (`test_command=true`, static HTML). These are the story's verification
commands, run from the repo root.

The marker probe (same shape as CONTENT-026's; it derives the harness scripts directory
from a file already in the tree, so neither builder nor reviewer types a home path):

```bash
FS=$(grep -oE '[^ "`]*skills/pairmode/scripts' CLAUDE.build.md | head -1); FS="${FS/#\~/$HOME}"
PATH=$HOME/.local/bin:$PATH uv run --project "${FS%/skills/pairmode/scripts}" python - "$FS" <<'PY'
import sys, pathlib; sys.path.insert(0, sys.argv[1])
import cer
rows = {l.split('|')[1].strip(): l for l in
        pathlib.Path('docs/cer/backlog.md').read_text().splitlines() if l.startswith('| CER-')}
for rid in ('CER-001','CER-005','CER-006','CER-008','CER-009','CER-010','CER-011'):
    print(rid, cer.is_resolution_marked(rows[rid]))
PY
```

Acceptance: `CER-001 True`, `CER-005 True`, `False` for the other five.

Backlog integrity and the untouched-prose check:

```bash
grep -cE '^\| CER-[0-9]+ \|' docs/cer/backlog.md      # not less than the pre-build count
git diff -- docs/cer/backlog.md | grep -c '^-|'       # expected 2 — CER-001 and CER-005 only
for id in CER-001 CER-005; do
  old=$(git show HEAD:docs/cer/backlog.md | grep "^| $id " | sed 's/ \*\*[A-Z]*.*//')
  new=$(grep "^| $id " docs/cer/backlog.md | sed 's/ \*\*[A-Z]*.*//')
  [ "$old" = "$new" ] && echo "PASS: $id prose unchanged" || { echo "FAIL: $id"; diff <(echo "$old") <(echo "$new"); }
done
```

Acceptance: the row count holds, exactly two rows are rewritten, both `PASS`.

The stamp check — whitespace-normalised, not a line-oriented grep (CER-011 was filed
because a verbatim multi-word grep breaks on a cosmetic soft-wrap):

```bash
python3 - <<'PY'
import re, pathlib
t = re.sub(r'\s+', ' ', pathlib.Path('docs/cer/backlog.md').read_text())
for rid in ('CER-001', 'CER-005'):
    row = [r for r in t.split('| CER-') if r.startswith(rid.split('-')[1])][0]
    print(rid, bool(re.search(r'20\d\d-\d\d-\d\d at [0-9a-f]{7,40}', row)))
PY
```

Acceptance: `True` for both.

The bundle guard:

```bash
git diff --stat -- index.html gap-handoff.html
grep -c 'exactly the case' gap-handoff.html
```

Acceptance on the expected path: the diff prints nothing and the count is `1`. If step 2's
contingency fired, the diff is `gap-handoff.html` with one changed line, the reviewer reads
that line to confirm it introduces no host, absolute path or machine identifier, and the
step 1 air-gapped command is re-run to confirm nine rows and zero unexpanded tags.

Finally, the reviewer reads the builder's reported reproduction output and confirms it
records observed values rather than restating the phase doc — CP-10's "a disproved finding
says how" is a read, not a grep.

**Do not add a frozen-snapshot assertion against `.companion/effort.db`.** CER-009 was
filed because that pattern cannot pass on the story that introduces it: the build's and
the review's own attempt rows land inside the same stamped day. This story asserts nothing
about the effort database.

## Out of scope

- **Deleting, re-numbering or re-quadranting any row.** CER-001 and CER-005 stay exactly
  where they are, in Do Later, with their original text and a marker appended.
- **CER-006, CER-008, CER-009, CER-010 and CER-011.** All stay open and unmarked. CER-006
  stays open by ruling (a referral is not a fix), CER-008 by ruling (history rewrite would
  invalidate the `cp-N` tags), and CER-009/CER-010/CER-011 were filed from this phase's own
  reviews and have not been triaged.
- **Any bundle edit beyond the single gap-wording sentence**, and that only if the
  builder's own re-check finds a live duplicate. No content refresh, no prose pass, no
  re-export.
- **Acting on CER-010's proposal** to extend the stamp convention to harness telemetry.
  It is recorded as a proposal; adopting it is a future story's decision.
- **Building anything to stop findings going stale.** The phase names that as a lesson
  worth recording, not a mechanism worth building here.
- **Re-opening the Phase 5 prune that removed GAP-011.** Why the twin is gone is settled;
  this story only records that it is.
