---
id: CONTENT-025
rail: CONTENT
title: Move the build-tooling audit out of this repository and refer the flex defect to the project that owns it
status: draft
phase: "10"
story_class: doc
auth_gated: false
schema_introduces: false
touches:
  - docs/pairmode-wiring-audit.md
  - docs/architecture.md
  - docs/checkpoints.md
  - docs/cer/backlog.md
  - docs/stories/CONTENT/CONTENT-020.md
  - docs/stories/CONTENT/CONTENT-022.md
  - docs/stories/CONTENT/CONTENT-024.md
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

`docs/pairmode-wiring-audit.md` records this repo's build-harness configuration and its
drift from harness convention. That is a subject about the build tooling, not about
administering forqsite, and it does not belong in this repository. This story removes it,
keeps the one fact in it that is genuinely about this project, makes every reference that
pointed at it resolve to something real, and disposes of the two backlog findings the
removal touches — one of which closes and one of which grew.

**This spec names no home-directory path literally.** Phase 10's principle applies to the
scaffolding as much as to the target, and CER-004's own finding text is one of the things
being redacted. Where a build-tooling path is needed (the marker probe in `## Tests`), it
is derived at run time from a file already in the tree rather than typed. `$HOME` used as
an unexpanded shell variable is not a home path and is permitted; writing out its expansion
is not.

## Requires

- CONTENT-023 complete — `docs/cer/backlog.md` carries the resolution-marker convention.
- CONTENT-024 complete — the CER-003 redaction precedent this story applies to CER-004.
- `docs/pairmode-wiring-audit.md` present in the tree at build time.

## Ruling (operator, 2026-09-21)

The phase doc left the destination open: the build tooling's own repository, a paste-ready
document here, an operator-local untracked file, or an explicitly authorised cross-repo
write. **The operator ruled: operator-local and untracked, at `~/flex-findings-20260921.md`
— outside both repositories.** Nothing is written into the build tooling's own repo and no
cross-repo commit is made.

The trade the operator accepted, recorded so it is not re-litigated: this is the
**lowest-durability** option of the four. The write-up is not versioned, not backed up by
either repo, and disappears with the machine. It was chosen anyway, to keep the boundary
between this repository and the build tooling's uncrossed — the per-story permission
manifests are scoped to this repo by construction, and the first exception to that would be
harder to reverse than a lost file is to rewrite.

This replaces the phase doc's "Open decision" paragraph for review purposes. The reviewer
checks against this ruling rather than re-opening the question.

## Recon (done; the builder does not repeat it)

**Every reference to the audit, as of commit `6f4d325`** (`grep -rIn 'pairmode-wiring-audit'
. --exclude-dir=.git` — seven files, nine hits):

| File | Kind | Treatment |
|---|---|---|
| `docs/architecture.md:49` | live | rewrite: drop the pointer, keep the surviving fact |
| `docs/checkpoints.md:52` | live | rewrite: drop the trailing `— see …` clause only |
| `docs/checkpoints.md:80` | live (historical record) | rewrite: name the audit by description, not by path |
| `docs/stories/CONTENT/CONTENT-020.md` | historical story (frontmatter, Context, Ensures, Instructions, **and a `test -f` in `## Tests`**) | relocation note, body unchanged |
| `docs/stories/CONTENT/CONTENT-022.md:86` | historical story | relocation note, body unchanged |
| `docs/stories/CONTENT/CONTENT-024.md:217` | historical story | relocation note, body unchanged |
| `docs/cer/backlog.md:38` | backlog row (CER-004) | redact + resolution marker |

