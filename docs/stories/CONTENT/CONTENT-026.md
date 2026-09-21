---
id: CONTENT-026
rail: CONTENT
title: Record the publication policy and the phases 3-7 ruling where each belongs
status: complete
phase: "10"
story_class: doc
auth_gated: false
schema_introduces: false
touches:
  - docs/ideology.md
  - docs/checkpoints.md
  - docs/cer/backlog.md
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

Two of the four operator rulings this phase executes are decisions to *keep things as they
are* — publish the source citations, leave phases 3-7 untagged. A ruling that changes
nothing leaves no trace unless it is written down, so both questions have already been
re-raised once (CER-002 at the Phase 8 security gate, CER-007 by the Phase 9 wiring audit)
and will be re-raised at every gate until the answer lives somewhere a reviewer reads.
This story writes each ruling into the one document that is its home, and closes the two
backlog rows that asked for it. It creates no tag: that is the ruling, not an omission.

## Requires

- CONTENT-023 complete — `docs/cer/backlog.md` carries the resolution-marker convention.
- CONTENT-024 complete — `docs/ideology.md` § Accepted constraints carries "Name the class,
  not the instance"; this story's new entry sits beside it and bounds it.
- CONTENT-025 complete — it removed the relocated-file pointer from the phases 3-7 paragraph
  in `docs/checkpoints.md` and deliberately left that paragraph's open-question sentence
  intact for this story.

## Recon (done; the builder does not repeat it)

**Where each ruling goes, and why.**

- *The citations ruling* → `docs/ideology.md` § Accepted constraints, as a fourth entry
  after "Name the class, not the instance". It is a publication policy, not a documentation
  constraint, which argues against that home — but it is specifically the **boundary** of
  the constraint CONTENT-024 just landed. That constraint reads "no host name, absolute
  path, or other deployment-specific identifier may appear in a live description of the
  architecture"; read tree-wide by a reviewer who does not know the ruling, it is exactly
  the rule that would strip GAP-012's `path:line` citations from the published bundle. A
  boundary recorded away from the rule it bounds does not get read with it.
  `docs/architecture.md` was the alternative and is rejected: it has no content- or
  publication-conventions section (its headings are Stack, Domain model, Module structure,
  Deployment, Layer rules, Protected files, Non-negotiables), so the policy would arrive as
  a new section of one, in the document a security reviewer reads *last*.
- *The phases 3-7 ruling* → `docs/checkpoints.md`, in the existing paragraph that asks the
  question. The phase doc names that file; CONTENT-025 § Out of scope reserved the sentence
  for this story. It is recorded **there and nowhere else** — CP-10 checks for duplicate
  state with independent writers, and a second copy of the reason in the backlog row or in
  `docs/phases/index.md` is exactly that.

**What the citations actually are** (read from the bundles at `eaa2da8`, 2026-09-21): each
Known-gaps entry carries an evidence list of `path:line` references into forqsite's own tree
(`docs/…md:431`, `src/components/editor/BlockEditor.tsx:2013`, `src/services/…:329-370`)
plus a `nullvalues/forqsite@<commit>` stamp and a "verified <date> against
nullvalues/forqsite@<commit>" footer. The reader of this site is a forqsite self-hoster or
administrator, so that tree is the reader's own.

