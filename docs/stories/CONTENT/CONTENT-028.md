---
id: CONTENT-028
rail: CONTENT
title: Record the procedure, the incident, and the lesson
status: complete
phase: "11"
story_class: doc
auth_gated: false
schema_introduces: false
touches:
  - docs/architecture.md
  - docs/checkpoints.md
  - docs/ideology.md
  - docs/cer/backlog.md
  - scripts/deploy.env.example
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

Phase 11 built three scripts and wrote none of them down. `docs/architecture.md` § Deployment
still describes only the container and its three bind-mounts, because INFRA-006, INFRA-007 and
INFRA-008 each deferred their doc wiring here; `docs/checkpoints.md` still describes a
checkpoint sequence that can go fully green over a stale live site, which is exactly what
`cp-8` and `cp-9` did; `docs/ideology.md` records four constraints, none of which names the
mistake that cost five days. This story makes the phase legible to someone who was not here.
It is the last story in the phase and writes no executable code: it documents what the other
three built, adds the one committed file that makes their configuration surface usable, records
the 2026-09-21 hand deploy as a dated verification record, and closes CER-014 properly.

## Requires

- INFRA-006, INFRA-007, INFRA-008 complete: `scripts/deploy.sh`, `scripts/drift-check.sh`,
  `scripts/make-provenance.sh` and their three selftests exist, each with an exit-code table in
  its header comment. Nothing in this story re-derives those contracts — it points at them.
- `docs/architecture.md` § Deployment, `docs/checkpoints.md`, `docs/ideology.md`
  § Accepted constraints and `docs/cer/backlog.md` present at `HEAD`.

## Recon (done; the builder does not repeat it)

State these as given. Two of them decide the shape of a deliverable, and re-litigating either
is how this story grows past its size.

1. **The checkpoint gate cannot be wired in this repository — verified 2026-09-22.** The
   checkpoint sequence is a fixed tuple in the build harness (`next_action.py`'s
   `_CHECKPOINT_SEQUENCE`), and `flex_build.py record-checkpoint-step` validates its `step_id`
   against it. Run with a new step id it refuses:

   ```
   record-checkpoint-step: unknown step_id 'drift-check'. Valid values: checkpoint-security,
   checkpoint-intent, checkpoint-docs, checkpoint-tag, dark-feature-scan
   ```

   There is no project-level extension point, and the one tempting substitute must not be
   taken: folding the drift check into `test_command` would run it on every story's build gate,
   where it exits 2 for missing configuration in every worktree and turns a per-story gate red
   for a reason that has nothing to do with the story. So deliverable 2 **degrades to a
   documented mandatory manual step in this repository and stops there** — the phase doc's own
   scope boundary. Do not open a harness file, and do not file a row proposing one; the referral
   is already made (CER-013, CER-016).

2. **CER-014 already reads as closed, by accident — verified 2026-09-22.** Its row ends
   "*Resolved by Phase 11's drift check (INFRA-007) plus the checkpoint-sequence line in
   CONTENT-028.*" That sentence was written at phase-planning time as a forward-looking plan,
   but `Resolved` there begins an annotation segment (sentence-ending `.` then a space), so
   `cer.is_resolution_marked` returns `True` for the row **before this story is built**. A
   finding that reads as closed because someone described the plan to close it is the same
   substitution this phase is about, one level up. The consequence for `## Tests`: the probe
   returning `True` proves nothing here, and the assertion has to be on the row's *content*.

3. **The site URL is an instance identifier — operator ruling, 2026-09-22.** INFRA-007 flagged
   the question and recommended keeping the base URL out of the tree; the operator ruled that
   way, on the ground that this repository and its product will be released as public sibling
   repos and a downstream adopter would rebrand both. `FORQSITE_HELP_SITE_URL` therefore joins
   the other two variables under `docs/ideology.md` § Name the class, not the instance. This is
   what makes deliverable 4 a *template*: three scripts exit 2 until a file nobody has been told
   how to write exists, and a check nobody can start is a check nobody runs — CP-11's own
   written-never-read line.

