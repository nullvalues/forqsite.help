# forqsite.help — Pairmode Wiring Audit

**Date:** 2026-09-21
**Scope:** this repo's pairmode configuration (`.gitignore`, `.companion/pairmode_context.json`,
`CLAUDE.build.md`, `.claude/agents/`, `docs/phases/index.md`, `docs/` structure) compared
against current flex convention, flex-0.4.7 (`~/flex-marketplace-cache/flex-0.4.7`):
`bootstrap.py`'s `SCAFFOLD_FILES`/`AGENT_FILES`/`EXEMPLAR_FILES`/`NARRATIVE_FILES`
destination lists, `audit.py`'s `CANONICAL_FILES` list, and `skills/pairmode/templates/`.
Written by CONTENT-020 (phase 9). This is a standalone record — link it from nothing
else; `docs/architecture.md` is CONTENT-022's file.

Every divergence below carries a disposition (`already fixed inline` / `fixed by this
story` / `kept, with reason` / `reported to operator`) and a reason. Nothing under
`~/flex-marketplace-cache/` was modified in the course of this audit —
`git -C ~/flex-marketplace-cache/flex-0.4.7 status --porcelain` is byte-identical
before and after this story.

---

## 1. `.gitignore` reconciliation

**Divergence:** `.companion/` telemetry (`effort.db`, `state.json`, `pairmode_context.json`)
was tracked in git, so every build-loop run dirtied the main checkout, and
`.pairmode-worktrees/` plus the shadow-reviewer marker files
(`.pairmode-suggestions.md`, `.pairmode-review.lck`, `.pairmode-review-request`) were
not ignored either — `merge-story-worktree`'s CER-288 guard refused every story merge
as a result.

**Disposition:** already fixed inline.

**Reason:** fixed during the Phase 8 build, commit `87a8ef7` ("chore: untrack
.companion/ telemetry and ignore pairmode runtime paths"), under an explicit operator
ruling. Verified present on `main`: `.gitignore` carries `.companion/`,
`.pairmode-worktrees/`, `.pairmode-suggestions.md`, `.pairmode-review.lck`, and
`.pairmode-review-request`. This story does not redo that commit.

---

## 2. `test_command` prose-vs-shell-command

**Divergence:** `test_command` held a prose description
(`none - static HTML, open file:// or serve with any static file server`) in a field
`next_action.py`'s `_run_build_gate_subprocess` executes as a shell command.

**Disposition:** already fixed inline.

**Reason:** `test_command` is `true` in both `.companion/pairmode_context.json` (main
checkout, verified: `"test_command": "true"`) and `CLAUDE.build.md`'s Build standards
line (verified: `` test_command=`true` — this project has no test suite... ``), fixed
inline after commit `945d379` under the same Phase 8 operator ruling. This story does
not redo it.

**Consequence — the load-bearing fact this audit exists to record:** `git tag -l
'cp-*'` returns nothing. **No phase 1-7 was ever tagged.** For this project's entire
build history through Phase 7, the prose `test_command` value was shelled out by
`_run_build_gate_subprocess`, produced `command not found` (exit 127), and the build
gate failed red on every checkpoint attempt — silently, because nothing in the loop
surfaced the shell error as anything other than "gate did not pass." The gitignore fix
(item 1) and this fix were applied together under the same ruling once the pattern was
recognized; only after both landed did `cp-*` tagging become possible again, starting
with whichever phase closes first under CP-8/CP-9.

---

## 3. `.claude/agents/gate-worker.md` — orphaned agent shell

**Divergence:** `.claude/agents/gate-worker.md` remained in this repo for the
`spawn-gate-worker` dispatch capability. Flex retired that dispatch in INFRA-422 (Phase
148) — `next_action.py`'s Row 4b now resolves a tripped schema/auth judged gate
fail-closed, the same way the stub gate's Row 4a already does, without ever emitting
`spawn-gate-worker` — and INFRA-448 removed the role's skill/procedure files from flex
itself. `bootstrap.py`'s `AGENT_FILES`/`CANONICAL_FILES` lists confirm `gate-worker.md.j2`
is gone from the template set (see the removal comment at `bootstrap.py` line ~120).
Nothing in this repo dispatches it — the only remaining mentions were
`CLAUDE.build.md`'s own historical note (which correctly *describes* the removal, so it
was left as-is) and this phase's doc. `dark_feature_scan.py --project-dir .` reported
this as its one finding: `narrative: GATE-WORKER — .claude/agents/gate-worker.md has no
docs/narratives/GATE-WORKER/ directory`.

**Disposition:** fixed by this story.

**Reason:** deleted `.claude/agents/gate-worker.md`. It is a dark feature — a shell with
no dispatch path to ever reach it. `dark_feature_scan.py --project-dir .` now reports
`0 finding(s)` (down from 1). Recorded here so it is not resurrected by a future sync
or a copy-paste from an older project.

