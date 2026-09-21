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
  - docs/phases/phase-10.md
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

This story was specced to close two expired findings. The first attempt's builder did what
the spec required — ran the reproduction rather than transcribing it — and refused to
proceed, because the reproduction does not show what the phase doc says it shows. A
controlled re-run (2x2: both origins x both URL fragments) split the result in two: the
**air-gap claim holds** — with the fragment held constant, the `file://` and
`http://127.0.0.1` dumps are byte-identical after blob-URL normalisation, so origin makes
no difference and the zero-dependency guarantee stands — but the **ledger-render claim does
not**. Stripping `<script>` before asserting shows zero rendered GAP rows at *either*
origin. The phase doc's "all nine ledger rows rendered" was a grep counting inert template
source (CER-012).

So CER-005's substance is confirmed while its stated cause is disproved. The operator ruled
on 2026-09-21: CER-001 closes as `SUPERSEDED`; **CER-005 stays open** with its evidence
corrected, on the CER-006 precedent that a finding which grew is amended, not closed; and
the phase doc's reproduction record — which asserts an observation its own command cannot
produce — is corrected in place rather than deleted, because the correction is the point.

*(The frontmatter `title:` still reads "the two stale findings … the disproved air-gap
claim". It records the premise the story was opened on. The ruling above supersedes it; the
title is left unedited because the spec-writer preserves frontmatter.)*

## Requires

- CONTENT-023 complete — `docs/cer/backlog.md`'s header carries the resolution-marker
  convention that `cer.is_resolution_marked` reads.
- CER-012 filed (`fef7f76`) — it owns the grep-vs-DOM assertion flaw and the uncontrolled
  comparison. This story consumes its lesson; it does not close it.
- `chromium` on `PATH` (present at `/usr/bin/chromium`, checked 2026-09-21) and `python3`
  for the control origin. The builder runs all four dumps.

## Recon (done; the builder does not repeat it, but re-runs the reproduction)

**CER-001 — no live duplicate remains.** Checked against the current bundle on 2026-09-21,
and independently re-verified by the first attempt's builder:

- `grep -o 'GAP-0[0-9][0-9]' gap-handoff.html | sort -u` returns GAP-003..GAP-010 and
  GAP-012. **GAP-011 is not in the bundle**, and neither is GAP-002.
- `grep -c 'exactly the case' gap-handoff.html` returns **1**, inside GAP-006 ("…the check
  reports \"is set\" — exactly the case the check exists to catch."). There is no second
  sentence for it to be near-identical to.
- `git log -S'GAP-011' -- gap-handoff.html` returns `3f16dcc` (Phase 5) as the commit that
  removed it.
- `index.html` contains one unrelated `exactly the case` in the standup/staging callout. It
  is not the "exists to catch / covers" construction and is not CER-001's subject.

The operator's ruling is therefore `SUPERSEDED` with **no bundle edit at all**. The
contingency reword specced in the first attempt is withdrawn.

**CER-005 — measured from the controlled 2x2.** Four dumps (`file://` and
`http://127.0.0.1`, each with `#gaps` and with no fragment), each analysed after removing
`<script>` *and* `<style>` blocks — `<style>` matters because the bundle inlines base64
fonts there, and an unstripped dump is ~97% inline asset by volume:

| dump | GAP ids raw | GAP ids after stripping | `data-screen-label` |
|---|---|---|---|
| `file://…#gaps` | 9 | **0** | **0** |
| `http://…#gaps` | 9 | **0** | **0** |
| `file://…` (no fragment) | 9 | **0** | 1 — `"Overview"` |
| `http://…` (no fragment) | 9 | **0** | 1 — `"Overview"` |

After blob-URL normalisation, `file-gaps == http-gaps` and `file-none == http-none` are
both byte-identical; `gaps != none` at the same origin. That is the confound: the phase
doc's air-gapped command used `#gaps` and its control used no fragment, so the diff between
them measured the fragment, not the origin.