4. **Spec-preflight note.** The scan is expected to warn on the constant names this spec quotes
   from the three landed scripts (`FORQSITE_HELP_DEPLOY_HOST`, `FORQSITE_HELP_DEPLOY_DIR`,
   `FORQSITE_HELP_SITE_URL`, `REPLACE_ME`) and on rail prefixes (`CER`, `CONTENT`, `INFRA`).
   All are intentional: the first three are defined in `scripts/deploy.sh` and
   `scripts/drift-check.sh`, `REPLACE_ME` is defined by this story's own new file.

## Ensures

**`docs/architecture.md` § Deployment** describes all three scripts by class and by name —
`scripts/deploy.sh`, `scripts/drift-check.sh`, `scripts/make-provenance.sh` — covering: the
configuration surface (the three variable *names*, read from the environment or from a
gitignored `scripts/deploy.env`, started from the committed `scripts/deploy.env.example`); what
`deploy.sh` backs up (each live bundle to a timestamped `.bak-<stamp>` before writing, both
sharing one stamp) and that it overwrites in place because the bind mount follows the inode;
what `drift-check.sh` compares (the sha256 of the bytes an HTTP request returns against the
sha256 of `git show <ref>:<bundle>`), that this and not the file on the host is the invariant,
and that `nginx.conf` is bind-mounted but never served and so is outside it; the sidecar
(`site-provenance.json`, written at deploy time so both bundles stay byte-identical to their
committed form, read by the drift check only as a labelled claim that can add a failure and
never supply a match, and needing a one-time `volumes:` entry plus a container recreate); and
the **exit-code contract** stated as a contract — `0` means the invariant held, every failure
mode has its own code, and usage never shares a code with another condition (CER-015) — with
the per-script tables **pointed at in the script headers, not copied**. The section names no
host, no absolute deployment path and no site URL (forbidden proxy: a redacted-looking example,
a "for instance" value, or the URL smuggled in as the sidecar's fetch path).

**`docs/architecture.md` § Deployment** additionally carries a dated verification record for the
2026-09-21 hand deploy, in the project's date-and-commit stamp form, stating: the live site was
found serving `index.html` as committed at `5ec8194` and `gap-handoff.html` as committed at
`813ce27` — both Phase 7, 2026-09-16 — while the repository stood at Phase 9; both live bundles
were backed up with a shared timestamp and copied; each file's sha256 was verified on the remote
side and locally; both pages were then fetched over the reverse proxy, returning 200 with bodies
hashing equal to the repository's; and six commits touching the bundles had not reached readers,
one of them a factual correction. Every commit id in the record resolves in this repository
(forbidden proxy: a record that reads as a narrative with no re-checkable anchor).

**`docs/checkpoints.md`** gains **exactly one** non-blank line, in the checkpoint-sequence
preamble at the top of the file, requiring `scripts/drift-check.sh` to be run before
`checkpoint-tag` and its exit code and result recorded in that phase's own checkpoint section,
and stating that a drift exit blocks the tag until a deploy corrects it and the check is re-run.
The diff of that file adds no other non-blank line and removes none (forbidden proxy: the
requirement stated *and* a paragraph explaining why it is manual — that explanation belongs in
§ Deployment, and restating it here creates a second writer of one fact).

**`docs/ideology.md` § Accepted constraints** gains a fifth entry, `### Assert the invariant,
not a proxy for it`, in the same **Rule / Protects / Rationale / Override path** shape as its
four siblings, citing the 2026-09-21 stale-site incident as the instance that cost five days
and CER-009, CER-011 and CER-012 as the rows that observed the same substitution in smaller
places. The entry is no longer than the § Zero runtime dependencies entry (14 lines, heading to
blank line before the next `###`), and contains no repair instruction for any of those three
rows — it names the class; it does not fix the instances (forbidden proxy: an entry that grows
a "fix shape" clause per cited row and becomes the three findings' backlog in prose).

**`scripts/deploy.env.example`** exists, is tracked, is not ignored (`git check-ignore` reports
nothing for it), and every line in it is blank or begins with `#`. It contains exactly three
assignment lines, each matching
`^#FORQSITE_HELP_(DEPLOY_HOST|DEPLOY_DIR|SITE_URL)="REPLACE_ME[A-Z_]*"$`, each preceded by a
comment saying what that variable is for; it contains **no real value** — zero occurrences of
`://`, zero occurrences of any of the three identifiers redacted in the CER-003 row, and no
host alias, absolute path or site URL in any other form.

**`docs/cer/backlog.md`**: the CER-014 row keeps its ID, quadrant, ordering, source, date and
phase, and its trailing forward-looking sentence ("Resolved by Phase 11's drift check …
CONTENT-028.") is replaced by a past-tense resolution marker of the project's bolded
`**RESOLVED cp-11 — …**` form naming INFRA-007 as landed and this story's checkpoint-sequence
line as the second half. `cer.is_resolution_marked` returns `True` for it and `False` for
CER-005, CER-006, CER-008, CER-009, CER-010, CER-011, CER-012, CER-013, CER-015 and CER-016,
each asserted individually; no row is removed and the `| CER-NNN |` row count does not fall
(forbidden proxy: taking the probe's `True` on CER-014 as evidence of this story's edit — see
§ Recon 2, it was `True` before the build).

**Neither bundle is touched**: `git diff --stat HEAD -- index.html gap-handoff.html` is empty at
the story commit, and no `verified <date> against <product-commit>` stamp anywhere is rewritten.

## Instructions

1. **`docs/architecture.md` § Deployment.** Keep the existing container/bind-mount/proxy
   paragraphs as they stand (they were generalised for CER-003 in Phase 10 — do not re-word
   them) and append the script description after them, then the verification record last. Read
   each script's header comment for its facts rather than re-deriving them from its body.

   On the exit codes — the call the phase doc left open — **point, do not copy.** Give the
   contract at class level (what `0` asserts; one code per failure mode; usage never shares,
   CER-015) and say that each script's own header comment carries its table. The reason, worth
   one clause in the doc: a copied table is a second writer of a fact the script owns, it drifts
   the first time a code is added, and the person who needs the numbers is already reading the
   script. That is CP-11's duplicate-state line, and the doc should not fail its own checklist.

2. **The verification record.** Title it as a dated verification record inside § Deployment and
   confine it to what was observed. Derive its anchors rather than transcribing them:

   ```bash
   git show -s --format='%h %ad %s' --date=short 5ec8194 813ce27
   git log --oneline 5ec8194..HEAD -- index.html gap-handoff.html   # the commits that had not shipped
   ```

   Refer to the target by class ("the deployment host", "over the reverse proxy") — the
   § Name the class, not the instance override path permits an identifier in a verification
   record but this story does not need one, and that constraint says to prefer the class form
   when both are possible.

3. **`docs/checkpoints.md`.** One line, in the preamble that already names the sequence
   (build gate → security audit → intent review), not inside any `## cp-N` section. It must
   carry all three of: run `scripts/drift-check.sh` before `checkpoint-tag`; record the exit
   code and the result block in that phase's checkpoint section; a drift exit blocks the tag
   until a deploy corrects it and the check is re-run. Say it is a manual step and point at
   `docs/architecture.md` § Deployment for why, in the same line. Add nothing else.

4. **`docs/ideology.md`.** New `###` entry after § Cite the source that makes a claim checkable,
   same four-field shape. Suggested substance, to be written in the builder's own words and kept
   inside the length cap: **Rule** — a check asserts the invariant it claims, not something
   correlated with it that is cheaper to compute; where the two differ, the check is wrong even
   when it is green. **Protects** — the meaning of a green gate. **Rationale** — on 2026-09-21
   the live site was found five days and two phases stale after `cp-8` and `cp-9` had both gone
   green, because every gate compared the repository to itself and stopped at the repository's
   edge; CER-009, CER-011 and CER-012 record the same substitution on smaller surfaces.
   **Override path** — a proxy may stand in only where the invariant is genuinely unobservable,
   and then the check must say so in its own output (as `drift-check.sh` does for `nginx.conf`).
   Cite the three rows by ID and stop; their repairs are not this entry's business.

5. **`scripts/deploy.env.example`.** A header comment saying what the file is (a template; copy
   to `scripts/deploy.env`, which is gitignored; uncomment and fill in), then one explanatory
   comment plus one commented assignment per variable: `FORQSITE_HELP_DEPLOY_HOST` (the ssh
   alias the deploy reaches the host through — an alias, so no host name is needed anywhere),
   `FORQSITE_HELP_DEPLOY_DIR` (the per-site directory on the far side that the bundles and the
   sidecar are written into), `FORQSITE_HELP_SITE_URL` (the base URL the drift check fetches
   the served bytes from, no trailing slash). Every assignment stays commented out and carries a
   `"REPLACE_ME…"` placeholder: commented, so a copied-but-unedited file leaves the scripts on
   their existing exit-2 path instead of sending a placeholder to `ssh`; quoted and
   alphabetic-only, so the file is shell-safe and no value can be mistaken for a real one. Do
   **not** add a `.gitignore` entry — `scripts/deploy.env` is already ignored by exact path and
   the example must stay tracked. Do **not** edit the three scripts to mention the file;
   § Deployment is its documented reader, and widening this story into INFRA-006/007's files is
   out of scope.

6. **`docs/cer/backlog.md`.** Rewrite only the CER-014 row's trailing sentence. Keep every other
   character of the row, including its Source/Date/Phase cells. Touch no other row — in
   particular, the ten rows asserted `False` in `## Tests` are not this story's to close, and
   CER-015's exit-code overload in `deploy.sh` is its own row (INFRA-007 deliberately did not
   repeat the mistake and deliberately did not fix it).

*(Proportionality note: `story_class: doc`, but five touched files across four documents plus one
new committed file, two of which carried decisions the phase doc left to this story to make and
justify. The length is spent on the four deliverables' boundaries — each is explicitly sized in
the phase doc and each has an obvious way to grow past that size.)*

## Tests

No test suite (`test_command` is `true`, static HTML). These are the story's verification
commands, run from the repo root. Paste the output of each into the build note.

**The marker probe** (derives the harness scripts directory from a file already in the tree, so
neither builder nor reviewer types a home path — the CONTENT-027 form):

```bash
FS=$(grep -oE '[^ "`]*skills/pairmode/scripts' CLAUDE.build.md | head -1); FS="${FS/#\~/$HOME}"
PATH=$HOME/.local/bin:$PATH uv run --project "${FS%/skills/pairmode/scripts}" python - "$FS" <<'PY'
import sys, pathlib, re; sys.path.insert(0, sys.argv[1])
import cer
rows = {l.split('|')[1].strip(): l for l in
        pathlib.Path('docs/cer/backlog.md').read_text().splitlines() if l.startswith('| CER-')}
for rid in ('CER-014','CER-005','CER-006','CER-008','CER-009','CER-010','CER-011','CER-012',
            'CER-013','CER-015','CER-016'):
    print(rid, cer.is_resolution_marked(rows[rid]))
norm = " ".join(rows['CER-014'].split())          # whitespace-normalised, never a line grep (CER-011)
print("marker form:", bool(re.search(r"\*\*RESOLVED cp-11 ", norm)))
print("plan sentence gone:", "Resolved by Phase 11's drift check" not in norm)
print("names both halves:", "INFRA-007" in norm and "CONTENT-028" in norm)
PY
```

Acceptance: `CER-014 True` and `False` for all ten others, **and** all three of the trailing
lines `True`. The `CER-014 True` line alone is not evidence — it was `True` before the build
(§ Recon 2); the three content lines are what this story is asserted on.

**Backlog integrity:**

```bash
grep -cE '^\| CER-[0-9]+ \|' docs/cer/backlog.md            # not less than the pre-build count
git diff -- docs/cer/backlog.md | grep -c '^-|'             # expected 1 — CER-014 only
```

**The example file:**

```bash
git check-ignore -v scripts/deploy.env.example ; echo "ignored=$?"   # expect ignored=1 (not ignored)
grep -cve '^[[:space:]]*$' -e '^#' scripts/deploy.env.example        # expect 0 — every line blank or comment
grep -cE '^#FORQSITE_HELP_(DEPLOY_HOST|DEPLOY_DIR|SITE_URL)="REPLACE_ME[A-Z_]*"$' scripts/deploy.env.example
grep -c '://' scripts/deploy.env.example                             # expect 0
```

Acceptance: `ignored=1`, `0`, `3`, `0`.

**The no-identifier hygiene check**, deriving its search terms from history so neither builder
nor reviewer types an identifier (the CONTENT-024 form, as reused by INFRA-006 and INFRA-007):

```bash
mapfile -t IDS < <(git show 8bb837b:docs/cer/backlog.md \
  | grep '^| CER-003 ' | grep -o '`[^`]*`' | tr -d '`')
[ "${#IDS[@]}" -eq 3 ] || { echo "FAIL: expected 3 identifiers, got ${#IDS[@]}"; exit 1; }
args=(); for i in "${IDS[@]}"; do args+=(-e "$i"); done
hits=$(grep -Il "${args[@]}" scripts/deploy.env.example docs/architecture.md \
  docs/checkpoints.md docs/ideology.md docs/stories/CONTENT/CONTENT-028.md || true)
[ -z "$hits" ] && echo "PASS: no identifier in this story's files" || { echo "FAIL:"; echo "$hits"; }
```

Acceptance: `PASS`. Also confirm by reading that none of the five files carries a host alias, an
absolute deployment path or a site URL in any *other* form — the grep only catches three known
strings.

**Sizing and bundles:**

```bash
awk '/^### Assert the invariant/,/^### /' docs/ideology.md | head -n -1 | wc -l   # <= 14
git diff --numstat -- docs/checkpoints.md                                          # 1 added, 0 removed
git diff --stat HEAD -- index.html gap-handoff.html                                # empty
```

**The commit anchors** in the verification record resolve:

```bash
git show -s --format='%h %ad %s' --date=short 5ec8194 813ce27
git log --oneline 5ec8194..HEAD -- index.html gap-handoff.html | wc -l
```

Acceptance: both commits resolve to 2026-09-16 Phase 7 subjects, and the count matches the
number of unshipped content commits the record states.

## Out of scope

- **Wiring the drift check into the harness checkpoint sequence**, opening any file under the
  flex cache, or filing a row asking for a project-level checkpoint-step extension point. The
  gate degrades to a documented manual step and stops at this repository's edge (phase doc; and
  the build harness is not this project's subject, CONTENT-025).
- **Resolving CER-005, CER-006, CER-008, CER-009, CER-010, CER-011, CER-012, CER-013, CER-015 or
  CER-016.** CER-009/011/012 are cited by the new ideology entry as instances of the class; being
  cited is not being repaired, and the entry's length cap exists to keep that boundary.
- **Changing any of the three scripts or their selftests**, including adding a pointer to
  `deploy.env.example` in their missing-configuration messages, and including fixing CER-015's
  exit-code overload in `deploy.sh`.
- **Running a deploy or a drift check against the live site.** Neither is part of this story's
  acceptance; when the operator runs them, the blocks they print are the artifacts.
- **Any change to the published bundles**, and CER-005's render gap — a sibling content phase.
- **A rollback procedure.** `deploy.sh`'s timestamped backups make one possible and § Deployment
  may say so, but no restore path is designed or documented here (INFRA-006 § Out of scope).