Prose references that name no path — `docs/checkpoints.md:86` ("the wiring audit had no
staleness trigger"), `docs/phases/phase-9.md` § CONTENT-020 — are left alone. They describe
work that happened and do not resolve to a file, so nothing dangles.

**The treatment for historical story docs, and why.** A completed story doc is the record of
what was specified and done at the time; rewriting its body to describe a file it never
mentioned falsifies that record. But a reference that resolves to nothing fails CP-10's
"nothing left dangling" line. Both are satisfied by leaving the body byte-identical and
adding one **relocation note** immediately after the frontmatter, which says the file was
removed, by which story, why, and where the surviving fact went. The reference then resolves
— to an explanation in the same document rather than to a void. This explicitly covers
CONTENT-020's `primary_files:` entry and its `test -f docs/pairmode-wiring-audit.md` test
line: both stay as written, and the note states that the Tests block is a Phase 9 record and
is no longer re-runnable. The reviewer checks against this stated position; it is not an
invitation to invent a different one.

**The facts that must survive the removal.** Audit items 1, 4 and 5 were fixed in the files
they were about — `.gitignore`, `docs/phases/index.md` — so the fix is its own record and
nothing needs restating. Items 2, 6, 7, 8, 9 and 10 are about the build harness and leave
with the audit (they reappear in the operator-local write-up). Two exceptions:

- **The phases 3-7 consequence** already lives in `docs/checkpoints.md`, which is its right
  home, and is CONTENT-026's subject. **Do not duplicate it here** — CP-10 checks for
  duplicate state with independent writers.
- **The `gate-worker.md` removal** (audit item 3) is the one genuinely forqsite-local fact
  with no other home: this repo deliberately no longer carries `.claude/agents/gate-worker.md`
  because the dispatch that reached it was retired upstream, and it must not be restored by a
  future scaffold sync. It lands in `docs/architecture.md`, replacing the pointer at line 49.

**Spec-preflight note.** The scan reports no `scope:` findings and five "constant" warnings
— `CER`, `CONTENT`, `LOW`, `RESOLVED`, `WORKER`. All are intentional: two are story-rail
prefixes, `LOW` is a severity word quoted from an existing backlog row, and `RESOLVED` and
`WORKER` are harness-defined names (`cer.RESOLUTION_MARKERS`, the WORKER-004 grammar), not
constants in this repo's source tree.

**Marker forms verified** against the real `cer.is_resolution_marked` on 2026-09-21: the
CER-004 replacement below returns `True`, the CER-006 replacement returns `False`.

## Ensures

`docs/pairmode-wiring-audit.md` is absent from the tree; `grep -rIl 'pairmode-wiring-audit'
. --exclude-dir=.git` returns exactly the three historical story docs, `docs/cer/backlog.md`
and this story file — every one of which states, at that reference, that the file was removed
and where its surviving fact went (forbidden proxy: a live doc still naming the path, or a
historical doc whose reference is silently deleted rather than annotated);
`docs/architecture.md` carries the `gate-worker.md` fact and no longer duplicates the phases
3-7 reason, which stays only in `docs/checkpoints.md`; `cer.is_resolution_marked` returns
`True` for the rewritten CER-004 row, which keeps its ID, quadrant (Do Later), ordering,
source, date and phase, and `False` for CER-006, which is present, updated to record that the
finding grew and that a write-up exists operator-local, and left open (forbidden proxy:
closing CER-006 because the referral was made — a referral is not a fix); the `| CER-NNN |`
row count is not less than before the build and no row is removed, with CER-008 in particular
untouched and unmarked; and `git diff` adds no absolute home path, machine name or operator
identity anywhere in the tree (forbidden proxy: `$HOME` written out in full, or a `~`-path
expanded — the unexpanded `~`/`$HOME` forms are the permitted ones).

## Instructions

1. **Delete `docs/pairmode-wiring-audit.md`** (`git rm`).

2. **`docs/architecture.md`** — replace the sentence at line 49 that points at the audit with
   two or three sentences saying: this repo's build-harness wiring was audited against
   convention in Phase 9; the audit itself is not kept here because its subject is the build
   harness rather than forqsite, and was removed in Phase 10 (CONTENT-025); the one outcome
   that is about this repository is that `.claude/agents/gate-worker.md` was removed as a
   dark feature — the dispatch that would reach it was retired upstream — and must not be
   restored by a future scaffold sync. Do not restate the phases 3-7 gate history here.

3. **`docs/checkpoints.md`** — two edits, and only these two:
   - Line 52: delete the trailing `— see \`docs/pairmode-wiring-audit.md\`` clause. Leave the
     rest of that sentence exactly as it stands; **CONTENT-026 replaces the open-question
     wording with the operator's ruling, and this story must not pre-empt it.**
   - Line 80: keep the claim (CONTENT-020 did audit the wiring and did record it) but name
     the record by description instead of by path — e.g. "…and recorded it in a standalone
     wiring audit, since removed from this repository in Phase 10 (CONTENT-025) because its
     subject is the build harness."

4. **The three historical story docs** (`CONTENT-020.md`, `CONTENT-022.md`, `CONTENT-024.md`)
   — add one relocation note immediately after the closing `---` of the frontmatter, as a
   blockquote, and **change nothing else in the file**, including frontmatter, Tests blocks
   and the `primary_files:` entry. Use this wording, adjusted only for the per-file clause:

   > **Relocation note (CONTENT-025, 2026-09-21).** `docs/pairmode-wiring-audit.md`,
   > referenced below, was removed from this repository in Phase 10: its subject is the
   > build harness, not administering forqsite. Its harness findings were written up
   > operator-local and untracked; the one repo-local outcome (the `gate-worker.md`
   > removal) is recorded in `docs/architecture.md`, and the phases 3-7 gate history in
   > `docs/checkpoints.md`. This document is left as the Phase 9 record of what was
   > specified and done — its body is unchanged and is not rewritten to match the current
   > tree.

   For CONTENT-020 only, append one sentence: "Its `## Tests` block is therefore a historical
   record and no longer re-runnable as written."

5. **`docs/cer/backlog.md` — CER-004.** Replace the row with exactly this (adjust only if the
   table's formatting requires it). The row's own text quotes a version-pinned cache path
   under a home directory; that is the same instance-naming class CER-003 was redacted for, so
   it is described rather than quoted:

   ```
   | CER-004 | Operator ruling wanted: whether docs/pairmode-wiring-audit.md's references to a version-pinned flex cache path under a home directory and to flex-internal story IDs are acceptable in a public repo, or should be generalized. Judged LOW-severity disclosure, not blocking. **RESOLVED cp-10 — the audit doc was removed from this repository in CONTENT-025 (its subject is the build harness, not forqsite); the cache path was redacted from this row too, under the same principle applied to CER-003** | security-auditor (Phase 9 checkpoint) | 2026-09-21 | 9 |
   ```

6. **`docs/cer/backlog.md` — CER-006.** Replace the row with exactly this. It is **not**
   closed: the defect is live and recurring, and a referral is not a fix.

   ```
   | CER-006 | Flex effort recording is unreliable in this harness: `read_completed_spawn` parses a worker's verdict from its final message text, but some subagents deliver the WORKER-004 block via the hand-back channel and sign off in prose, leaving `outcome` NULL. Original finding (phases 8-9): six rows needed hand reconciliation, each carrying a `notes` field saying so. Report upstream to flex rather than patching the cache. **Grew in Phase 10.** Measured against the effort database as of 2026-09-21: of 36 attempt rows, 13 carry a hand-reconciliation note (9 from the phase 8-9 work — rows 15, 16, 17, 18, 21, 24, 25, 31, 32 — and 4 added by Phase 10's own stories: CONTENT-023 rows 33/34, CONTENT-024 rows 35/36), and 6 still carry a NULL `outcome` (ids 1, 3, 5, 6, 9, 11, all builder attempts from July 2026 — a different and older population, predating the reconciliation practice). The original six-row count could not be reproduced from the database and is left as the historical claim it was rather than silently restated. CONTENT-025 wrote the symptom and the transcribed rows up for the project that owns the defect, operator-local and untracked. Referring it upstream does not fix it here, so this finding stays open. | orchestrator (phases 8-9, updated Phase 10) | 2026-09-21 | 9 |
   ```

   **Every number in that row was measured, and the two populations are deliberately
   distinct** — "needed hand reconciliation" (13) is not "still carries a NULL outcome" (6),
   and today's four rows belong to the first group, not the second. Do not merge them into a
   single impressive figure: the point of the update is that the finding *grew*, which stands
   on either number. The original "six rows across phases 8-9" could not be reproduced (nine
   rows carried a reconciliation note before 2026-09-21, and how the original six was counted
   is unknown), so it is kept verbatim as the historical claim and not restated as nine. Do
   not invent a reconciliation between the two.

   Change nothing else in the file — no other row's text, no ordering, no quadrant move, and
   nothing at all to CER-008.

7. **Do not attempt the operator-local write-up.** It is written outside this worktree by the
   orchestrator (next section). A builder's permission manifest is scoped to this repository
   and a write to a home directory will be refused; a refusal is the correct outcome, not a
   reason to retry another way. Nothing under the build tooling's cache is modified by this
   story at all.

8. Proportionality note: this spec runs past this project's usual doc-story length because it
   edits seven files, carries an operator ruling, states a contested treatment for historical
   docs, and fully specifies a deliverable the builder does not write.

## Orchestrator step — the operator-local write-up (not a repo change)

Performed outside the worktree, after the build merges. Destination `~/flex-findings-20260921.md`
(tilde form only — never write the expanded path, here or in the file). The file must contain
these four parts:

1. **The defect, stated as a symptom.** How the verdict is read from a worker's final message
   text, how a hand-back-channel delivery plus a prose sign-off leaves `outcome` NULL, and
   what the operator sees: a spawn row and a verdict row stranded, needing hand reconciliation
   before the phase can be checkpointed.
2. **The affected rows, transcribed** — as two clearly separated populations, because they are
   not the same rows and conflating them is how the first draft of CER-006 got its numbers
   wrong. As of 2026-09-21, of 36 attempt rows: (a) the **6 still carrying a NULL `outcome`**
   — ids 1, 3, 5, 6, 9, 11, all builder attempts from July 2026, which predate the
   reconciliation practice and were never reconciled; and (b) the **13 carrying a
   hand-reconciliation note** — ids 15, 16, 17, 18, 21, 24, 25, 31, 32 from the phase 8-9 work
   and 33, 34, 35, 36 from Phase 10's own CONTENT-023 and CONTENT-024. One line per row: id,
   story id, worker role, recorded outcome, and the `notes` text. Stamp the figures "as of
   2026-09-21"; they move as more stories run. Read them with the harness's own effort reader
   or a read-only query; do not copy a database file into either repository.
3. **Whether it duplicates a finding already open upstream.** Check the build tooling's own
   backlog for an existing finding about this read path and record the answer either way — the
   finding's ID if one exists, or an explicit "checked, no open finding" naming what was
   checked. An unanswered question here is a fail.
4. **The harness-relevant content from the removed audit**, carried over so it is not lost:
   the standalone-invocation dependency gap (the dark-feature and audit scripts need packages
   flex's own venv provides, so the documented invocation lines fail outside it); the phase
   index template's boilerplate assuming per-quadrant backlog phase docs that this project
   never had; the operator seed narrative being excluded from the shared narrative and
   canonical-file lists, so neither scan flags its absence; the retired gate-worker shell still
   arriving from an older scaffold; and the failure mode behind it all — a prose value in a
   field that is shelled out fails at exit 127 and surfaces only as "gate did not pass".

**Constraints, absolute.** No operator identity, no absolute home path, no machine name
anywhere in the file, and specifically not in the transcribed `notes` text — redact any that
appear to the `~`-form or to a class description before transcribing. The irony is noted and
handled deliberately: the file lives at a home path, so it never states its own location and
never names the directory it sits in.

## Tests

No test suite (`test_command=true`, static HTML). These are the story's verification commands.

```bash
cd /mnt/work/forqsite.help
test ! -e docs/pairmode-wiring-audit.md && echo AUDIT-DOC-REMOVED
grep -rIl 'pairmode-wiring-audit' . --exclude-dir=.git | sort
```

Acceptance: the marker prints, and the second command lists exactly these five and nothing
else — `./docs/cer/backlog.md`, `./docs/stories/CONTENT/CONTENT-020.md`,
`./docs/stories/CONTENT/CONTENT-022.md`, `./docs/stories/CONTENT/CONTENT-024.md`,
`./docs/stories/CONTENT/CONTENT-025.md`. Then read each hit and confirm it states the file
was removed and where the surviving fact went — that part is a read, because a grep cannot
check it.

The marker probe. It derives the harness scripts directory from a file already in the tree, so
neither builder nor reviewer types a home path (verified to run, 2026-09-21):

```bash
FS=$(grep -oE '[^ "`]*skills/pairmode/scripts' CLAUDE.build.md | head -1); FS="${FS/#\~/$HOME}"
PATH=$HOME/.local/bin:$PATH uv run --project "${FS%/skills/pairmode/scripts}" python - "$FS" <<'PY'
import sys, pathlib; sys.path.insert(0, sys.argv[1])
import cer
rows = {l.split('|')[1].strip(): l for l in
        pathlib.Path('docs/cer/backlog.md').read_text().splitlines() if l.startswith('| CER-')}
for rid in ('CER-004', 'CER-006', 'CER-008'):
    print(rid, cer.is_resolution_marked(rows[rid]))
PY
```

Acceptance: `CER-004 True`, `CER-006 False`, `CER-008 False`.

```bash
grep -cE '^\| CER-[0-9]+ \|' docs/cer/backlog.md        # not less than the pre-build count
git diff -- docs/cer/backlog.md | grep '^-|' | wc -l    # expected 2 — CER-004 and CER-006 only
git diff | grep '^+' | grep -nF -e "$HOME" -e "$(hostname)"  # expected: no output
```

Acceptance: the row count holds, exactly two rows are rewritten, and the added-lines scan is
empty. Finally, read `docs/checkpoints.md` and confirm the phases 3-7 reason still reads as it
did and appears in no other file.

The effort-database probe, for CER-006's figures. It re-derives the counts from live data so
the reviewer checks the row against the database rather than against this spec's prose. The
row is stamped "as of 2026-09-21", so the probe asserts the figures **for that date's
population**, not for whatever the database holds at review time — more stories will have run
by then, and a probe frozen to a live total would fail for the wrong reason:

```bash
cd /mnt/work/forqsite.help
python3 - <<'PY'
import sqlite3
db = sqlite3.connect('file:.companion/effort.db?mode=ro', uri=True)
q = lambda s, *a: db.execute(s, a).fetchall()
asof = '2026-09-21'
P10 = ('CONTENT-023', 'CONTENT-024')          # the stories that grew the finding
total    = q("select count(*) from attempts where substr(ts,1,10) <= ?", asof)[0][0]
recon    = [r[0] for r in q("select id from attempts where notes like '%reconcil%' "
                            "and substr(ts,1,10) <= ? order by id", asof)]
grew     = [r[0] for r in q("select id from attempts where notes like '%reconcil%' "
                            "and story_id in (?, ?) order by id", *P10)]
stranded = q("select id, story_id, agent_role, substr(ts,1,10) from attempts "
             "where outcome is null and substr(ts,1,10) <= ? order by id", asof)
print(f"as of {asof}: total={total} reconciled_note={len(recon)} "
      f"(of which Phase 10: {len(grew)} -> {grew}) null_outcome={len(stranded)}")
for r in stranded: print("  stranded", *r)
assert (total, len(recon), len(grew), len(stranded)) == (36, 13, 4, 6), "row's figures no longer hold for 2026-09-21"
assert recon == [15, 16, 17, 18, 21, 24, 25, 31, 32, 33, 34, 35, 36]
assert [r[0] for r in stranded] == [1, 3, 5, 6, 9, 11]
print("PASS — CER-006's as-of figures reproduce")
PY
```

Acceptance: `PASS`, and the printed stranded rows are the six July-2026 builder attempts the
row names. Run it from the main checkout — `.companion/` is gitignored and does not exist in
a story worktree; if the file is missing, say so rather than reporting the probe as clean.

## Out of scope

- **Recording the phases 3-7 ruling.** CONTENT-026's subject. This story removes a dangling
  pointer from line 52; it does not answer the question that sentence asks.
- **CER-008**, and every backlog row other than CER-004 and CER-006. CER-008 stays open and
  unmarked.
- **Patching the build tooling's cache, or committing into its repository.** The ruling above
  forecloses both; the phase doc forbids the first outright.
- **Rewriting the bodies of the historical story docs**, including CONTENT-020's `## Tests`
  block and `primary_files:` entry. They are the Phase 9 record; the relocation note is the
  whole treatment.
- **Path-free prose mentions** of the audit in `docs/checkpoints.md:86` and
  `docs/phases/phase-9.md`. They name no file and so resolve to nothing missing.
- **The published bundles.** Untouched; this is a documentation change only.