Node-count figures (`data-dc-tpl`: 46 with `#gaps`, 113 without) depend on the counting
recipe and are not the load-bearing observation. The load-bearing observations are the two
zeros and the `data-screen-label` split.

**Marker forms verified** against the real `cer.is_resolution_marked` on 2026-09-21: the
replacement CER-001 row in Instructions step 3 returns `True`; the amended CER-005 row in
step 4 returns `False` (checked explicitly — an amendment must not accidentally read as a
close); and CER-006, CER-008, CER-009, CER-010, CER-011 and CER-012 all return `False` as
they stand and must still return `False` after the build.

## Ensures

The builder ran all four dumps itself and reported the values it observed (forbidden proxy:
transcribing this spec's or the phase doc's recorded numbers in place of running the
commands), and those values show origin-independence with the fragment held constant and
zero `GAP-0NN` ids in every dump after `<script>`/`<style>` removal (forbidden proxy: a
grep over the whole `--dump-dom` output used as a render assertion — CER-012);
`cer.is_resolution_marked` returns `True` for the rewritten CER-001 row and `False` for
CER-005, CER-006, CER-008, CER-009, CER-010, CER-011 and CER-012; the amended CER-005 row
keeps its ID, quadrant, ordering, source, date and phase with its original text
byte-identical ahead of the appended correction, and the `| CER-NNN |` row count is not
less than before the build; the amended row and the phase-doc correction each carry a
date-and-commit stamp naming when and at which short SHA the 2x2 was run; the phase doc's
original reproduction record is still present, now annotated rather than deleted, and its
"renders completely" / "all nine ledger rows rendered" claims no longer stand unqualified;
and `index.html` and `gap-handoff.html` are byte-identical to their pre-build form.

## Instructions

1. **Run the controlled 2x2.** Hold the fragment constant across origins; vary one thing at
   a time. Copy the bundle to a scratch directory so nothing in the repo is touched:

   ```bash
   D=$(mktemp -d); cp index.html gap-handoff.html "$D/"
   python3 -m http.server 8731 --directory "$D" >/dev/null 2>&1 & SRV=$!
   for frag in '#gaps' ''; do
     n=${frag:-none}; n=${n#\#}
     chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=8000 \
       --host-resolver-rules="MAP * 0.0.0.0" --disable-features=NetworkService \
       --dump-dom "file://$D/index.html$frag" > "$D/file-$n.html"; echo "file-$n exit=$?"
     chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=8000 \
       --dump-dom "http://127.0.0.1:8731/index.html$frag" > "$D/http-$n.html"; echo "http-$n exit=$?"
   done
   kill $SRV
   ```

   The `file://` runs are the air-gapped arm (every DNS lookup blackholed); the
   `http://127.0.0.1` runs are the control. Four dumps, one variable changing per
   comparison.

2. **Assert on them correctly, and report what you observe.** Never grep the raw dump for a
   render claim — strip `<script>` and `<style>` first (CER-012):

```bash
python3 - "$D" <<'PY'
import re, sys, pathlib
d = pathlib.Path(sys.argv[1])
strip = lambda t: re.sub(r'(?is)<(script|style)\b.*?</\1>', '', t)
norm  = lambda t: re.sub(r'blob:[^"\']*', 'blob:X', t)
raw = {n: (d / f'{n}.html').read_text() for n in
       ('file-gaps', 'http-gaps', 'file-none', 'http-none')}
for n, t in raw.items():
    s = strip(t)
    print(n, 'gapids_raw=', len(set(re.findall(r'GAP-0\d\d', t))),
             'gapids_rendered=', len(set(re.findall(r'GAP-0\d\d', s))),
             'screen_label=', re.findall(r'data-screen-label="[^"]*"', s),
             'unexpanded_tags=', s.count('{{'))
print('origin-independent, #gaps      :', norm(raw['file-gaps']) == norm(raw['http-gaps']))
print('origin-independent, no fragment:', norm(raw['file-none']) == norm(raw['http-none']))
print('fragment changes the render    :', norm(raw['file-gaps']) != norm(raw['file-none']))
PY
```

   Report the actual output. The expected shape is: all four exits `0`; both
   origin-independence lines `True`; `gapids_rendered= 0` in all four; `screen_label=` empty
   for both `#gaps` dumps and `["Overview"]` for both no-fragment dumps; `unexpanded_tags= 0`
   throughout. **If any of these disagrees, stop and report** — the point of this story is
   that the recorded observation was wrong once already.

   State the conclusion as what it is: *origin-independence confirmed, the zero-dependency
   guarantee unaffected; ledger rows not rendered at any origin.* Do not restate it as
   "renders completely".