**CER-002 carries no identifier to redact** — checked at `eaa2da8` against CONTENT-024's
precedent. The row *describes* the citations ("cites forqsite source paths and a commit
hash") without quoting a path or a hash, and it names no host, absolute path or machine. So
unlike CER-003 and CER-004, its pre-marker text stays byte-identical; the builder re-checks
this (Tests) rather than assuming it.

**No `cp-3`..`cp-7` tag exists** — `git tag -l` unfiltered at `eaa2da8` returns exactly
`cp-8`, `cp-9`, `cp1-bootstrap-complete`, `cp2-docs-refresh-complete`. Unfiltered is the
correct listing per this file's own naming note: a `cp-*` glob misses the two legacy names.

**Marker forms verified** against the real `cer.is_resolution_marked` on 2026-09-21: both
replacement rows below return `True`; CER-006, CER-008, CER-009 and CER-010 return `False`
as they currently stand and must still return `False` after the build.

## Ensures

`cer.is_resolution_marked` returns `True` for the rewritten CER-002 and CER-007 rows and
`False` for CER-006, CER-008, CER-009 and CER-010 (forbidden proxy: closing a neighbouring
row because this story happened to touch the file); both rewritten rows keep their ID,
quadrant (Do Later), ordering, source, date and phase, and CER-002's pre-marker text is
byte-identical to its pre-build form; the `| CER-NNN |` row count is not less than before
the build and no row is removed; `git tag -l`, listed unfiltered, contains no tag naming
any of phases 3-7 in any convention, and the build creates no tag at all (forbidden proxy:
a tag created "to complete the series" and the ruling recorded anyway — the ruling *is* that
the tag does not exist); `docs/ideology.md` § Accepted constraints carries a fourth entry
recording the KEEP ruling in the same Rule/Protects/Rationale/Override path shape as its
three siblings, giving the reason that the cited paths name the reader's own source tree and
that the citations are what make the site's claims checkable, and naming its boundary
against "Name the class, not the instance"; `docs/checkpoints.md` states the phases 3-7
ruling with its reason in place of the open question, and that reason appears in exactly one
tracked file besides this spec (forbidden proxy: the reason restated in the CER-007 row or
in `docs/phases/index.md` — the row may point at the file, never repeat it); and
`index.html` and `gap-handoff.html` are untouched.

## Instructions

1. **`docs/ideology.md`** — add a fourth accepted constraint immediately after "Name the
   class, not the instance", matching the existing four-field format exactly. Suggested
   name: **Cite the source that makes a claim checkable**.
   - *Rule:* a published claim about forqsite's behaviour carries its evidence — the
     forqsite source `path:line` it was read from and the `repo@commit` it was checked at —
     and that evidence is published as written. Citations are not stripped as internal
     detail.
   - *Protects:* the reader's ability to verify a claim against their own installation
     instead of trusting the page, and the site's own defence against silent drift (a
     citation that no longer matches is a detectable failure; an uncited assertion is not).
   - *Rationale:* the audience self-hosts forqsite, so the cited tree is the reader's own
     source tree, not a third party's internals. Recording the ruling is the point: the
     question was raised at the Phase 8 security gate (CER-002) and will be raised again at
     every gate unless the answer is written where a reviewer reads it.
   - *Override path:* a citation is dropped only when the claim it supports is removed.
   - Close the entry with the boundary, in one sentence: this constraint governs the
     product's source tree, which the reader also has; "Name the class, not the instance"
     governs our own deployment, and nothing here grants a host name, an absolute path or a
     machine name of ours any publication right. Do not edit the "Name the class" entry to
     add a reciprocal pointer — one direction only, so there is a single writer.

2. **`docs/checkpoints.md`** — in the paragraph that begins `**Phases 3-7 have no entry here
   and no tag.**` (inside the `## cp-8` section), keep every sentence up to and including
   "…without ever passing a green gate." and replace only the final sentence — "Whether to
   back-tag them is an open operator question.", which wraps across two lines — with the
   ruling. Locate it by that text, not by line number. The replacement must say all four of:
   - the operator ruled, on 2026-09-21 (CONTENT-026), that they stay untagged;
   - why: a `cp-<N>` tag asserts the checkpoint sequence passed, and for these phases it did
     not — back-tagging would record a gate result that was never obtained, making this file
     less trustworthy rather than more;
   - that the work itself is not unverified, because later phases re-check it regardless.
     Cite the two checkable instances rather than asserting it: the checkpoint gates run
     against the current tree, not a phase-scoped diff (cp-8's dark-feature-scan failed on
     an artifact that predated Phase 8 — recorded in this same file), and Phase 10's
     CONTENT-024 re-read and corrected `docs/phases/phase-4.md`;
   - that the gap from 3 to 7 in the `cp-*` series is therefore **a deliberate state
     recorded here, not an oversight** — include that phrase verbatim, it is what the
     duplicate-state test greps for — and not an invitation to backfill. Close by naming
     CER-007 as closed against this record.

   Change nothing else in the file. Do not add `## cp-3`..`## cp-7` sections: a section
   here describes a checkpoint that happened.

