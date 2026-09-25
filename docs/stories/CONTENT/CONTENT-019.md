---
id: CONTENT-019
rail: CONTENT
title: Record the content-migration gap as a new numbered entry in Known gaps
status: complete
phase: "8"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - gap-handoff.html
touches:
  - index.html
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->

## Context

Phase 8's three-stream model names **content** as the one stream with "No, and no
mechanism" in the reversibility column, and `#promote` (CONTENT-016) now publishes that
claim. The Known gaps backlog — the site's list of what a self-hoster will hit — does not
carry it. The concrete failure is a pack upgrade that renames a field key: blocks already
stored keep the old key, the editor shows the field empty, `render` falls through to its
default, and nothing throws, logs, or fails a health check. It is the same
silent-degradation shape the site already names for a pack missing from the build, and a
reader who has been told the content stream is irreversible deserves the entry that says
what it costs them and what they can do about it today. This story records the gap. It
does not close it, and it does not choose the mechanism — that ruling is held in
forqsite's own backlog and is the operator's (phase doc, "What is NOT in scope").

## Requires

- The bundle-edit path: `scripts/bundle-template.py extract|inject|verify`. Extract each
  bundle to a scratch file, edit only there, inject once, verify. Never hand-edit the
  encoded `__bundler/template` payload inside `gap-handoff.html` or `index.html`.
- the local forqsite clone checked out at `7089b9dc` (branch `main`). Every claim below was
  verified there on 2026-09-19; the citations in `## Instructions` are the evidence a
  reviewer re-checks, at that commit.
- CONTENT-017 complete: that a pack's block configuration is `jsonb` on the block row,
  validated by the pack's own `dataSchema`, is already established and published. This
  entry builds on it and does not re-derive it.

## Ensures

`gap-handoff.html` carries one new entry, `GAP-012`, built with the same `mk(id, pri,
area, title, problem, evidence, approach, ac)` call every existing entry uses, stating as
verified fact that a pack upgrade renaming a field key does not rewrite stored block data
— the editor shows the field empty, `render` falls through to its default, and nothing
reports it — whose **HOW TO FIX IT** says the fix is undecided and upstream's to rule on
while giving the reader the workaround they have today (check a pack's release notes for
renamed keys before upgrading, and plan the data rewrite as part of that upgrade), whose
**EVIDENCE** rows cite the forqsite files and lines listed in `## Instructions` plus a
closing row naming `nullvalues/forqsite@7089b9dc` and the 2026-09-19 check date, and whose
**DONE WHEN** items are mechanism-neutral; the page's item count and priority chip count
are corrected to match; `index.html`'s `ledger` gains the matching `GAP-012` row; and both
bundles pass `bundle-template.py verify`.

Forbidden proxies, each of which would satisfy a careless read of the above and must not
appear:

- Reusing `GAP-011` (or `001`/`002`) as the new number. Those were issued and pruned
  (Phase 5's CONTENT-008; `docs/checkpoints.md`, `docs/phases/phase-7.md` still cite them),
  and `#gap-011` meant a different, shipped gap. Numbers retire; they do not recycle.
  (Forbidden proxy: "the highest entry on the page is 010, so the next one is 011".)
- Naming, ranking, or leaning toward any particular fix — a dual-read in the pack, a
  declared rename in the manifest, a `migrate` hook, a lazy read-time chain, or a platform
  script. The entry records the gap; it does not pre-empt the ruling. (Forbidden proxy:
  "the pack should read `data.linkTarget ?? data.linkedPage`".)
- **DONE WHEN** items written against a mechanism rather than against an outcome.
  (Forbidden proxy: "the manifest carries a `rename` map".)
- Advancing either page-level stamp (`Verified 2026-09-16 against
  nullvalues/forqsite@17b78645` in the intro paragraph, and the footer line) to `7089b9dc`.
  This story verified one entry, not the other eight; moving the page stamp would assert a
  re-verification that did not happen. (Forbidden proxy: "the newest entry is at 7089b9dc,
  so the page is.")
- Adding the entry while leaving "eight of them" in the intro paragraph or the priority
  chip count unchanged. (Forbidden proxy: a correct entry on a page that counts itself
  wrong.)
- Adding it to `gap-handoff.html` only, leaving `index.html`'s Known gaps ledger one row
  short of the page it links into.
- Placing the new item out of its priority group in the `items` array. The array is
  rendered in order and the chips jump to the first item of each priority; a P2 sitting
  after the P3s reads as a page that lost track of its own ordering.
- Build-process vocabulary — `R0`–`R4`, "ring", "story", "phase", "CONTENT-019" — anywhere
  in the shipped strings.
- Markup inside the `mk(...)` strings. They are rendered as text, not HTML; a `<strong>` or
  an `<a href>` ships literally.
- Describing what the page used to say, or what this change adds (CP-8 no self-narration).

## Instructions

1. `python3 scripts/bundle-template.py extract gap-handoff.html /tmp/gap.html` and
   `python3 scripts/bundle-template.py extract index.html /tmp/idx.html`. Edit only the
   scratch files.

2. **The new entry.** In `/tmp/gap.html`, add one `mk(...)` call to the `items` array in
   `renderVals()`, with `id` `'GAP-012'`, `pri` `'P2'`, and an `area` naming the subject in
   the style of the existing labels (`'CONTENT MIGRATION'` fits the set). Place it at the
   end of the P2 group — immediately after `GAP-008`, before `GAP-009` — so the array stays
   in priority order. Match the surrounding call's shape exactly: plain strings, `\'` for
   apostrophes, evidence as `[file, what]` pairs, `ac` as an array of one-sentence items.

3. **PROBLEM.** A pack upgrade that renames a field key does not rewrite block data
   already stored. Stored blocks keep the old key; the editor renders the field for the new
   key empty; `render` falls through to its null-or-default path, so a live page shows the
   default in place of the content that is still sitting in the row. Nothing throws, no
   save is rejected, the health check passes, and no log line records it — the first
   report is a reader noticing the page is wrong. Say that renaming a block `type` orphans
   existing blocks the same way. Keep it to the shape and length of `GAP-007`'s PROBLEM.

4. **EVIDENCE.** Use these, verified at `7089b9dc`; keep the `what` text to one clause each:
   - `docs/block-provider-spec.md:431` — "Field key renames are not migrated"; stored
     blocks carry the old key, editor empty, `render` falls to its null-or-default path,
     nothing rewrites stored data, and the rewrite is assigned to the operator.
   - `src/components/editor/BlockEditor.tsx:2013` — each editor field reads
     `data[field.key]`; a key the stored row does not have reads `undefined` and renders
     empty, with no notice.
   - `src/block-providers/core/index.ts:151` — `d.label ?? 'Button'`: the shipped render
     path substitutes a literal default for a missing key.
   - `src/services/block-registry/index.ts:329-370` — the only validation on the save path;
     an absent optional key is valid, so nothing errors, and `dataSchema.parse` (`:357`)
     strips the key the rename left behind, so the next save of that page deletes the old
     value for good.
   - `src/db/migrations/0091_reshape_paragraph_content_docs.sql` — when a rewrite has been
     needed, it has been done by hand as platform SQL; `package.json` has no script for it
     (`db:migrate` is drizzle SQL, `migrate:export`/`migrate:import` are tenant transfer).
   - `nullvalues/forqsite@7089b9dc` — every line above checked at this commit, 2026-09-19.
     (This closing row is the entry's verification stamp: the template has no per-entry
     stamp slot and the page-level stamps stay where they are — see `## Ensures`.)

5. **HOW TO FIX IT — undecided, and say so.** State that no mechanism exists and the choice
   of one has not been made: it sits in forqsite's backlog and is forqsite's to rule on.
   Give the reader why it is unowned rather than overlooked — a pack cannot perform the
   rewrite (packs have no database access) and the platform cannot either (it owns the
   table but has no way to know two field names are the same field). One neutral sentence
   on what the choice turns on is allowed and no more: whether a fix rewrites stored data
   or leaves it alone is what decides whether the content stream stays reversible. Then the
   part the reader can act on today: before upgrading a pack, read its release notes for
   renamed keys, and plan the data rewrite as part of that upgrade rather than after it.

6. **DONE WHEN.** Three or four items, each an outcome any mechanism could satisfy — e.g.
   a pack upgrade that renames a key has a documented, repeatable route for rewriting
   stored block data, whichever route is chosen; the route is rehearsed against a
   throwaway copy of real data before production, and the fact that a rewrite was needed
   and performed is recorded somewhere an operator can find later; a block whose stored
   data no longer matches its pack's current field keys can be found without opening pages
   one at a time in the editor. No item may name a mechanism.

7. **Counts.** In `/tmp/gap.html`, change "eight of them" in the intro paragraph to "nine
   of them", and the P2 chip from `× 3` to `× 4`. Add one TL;DR bullet in the existing
   voice placing the new entry in the reading order — it is not work to schedule; it is
   what to read before the first pack upgrade. Do not restate its content there.

8. **The index ledger.** In `/tmp/idx.html`, add a `{ id: 'GAP-012', pri: 'P2', priColor:
   P2, sum: '…' }` row to the `ledger` array, in the same position relative to its
   neighbours as step 2 used, with a one-sentence summary in the voice of the rows around
   it. Change nothing else in `index.html` — the setup-stage list and the `#promote`
   section are not this story's.

9. `python3 scripts/bundle-template.py inject gap-handoff.html /tmp/gap.html` and the same
   for `index.html`, then `verify` both.

*Ideology note:* step 1's extract/inject path is written in to preserve the
Generated-artifact discipline constraint under its Phase 2 loop-mediated exception. The
change is string data inside the existing bundles — no new asset, no external request — so
Zero runtime dependencies (no override permitted) is untouched.

*Scope note:* spec-preflight's three `scope:` findings are expected and left standing:
`scripts/bundle-template.py` is executed, not modified, and `docs/checkpoints.md` /
`docs/phases/phase-7.md` are cited only as the record that `GAP-011` was already issued —
none is written by this story. The forqsite paths cited
in step 4 are evidence in a sibling repository and are deliberately absent from `touches:`.
`index.html` is in `touches:` because step 8 writes one ledger row to it; `gap-handoff.html`
is the story's subject.

*Proportionality note:* longer than a one-file `doc` story normally warrants because every
sentence the entry ships is a claim about a second repository carrying its own citation,
and because the two hardest constraints here — the retired-number rule and the
"undecided, do not propose a mechanism" rule — are ones a builder cannot infer from the
page it is editing.

## Tests

```bash
cd "$(git rev-parse --show-toplevel)"
python3 scripts/bundle-template.py verify gap-handoff.html
python3 scripts/bundle-template.py verify index.html
python3 scripts/bundle-template.py extract gap-handoff.html /tmp/check-gap.html
node --check <(sed -n '/type="text\/x-dc"/,/<\/script>/p' /tmp/check-gap.html | sed '1d;$d')
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 \
  --dump-dom "file://$PWD/gap-handoff.html#gap-012" > /tmp/gap.dom
grep -c 'GAP-012' /tmp/gap.dom
grep -ci 'nine of them' /tmp/gap.dom
grep -c '× 4' /tmp/gap.dom
grep -c 'nullvalues/forqsite@7089b9dc' /tmp/gap.dom
grep -c 'nullvalues/forqsite@17b78645' /tmp/gap.dom
grep -Eic 'release notes' /tmp/gap.dom
grep -Eic 'R[0-4]\b|\bring\b|\bstory\b|CONTENT-019' /tmp/gap.dom
grep -Eic 'migrate\(|dual.read|\?\? data\.|manifest carries' /tmp/gap.dom
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 \
  --dump-dom "file://$PWD/index.html#gaps" > /tmp/idx.dom
grep -c 'GAP-012' /tmp/idx.dom
```

Acceptance: both `verify` runs report byte-identical; `node --check` exits 0; the rendered
gap page shows `GAP-012` with all four labelled blocks (PROBLEM / EVIDENCE / HOW TO FIX IT
/ DONE WHEN), "nine of them", a `P2 … × 4` chip, the `7089b9dc` evidence row, and the
`17b78645` page stamps still present and unchanged; the workaround sentence is there; the
build-process-vocabulary grep and the named-mechanism grep both return 0; the index ledger
shows one `GAP-012` row. Also open both files from `file://` and confirm the P2 chip still
lands on the first P2 entry, the new card sits between `GAP-008` and `GAP-009`, and the
ledger row's link reaches `gap-handoff.html#gap-012`.

## Out of scope

- Choosing, proposing or implying a content-migration mechanism, or reproducing forqsite's
  four-option comparison. The ruling is the operator's and is held upstream.
- Editing `#promote`, `#packs` or the Upgrade section (CONTENT-016/017/018, all complete).
  This entry restates nothing they publish and adds no cross-link into them.
- Re-verifying `GAP-003`…`GAP-010` or advancing the page-level verification stamps. Anything
  found stale in those entries is recorded, not fixed here.
- The setup-stage checklist in `index.html` that maps stages to gap IDs — the content
  stream is not a fresh-install stage and does not belong in it.
- Pruning resolved entries, renumbering the backlog, or changing the priority of any
  existing gap.