3. **`docs/cer/backlog.md` — close CER-001.** Replace this one row. Substitute the date you
   ran step 1 and the short SHA of `HEAD` at that moment for `2026-09-21`/`fef7f76`.

   ```
   | CER-001 | CONTENT-004 missed one named acceptance-criterion line item: reword one of GAP-006/GAP-011's near-identical 'exactly the case ... exists to catch/covers' construction in gap-handoff.html. Both phrases still present verbatim. Suggested fix for GAP-011: '...requires the same restart the admin banner already flags.' **SUPERSEDED cp-10 — re-checked against the current gap-handoff.html on 2026-09-21 at fef7f76, not against this row's own description: GAP-011 was pruned from the bundle in Phase 5 (3f16dcc), leaving one occurrence of the construction, in GAP-006. The pair the finding names no longer exists, so there is nothing to reword. The row outlived its target because it was filed against a bundle state that changed three phases before anyone re-read it (CONTENT-027).** | intent-reviewer (Phase 2 checkpoint) | 2026-07-16 | 2 |
   ```

4. **`docs/cer/backlog.md` — amend CER-005, do not close it.** Same treatment CER-006
   received: original text intact, correction appended, row stays open in Do Later. Verified
   on 2026-09-21 to return `False` from `cer.is_resolution_marked` — keep it that way; no
   `RESOLVED`/`SUPERSEDED`/`OBSOLETE` keyword may open a segment anywhere in the row.

   ```
   | CER-005 | index.html's `sc-for` ledger list does not hydrate under headless Chromium at a `file://` origin, so ledger rows can be verified in source but not in a render. Pre-existing, reproduced on the pre-story bundle. Limits reviewer verification coverage for any story touching that list. **Corrected in Phase 10.** Re-run under control on 2026-09-21 at fef7f76 (CONTENT-027), 2x2 across both origins and both URL fragments: the stated cause is wrong and the substance is broader. With the fragment held constant the `file://` and `http://127.0.0.1` dumps are byte-identical after blob-URL normalisation, so the behaviour is origin-independent and the zero-dependency guarantee is unaffected. After stripping `<script>` and `<style>` blocks, zero `GAP-0NN` ids appear in rendered markup at either origin — all nine matches live in the inert `const ledger = [...]` source. The `#gaps` fragment renders no screen at all at either origin (no `data-screen-label` node); the no-fragment load renders Overview at both. Ledger rows are therefore verifiable in source but not in a render, not because of the origin but because that screen does not render. The earlier contrary observation was a whole-dump grep counting script source as rendered nodes (CER-012). This finding stays open; Phase 10 records the corrected evidence and does not repair the gap. | reviewer (CONTENT-019, accepted deviation) | 2026-09-18 | 8 |
   ```

5. **`docs/phases/phase-10.md` — correct the record, keep the record.** A story editing its
   own phase doc is unusual and is deliberate here: the phase doc carries a factual claim
   about forqsite's behaviour that this story disproved, and the phase's own Verification
   obligation makes such claims this story's subject. It is a correction of fact, not a
   re-plan — no goal, story, scope or checklist item changes. Make exactly these four edits:

   a. Under **"The reproduction, as run (2026-09-21)"**, leave both command blocks and the
      "Observed, air-gapped:" paragraph in place as the historical account, and append a
      clearly-marked correction block immediately after it, stamped with your run's date and
      short SHA. It must say: the two commands were not a controlled comparison — the
      air-gapped run used `#gaps` and the control used no fragment, so their diff measured
      the fragment, not the origin; re-run as a 2x2 with the fragment held constant, the two
      origins are byte-identical after blob-URL normalisation, so **origin-independence and
      the zero-dependency guarantee are confirmed**; but "all nine ledger rows rendered" was
      a grep over the whole `--dump-dom` output counting inert `<script>` template source —
      after stripping `<script>`/`<style>`, zero GAP rows render at either origin, and
      `#gaps` renders no screen at all; therefore CER-005 stays open with corrected
      evidence, and CER-012 records the assertion flaw.
   b. In **"Why this phase exists"**, the paragraph beginning "One turned out to be a bad
      filing:" — keep it as the belief the phase was planned on, and append one sentence
      recording that it was re-tested under control and only half held: the air-gap cause is
      disproved, the render gap is real, and the finding stays open. Do not rewrite the
      paragraph to read as though this was always known.
   c. In the **"What triage found"** table, change the "Bundle allegedly fails from disk"
      row's disposition from "**Obsolete** — tested air-gapped, renders completely" to a
      disposition that matches the ruling: the air-gap cause disproved, the render gap
      confirmed, finding stays open with corrected evidence. Its "What it actually is"
      cell — "Bad filing" — becomes "Partly misfiled"; leave every other row untouched.
   d. In **CONTENT-027's own section**, replace the "**Done when** the air-gap finding closes
      as obsolete…" paragraph with the ruling: the air-gap cause is disproved and recorded,
      the render gap is confirmed and the finding stays open and amended, and Phase 10 does
      not repair it. Keep the "**Not done if** the closure is recorded without the
      reproduction" sentence — it still governs, now applied to the correction.

   Leave the **CP-10 checklist** alone. Its "a disproved finding says how" line is answered
   at phase completion by the corrected record; a checklist the developer fills in after the
   phase is not this story's to edit.