3. **Create no tag.** Not `cp-3`..`cp-7`, not any other. If a build step seems to want one,
   that is the step to drop.

4. **`docs/cer/backlog.md`** — replace exactly these two rows and nothing else. No other
   row's text, no ordering, no quadrant move; CER-006, CER-008, CER-009 and CER-010 are
   untouched. Each marker names a document as its evidence and does not repeat the reasoning
   that document holds.

   ```
   | CER-002 | GAP-012 (and the Known gaps convention generally) cites forqsite source paths and a commit hash on a publicly served page. Matches the page's existing citation convention, so not a Phase 8 regression — needs an operator ruling on whether product-repo internal detail belongs in public docs. **RESOLVED cp-10 — operator ruled KEEP: the cited paths name the reader's own source tree, and the citations are what make the site's claims checkable. Recorded as deliberate publication policy in docs/ideology.md § Accepted constraints (CONTENT-026)** | security-auditor (Phase 8 checkpoint) | 2026-09-18 | 8 |
   ```

   ```
   | CER-007 | Phases 3-7 were marked complete in docs/phases/index.md without ever passing a green build gate (the prose `test_command` failed red at exit 127 throughout). Open operator question whether to back-tag them. **RESOLVED cp-10 — operator ruled: leave untagged; no `cp-3`..`cp-7` tag is created. The ruling and its reason are recorded in docs/checkpoints.md (CONTENT-026) and are not restated here.** | CONTENT-020 audit | 2026-09-21 | 9 |
   ```

5. Proportionality note: this spec runs past a three-file doc story's usual length because it
   carries two operator rulings, a placement decision the phase doc left to the story, and a
   negative acceptance criterion (a tag that must not exist).

**Spec-preflight note.** The scan's "constant" warnings — `CER`, `CONTENT`, `GAP`, `KEEP`,
`RESOLVED` — are intentional: rail and backlog-row prefixes, the operator's one-word ruling,
and a marker keyword defined in the build harness (`cer.RESOLUTION_MARKERS`), not in this
repo's source tree. Its two `scope:` findings — `docs/phases/index.md` and
`docs/phases/phase-4.md` — are intentional too, and deliberately **not** added to `touches:`:
both are named as things this story does not edit (the first is listed in Out of scope, the
second is cited as evidence that a later phase re-checked an earlier one). A path named to
forbid editing it must not become declared scope.

## Tests

No test suite (`test_command=true`, static HTML). These are the story's verification commands,
run from the repo root.

The tag assertion — unfiltered, because a `cp-*` glob misses the legacy tag names:

```bash
git tag -l | sort | tee /dev/stderr | grep -qE '(^|[^0-9])cp-?[3-7]([^0-9]|$)' \
  && echo "FAIL: a phases 3-7 tag exists" || echo "PASS: no cp-3..cp-7 tag"
```

Acceptance: `PASS`, and the listing printed is exactly `cp-8`, `cp-9`,
`cp1-bootstrap-complete`, `cp2-docs-refresh-complete` — the same four as before the build.

The marker probe. It derives the harness scripts directory from a file already in the tree,
so neither builder nor reviewer types a home path (verified to run, 2026-09-21):