---

## 4. `docs/phases/index.md` § Backlog promotions — dangling Do-Later/Do-Much-Later reference

**Divergence:** the § Backlog promotions section's parenthetical
(`List items promoted from the Do-Later / Do-Much-Later backlog into active phases
here...`) is verbatim flex template boilerplate
(`skills/pairmode/templates/docs/phases/index.md.j2`) — **not a forqsite-authored
claim.** Read literally it implies separate Do-Later/Do-Much-Later phase docs, which do
not exist on disk in this project (`docs/phases/` has no such files). This project
instead already implements the Do Now / Do Later / Do Much Later / Do Never structure
as **quadrant sections inside a single file**, `docs/cer/backlog.md` — present, in use,
and populated (CER-001 sits in its Do Later quadrant) since Phase 2. The boilerplate
text was never updated to name that file when this project adopted the single-doc
quadrant convention instead of flex's assumed per-quadrant-phase-doc convention.

**Disposition:** fixed by this story (the forqsite-side reference) / reported to
operator (the flex-side boilerplate).

**Reason:** reworded the § Backlog promotions parenthetical to link
`docs/cer/backlog.md` directly rather than describing backlog docs that were never
going to exist under this project's actual (single-file, quadrant) convention. This is
an edit to `docs/phases/index.md`, a forqsite-owned file already in this story's
`touches:` list — not a flex-side patch. The upstream template text itself
(`index.md.j2`) is out of scope for this story per Instructions step 3: that is a
flex-side observation, reported here, never patched.

---

## 5. `docs/phases/index.md` § Proposed phases — dangling link to a nonexistent proposal file

**Divergence (sweep lead, confirmed):** the § Proposed phases table linked
`phase-proposed-pairmode-030-migration-20260722-001.md` ("Migrate to pairmode 0.3.0"),
which is not on disk (`find docs/phases -iname '*proposed*'` returns nothing). The
proposal itself is also moot: this project is already on flex 0.4.7, several versions
past the 0.3.0 migration the proposal was scoped to.

**Disposition:** fixed by this story.

**Reason:** replaced the stale row with an explicit `(none)` placeholder. `index.md` is
already in this story's `touches:` list; the fix is a same-file cleanup alongside item 4,
not new scope. If the proposal had residual value it would have been sequenced into a
phase already (this project is on Phase 9); leaving a dead link around for the next
person to click and find nothing serves no one.

---

## 6. `dark_feature_scan.py` invocation in `CLAUDE.build.md` fails outside flex's own venv

**Divergence (sweep lead, confirmed):** `CLAUDE.build.md`'s documented Checkpoint
section invocation —
`PATH=$HOME/.local/bin:$PATH uv run python ~/flex-marketplace-cache/flex-0.4.7/skills/pairmode/scripts/dark_feature_scan.py --project-dir .`
— fails with `ModuleNotFoundError: No module named 'click'` when run from this project
(confirmed by direct reproduction). Adding `--with click` to the `uv run` invocation
(`uv run --with click python ...`) succeeds and produces the expected finding count.
The same is true of `audit.py`, which additionally needs `--with jinja2`.

**Disposition:** kept, with reason (not fixed).