6. **Do not fix the render gap.** The operator explicitly declined to widen Phase 10 into a
   bundle fix. Do not touch `index.html` or `gap-handoff.html`, do not investigate why
   `#gaps` renders no screen beyond what step 2 observes, and do not open a new finding for
   it — CER-005 now records it.

7. **Stamp convention note.** CER-010 proposes extending the date-and-commit stamp to
   harness-telemetry claims. That is a proposal, not in force; both of this story's stamped
   claims are about forqsite's own behaviour, which the Phase 6 convention already covers.
   CER-010 stays open and unmarked.

8. Proportionality note: this spec runs long for a two-file doc story because it carries a
   four-dump reproduction, a correction to a phase doc's record of fact, and an amendment
   that must verifiably *not* close its row.

**Spec-preflight note.** The scan reports no route and no `scope:` findings. Its six constant
warnings — `CER`, `CONTENT`, `GAP` (rail and backlog-row prefixes), `SUPERSEDED` (a marker
keyword defined in the build harness's `cer.RESOLUTION_MARKERS`, not in this repo), and
`MAP`, `SRV` (a Chromium flag value and a shell local in the reproduction block) — are all
intentional.

## Tests

No test suite (`test_command=true`, static HTML). These are the story's verification
commands, run from the repo root.

The marker probe (derives the harness scripts directory from a file already in the tree, so
neither builder nor reviewer types a home path):

```bash
FS=$(grep -oE '[^ "`]*skills/pairmode/scripts' CLAUDE.build.md | head -1); FS="${FS/#\~/$HOME}"
PATH=$HOME/.local/bin:$PATH uv run --project "${FS%/skills/pairmode/scripts}" python - "$FS" <<'PY'
import sys, pathlib; sys.path.insert(0, sys.argv[1])
import cer
rows = {l.split('|')[1].strip(): l for l in
        pathlib.Path('docs/cer/backlog.md').read_text().splitlines() if l.startswith('| CER-')}