```bash
FS=$(grep -oE '[^ "`]*skills/pairmode/scripts' CLAUDE.build.md | head -1); FS="${FS/#\~/$HOME}"
PATH=$HOME/.local/bin:$PATH uv run --project "${FS%/skills/pairmode/scripts}" python - "$FS" <<'PY'
import sys, pathlib; sys.path.insert(0, sys.argv[1])
import cer
rows = {l.split('|')[1].strip(): l for l in
        pathlib.Path('docs/cer/backlog.md').read_text().splitlines() if l.startswith('| CER-')}
for rid in ('CER-002', 'CER-007', 'CER-006', 'CER-008', 'CER-009', 'CER-010'):
    print(rid, cer.is_resolution_marked(rows[rid]))
PY
```

Acceptance: `CER-002 True`, `CER-007 True`, and `False` for the other four.

The backlog-integrity and no-redaction-needed checks:

```bash
grep -cE '^\| CER-[0-9]+ \|' docs/cer/backlog.md          # not less than the pre-build count
git diff -- docs/cer/backlog.md | grep -c '^-|'           # expected 2 — CER-002 and CER-007 only
old=$(git show HEAD:docs/cer/backlog.md | grep '^| CER-002 ' | sed 's/ | security-auditor.*//')
new=$(grep '^| CER-002 ' docs/cer/backlog.md | sed 's/ \*\*RESOLVED.*//')
[ "$old" = "$new" ] && echo "PASS: CER-002 prose unchanged" \
  || { echo "FAIL:"; diff <(echo "$old") <(echo "$new"); }
```

Acceptance: the row count holds, exactly two rows are rewritten, and CER-002's original prose
is unchanged ahead of the appended marker. Then read the CER-002 row and confirm it still
names no forqsite path, commit hash, host or absolute path — a read, because the check is
whether an identifier was *introduced*, which a diff shows and a grep cannot judge.

The duplicate-state check for the phases 3-7 reason, and the bundle guard:

```bash
grep -rIl 'a deliberate state recorded here, not an oversight' . --exclude-dir=.git | sort
git diff --stat -- index.html gap-handoff.html
grep -c '^### ' docs/ideology.md   # 8 before the build (3 constraints + 3 reconstruction
                                   # subsections + 2 inside template comments), 9 after
```

Acceptance: the grep lists exactly `./docs/checkpoints.md` and
`./docs/stories/CONTENT/CONTENT-026.md` (this spec quotes the phrase it asserts on); the
bundle diff prints nothing; the heading count is `9`, one greater than before the build. Finally,
read the new ideology entry and the rewritten checkpoints paragraph and confirm each states
its reason rather than only its conclusion — CP-10's "every close has evidence" line is a
read, not a grep.

**Do not add a frozen-snapshot assertion against `.companion/effort.db`.** CER-009 was filed
because that pattern cannot pass on the story that introduces it: the build's and the
review's own attempt rows land inside the same stamped day. This story asserts nothing about
the effort database.

## Out of scope

- **Creating any `cp-3`..`cp-7` tag, or a checkpoint section for those phases.** This is the
  ruling itself, not an omission — see Instructions step 3.
- **CER-006, CER-008, CER-009 and CER-010.** All stay open and unmarked. CER-006 stays open
  by ruling (a referral is not a fix); CER-008 by ruling (history rewrite would invalidate
  the `cp-N` tags); CER-009 and CER-010 were filed from CONTENT-025's review and have not
  been triaged.
- **CER-001 and CER-005**, the two stale findings — CONTENT-027's subject.
- **Editing the published bundles' citations.** The ruling is to keep them exactly as they
  are; a story that "implements" a keep ruling by touching the bundles has misread it.
- **Changing `docs/phases/index.md`'s completion marks for phases 3-7.** They record that the
  phases' work was done, which is true; the tags record that a gate passed, which is what is
  absent. The two are different claims and neither is edited to match the other.
- **Editing the "Name the class, not the instance" constraint** to cross-reference the new
  one. One direction only (Instructions step 1).