**Reason:** per Instructions step 4, editing `CLAUDE.build.md` to fix its own
invocation line is explicitly not required by this story, and is left as-is. The
`dark_feature_scan.py` dependency on `click` (and `audit.py`'s on `jinja2`) not being
declared for standalone invocation outside flex's own venv is a flex-side packaging gap
— the scripts assume flex's own project environment provides these — not a forqsite
misconfiguration, so it is also not something this project can fix at its own root.
Reported to operator for a future flex-side fix (a `--with click` / `--with jinja2`
default in the documented invocation line, or a `requirements.txt`/inline
`# /// script` dependency block on the scripts themselves).

---

## 7. `.claude/agents/` — remaining nine shells match flex 0.4.7's `AGENT_FILES`

**Divergence:** none found.

**Disposition:** kept, with reason (verification only — no change needed).

**Reason:** after removing `gate-worker.md` (item 3), the remaining contents of
`.claude/agents/` — `builder.md`, `docs-reviewer.md`, `intent-reviewer.md`,
`loop-breaker.md`, `reconstruction-agent.md`, `reviewer.md`, `security-auditor.md`,
`shadow-reviewer.md`, `spec-writer.md` — are exactly the nine entries
`bootstrap.py`'s `AGENT_FILES` list scaffolds for flex 0.4.7. Confirmed by direct
comparison against `bootstrap.py`.

---

## 8. `SCAFFOLD_FILES` / `EXEMPLAR_FILES` destinations all present

**Divergence:** none found.

**Disposition:** kept, with reason (verification only — no change needed).

**Reason:** `CLAUDE.md`, `CLAUDE.build.md`, `.pairmode-overrides`, `docs/brief.md`,
`docs/ideology.md`, `docs/reconstruction.md`, `docs/architecture.md`,
`docs/checkpoints.md`, and `docs/cer/backlog.md` (flex 0.4.7's `SCAFFOLD_FILES`
destinations) all exist. `docs/exemplars/EXEMPLAR-000.md` (`EXEMPLAR_FILES`) exists.

---

## 9. `audit.py` run against this project — WARN-level extensions only

**Divergence:** running
`uv run --with click --with jinja2 python ~/flex-marketplace-cache/flex-0.4.7/skills/pairmode/scripts/audit.py --project-dir .`
(the venv workaround from item 6) reports no MISSING/ERROR findings, and four WARN
findings: `CLAUDE.md` § "session modes", `.claude/agents/builder.md` §
"return__8", `.claude/agents/reviewer.md` § "return__9", and
`.claude/agents/security-auditor.md` § "audit scope" — each labelled "stale-canon
candidate or deliberate extension — confirm or override."

**Disposition:** kept, with reason.

**Reason:** these four sections are deliberate project-specific extensions of
harness-owned canonical files (CLAUDE.md's Session modes block governing this
project's build/review-mode split; the agent shells' project-specific procedure
pointers), not accidental drift — expected and correct given these files are
"project-owned after first bootstrap" per `bootstrap.py`'s own AGENT_FILES comment.
No action needed; recorded so a future sync run's WARN output is not mistaken for a
new finding.

Note: `audit.py`'s INCONSISTENT template-body comparison could not run in the audit
worktree — it reported `No pairmode_context.json found` because `.companion/` is
gitignored and per-story worktrees do not carry over untracked files from the main
checkout. The main checkout's `.companion/pairmode_context.json` does exist and was
read directly for item 2's verification instead.

---

## 10. `docs/narratives/OPERATOR/` seed directory absent

**Divergence (sweep finding, not one of the four named leads):** flex 0.4.7's
`bootstrap.py` scaffolds an `OPERATOR-000-ideology.md` seed narrative
(`OPERATOR_SEED_FILE`) into `docs/narratives/OPERATOR/` on every fresh bootstrap, "like
the other ten" harness-role narratives, meant to be extended per-project via a
numbered `OPERATOR-010`-and-onward file. This repo's `docs/narratives/` has all ten
harness-role directories (`BUILDER`, `REVIEWER`, `LOOP-BREAKER`, `SECURITY-AUDITOR`,
`INTENT-REVIEWER`, `DOCS-REVIEWER`, `SPEC-WRITER`, `ORCHESTRATOR`, `SHADOW-REVIEWER`,
`RECONSTRUCTION-AGENT`) but no `OPERATOR/` directory at all.

**Disposition:** reported to operator.

**Reason:** `OPERATOR_SEED_FILE` is deliberately excluded from `bootstrap.py`'s shared
`NARRATIVE_FILES` list and from `audit.py`'s `CANONICAL_FILES`/`SCAFFOLD_FILES`
comparisons, so neither `dark_feature_scan.py` nor `audit.py` flags its absence — this
was found by direct comparison against `bootstrap.py`'s source, not by either scan
tool. Creating it requires the operator's free-text prompt answer that seeds the
extension file (per `bootstrap.py`'s own comment, "the operator's free-text prompt
answer" is what the extension file's content comes from) and touches a file outside
this story's declared `touches:` list (`docs/phases/index.md`,
`.claude/agents/gate-worker.md`). Recorded here rather than created unilaterally with
placeholder content.

---

## Summary

| # | Divergence | Disposition |
|---|---|---|
| 1 | `.gitignore` pairmode-runtime reconciliation | already fixed inline (`87a8ef7`) |
| 2 | `test_command` prose-vs-shell-command | already fixed inline (post-`945d379`) |
| 3 | `.claude/agents/gate-worker.md` orphaned shell | fixed by this story |
| 4 | `docs/phases/index.md` Do-Later/Do-Much-Later backlog reference | fixed by this story / reported to operator (template origin) |
| 5 | `docs/phases/index.md` dangling proposed-phase link | fixed by this story |
| 6 | `dark_feature_scan.py`/`audit.py` venv dependency gap | kept, with reason |
| 7 | `.claude/agents/` shell set vs flex `AGENT_FILES` | verified, no divergence |
| 8 | `SCAFFOLD_FILES`/`EXEMPLAR_FILES` destinations | verified, no divergence |
| 9 | `audit.py` WARN-level project extensions | kept, with reason |
| 10 | `docs/narratives/OPERATOR/` seed absent | reported to operator |

`git -C ~/flex-marketplace-cache/flex-0.4.7 status --porcelain` was checked before and
after this audit and is unchanged (empty both times) — nothing under
`~/flex-marketplace-cache/` was modified.