for rid in ('CER-001','CER-005','CER-006','CER-008','CER-009','CER-010','CER-011','CER-012'):
    print(rid, cer.is_resolution_marked(rows[rid]))
PY
```

Acceptance: `CER-001 True`, and `False` for all seven others — CER-005 included. An amended
row reading as closed is a failure, not a rounding error.

Backlog integrity and the untouched-prose check:

```bash
grep -cE '^\| CER-[0-9]+ \|' docs/cer/backlog.md      # not less than the pre-build count
git diff -- docs/cer/backlog.md | grep -c '^-|'       # expected 2 — CER-001 and CER-005 only
old=$(git show HEAD:docs/cer/backlog.md | grep '^| CER-005 ' | sed 's/ | reviewer (CONTENT-019.*//')
new=$(grep '^| CER-005 ' docs/cer/backlog.md | sed 's/ \*\*Corrected.*//')
[ "$old" = "$new" ] && echo "PASS: CER-005 prose unchanged" \
  || { echo "FAIL:"; diff <(echo "$old") <(echo "$new"); }
```

Acceptance: the row count holds, exactly two rows are rewritten, `PASS`. (The identity check
is a post-build check by construction — run before the amendment lands it reports FAIL,
because `new` has nothing to truncate yet.)

The stamp check — whitespace-normalised, never a line-oriented verbatim grep, because a
multi-word phrase soft-wrapping across two source lines is a formatting accident, not a
content regression (CER-011):

```bash
python3 - <<'PY'
import re, pathlib
STAMP = r'20\d\d-\d\d-\d\d at [0-9a-f]{7,40}'
b = re.sub(r'\s+', ' ', pathlib.Path('docs/cer/backlog.md').read_text())
for rid in ('CER-001', 'CER-005'):
    seg = [s for s in b.split('| CER-') if s.startswith(rid[4:])][0]
    print(rid, bool(re.search(STAMP, seg)))
p = re.sub(r'\s+', ' ', pathlib.Path('docs/phases/phase-10.md').read_text())
print('phase-doc correction stamped:', bool(re.search(STAMP, p)))
print('original record retained    :',
      'Observed, air-gapped:' in p and 'host-resolver-rules' in p)
PY
```

Acceptance: `True` on all four lines.

The bundle guard:

```bash
git diff --stat -- index.html gap-handoff.html
grep -c 'exactly the case' gap-handoff.html
```

Acceptance: the diff prints nothing and the count is `1`.

Finally, the reviewer reads the builder's reported 2x2 output and the phase-doc correction
and confirms that each records observed values and distinguishes what was confirmed from
what was disproved — CP-10's "every close has evidence" and "backlog honesty" lines are
reads, not greps.

**Two prohibited assertion patterns.** Do not add a frozen-snapshot assertion against
`.companion/effort.db` (CER-009 — the build's own attempt rows land inside the same stamped
day). Do not assert a render fact by grepping a raw `--dump-dom` (CER-012 — that is the
exact error this story exists to correct).

## Out of scope

- **Closing CER-005.** It stays open and unmarked. This story corrects its evidence; only a
  fix to the render gap could close it, and that fix is not authorised.
- **Repairing the render gap** in `index.html` — no bundle edit of any kind, including the
  gap-wording reword the previous spec allowed as a contingency. CER-001's recon was
  re-verified; there is nothing to reword.
- **CER-006, CER-008, CER-009, CER-010, CER-011 and CER-012.** All stay open and unmarked.
  CER-012 in particular is the orchestrator's own finding about the assertion flaw; this
  story applies its lesson and does not close it.
- **Deleting the phase doc's original reproduction record.** It is corrected in place. A
  record that quietly loses what was believed cannot show that the belief was tested.
- **Editing the CP-10 checklist, the phase Goal, the Stories table, or the story ordering.**
  The phase-doc edits are corrections of fact, confined to the four locations in
  Instructions step 5.
- **Acting on CER-010's proposal** to extend the stamp convention to harness telemetry.
- **Re-opening the Phase 5 prune that removed GAP-011.**
