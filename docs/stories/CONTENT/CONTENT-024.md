---
id: CONTENT-024
rail: CONTENT
title: Record name-the-class-not-the-instance as an accepted constraint, and generalise our infrastructure identifiers out of all four files
status: complete
phase: "10"
story_class: doc
auth_gated: false
schema_introduces: false
touches:
  - docs/ideology.md
  - docs/architecture.md
  - docs/phases/phase-4.md
  - docs/stories/INFRA/INFRA-002.md
  - docs/cer/backlog.md
narrative_roles: []
---

> **Relocation note (CONTENT-025, 2026-09-21).** `docs/pairmode-wiring-audit.md`,
> referenced below, was removed from this repository in Phase 10: its subject is the
> build harness, not administering forqsite. Its harness findings were written up
> operator-local and untracked; the one repo-local outcome (the `gate-worker.md`
> removal) is recorded in `docs/architecture.md`, and the phases 3-7 gate history in
> `docs/checkpoints.md`. This document is left as the Phase 9 record of what was
> specified and done — its body is unchanged and is not rewritten to match the current
> tree.

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

Phase 10 establishes that this project documents an approach by its class — the
constraint, the topology, the reason — not by our particular deployment of it. The
published bundles already follow that rule; the repository does not. Our Docker host name
and our two deployment directories sit in the live architecture doc, in two historical
docs, and in the backlog row that reports the leak. A public repository leaks the same
string whichever file carries it. This story writes the principle down as an accepted
constraint so it survives, and generalises the identifiers out of all four — keeping, in
every case, the operational reason that made the arrangement what it is.

**This spec names no identifier literally.** The principle applies to the scaffolding as
much as to the target: a spec that quotes the string it exists to remove is a fifth file
carrying it, and its own acceptance test could never pass. Everywhere the strings would
otherwise appear, this spec points at them instead (see Recon).

## Requires

- CONTENT-023 complete (`docs/cer/backlog.md` carries the resolution-marker convention).
  This story is that convention's first live use.
- A new row `CER-008` (git history still carries the redacted strings) is appended to
  `docs/cer/backlog.md` on `main` before this story's worktree is created. Expect it to be
  present. It is not this story's subject and must not be resolved by it.

## Recon (done; the builder does not repeat it)

**The three identifiers.** They are one host name and two absolute deployment directories:
exactly the three backtick-quoted strings in the CER-003 row of the backlog as of commit
`8bb837b`. Retrieve them with:

```bash
git show 8bb837b:docs/cer/backlog.md | grep '^| CER-003 ' | grep -o '`[^`]*`' | tr -d '`'
```

That prints three lines and nothing else (verified 2026-09-21). Every grep, edit and
assertion below is expressed against those three values, never against a literal.

**The count is four, as the phase doc says.** `git grep` for the three, over the tracked
tree at `8bb837b`:

| File | Lines | What the passage says |
|---|---|---|
| `docs/architecture.md` | 73-74 | The Deployment section names the host the site runs on and the directory it is deployed into, alongside the edge proxy's own equivalent directory, then gives the single-host DNS reason. |
| `docs/phases/phase-4.md` | 55-57, 59, 74, 89-92, 95 | Acceptance criteria, the shared-production-host risk note, the build record, and four verification lines that say where a `curl`/`docker ps` was run from. |
| `docs/stories/INFRA/INFRA-002.md` | 22, 53-54, 61-63 | A Requires line about the proxy stack already running, the rsync/deploy Instructions, and three Tests lines naming where each command ran. |
| `docs/cer/backlog.md` | 37 | The CER-003 row, which quotes all three as the finding's own subject. |

Two exclusions, both checked rather than assumed:

- `README.md:32` — a `root *` line inside an illustrative Caddyfile block under
  "## Hosting". It is not our deployment directory: ours spells the site name with a
  hyphen, the README's with a dot, and the surrounding prose offers GitHub Pages and
  `python3 -m http.server` as equal alternatives. It describes the reader's own server, and
  it does not match any of the three retrieved strings. Leave it.
- `forqsite.help`, the container name and port, the sibling proxy repo's site-config
  filename, and the `edge` network name are the service's public identity and a public
  convention, not our machine. Leave them.

**The published bundles are clean.** `index.html` and `gap-handoff.html` were grepped on
2026-09-21 at `8bb837b` for each of the three, plus the broader patterns `/srv[A-Za-z0-9._/-]*`
and the host's two-letter site prefix: zero matches in both files. Nothing in this story
touches them.

**Spec-preflight note.** The scan warns on three "constants" — `CER`, `INFRA` and
`RESOLVED`. All three are intentional: the first two are story-rail prefixes, and
`RESOLVED` is a marker keyword defined in the build harness (`cer.RESOLUTION_MARKERS`),
not in this repo's source tree.

## Ruling (operator, 2026-09-21)

The spec first stopped at three files, holding that the phase's "every row present at the
end, with its original text" rule made the CER-003 row immutable. The operator ruled
otherwise: **redact inside the row.** The reviewer checks against this reasoning rather
than re-litigating it.

- The hygiene goal is binary. With the row untouched, a tree-wide grep on the public repo
  still returns a hit — three files out of four is the same leak with more steps.
- The "quote it as evidence" argument fails. A reader verifies the fix from the diff, the
  commit and the resolution marker — never from a finding text that still carries the
  string.
- The no-deletion rule's stated purpose is that findings do not *vanish* and the table does
  not shorten. Preserving the row's ID, quadrant, ordering, source, date, severity and
  meaning satisfies that purpose.
- Reading "original text" as byte-immutability would make the phase permanently unable to
  apply its own principle to its own backlog.
- Decisively: CP-10's "class not instance" checklist line asks whether any file this phase
  touched names a host or an absolute path. `docs/cer/backlog.md` IS touched this phase, so
  leaving the row would fail that line at the gate.

The same ruling was then applied to this spec (see Context), which is why it arrives with
no literal to scrub.

## Ensures

After this story, the tree-wide search in `## Tests` — which derives its own search terms
from commit `8bb837b` rather than naming them — reports zero hits anywhere in the working
tree outside `.git` (forbidden proxy: three files edited while the string survives in a
fourth, or in this spec); `docs/ideology.md` § Accepted constraints carries a third entry,
"Name the class, not the instance", in the same Rule/Protects/Rationale/Override path shape
as its two siblings and giving both arguments (public-repo hygiene, and that naming the
instance is worse documentation); `cer.is_resolution_marked` returns `True` for the
rewritten CER-003 row; that row keeps its ID, quadrant (Do Later), ordering, source, date
and phase unchanged and its finding still reads as the same finding; the backlog's
`| CER-NNN |` row count after the build is not less than before it and no row is removed
(CER-008 in particular stays open and unmarked); and each of the four edited passages still
states the operational reason — same Docker host as the edge proxy, per-site directory,
because that network's embedded DNS resolves only within a single host.

## Instructions

1. Retrieve the three identifiers with the Recon command above. Keep them in the shell, not
   in any file you write.
2. Add the accepted constraint to `docs/ideology.md`, after "Generated-artifact discipline",
   matching the existing four-field format exactly. Override path: state that a specific
   identifier may appear only where it is the subject of a finding or a verification record,
   and never in a live description of the architecture — and that this story's own ruling
   narrowed even that, since a finding can name its subject by class, and so can the spec
   that fixes it.
3. In each of `docs/architecture.md`, `docs/phases/phase-4.md` and
   `docs/stories/INFRA/INFRA-002.md`, replace the host name with the class ("the Docker host
   that runs the edge proxy", or a phrasing that fits the sentence) and each of the two
   directories with the class ("a per-site directory under that host's service root", "the
   proxy's own deploy convention"). Where a line says a command was run *on* or *from* the
   host, the class is "from the deployment host".
4. Do not rewrite the historical docs beyond the identifiers. Phase 4's build record and
   INFRA-002's Tests stay historical records of what was done; only the identifier changes.
5. Replace the CER-003 row in `docs/cer/backlog.md` with exactly this, adjusted only if the
   surrounding table formatting requires it. It names files, never identifiers — a marker
   records what landed, not the instance:

   ```
   | CER-003 | docs/architecture.md's Deployment section names the internal host and its deployment paths in a public repo. Pre-existing since the Phase 4 containerization commit, outside Phase 9's diff. Same public-hygiene class as CER-002. **RESOLVED cp-10 — generalised in docs/architecture.md, docs/phases/phase-4.md and docs/stories/INFRA/INFRA-002.md; the identifiers were redacted from this row too, under the same principle** | security-auditor (Phase 9 checkpoint) | 2026-09-21 | 9 |
   ```

   Change nothing else in the file: no other row's text, no ordering, no quadrant move, and
   nothing at all to CER-008.
6. Leave `README.md`, `index.html`, `gap-handoff.html` and this spec untouched (see Recon).
   This spec is already free of the identifiers; do not add them to it in any form,
   including in a build note.

## Tests

The working-tree assertion. It reads its own search terms out of history, so neither the
builder nor the reviewer types an identifier (verified to run, 2026-09-21):

```bash
cd /mnt/work/forqsite.help
mapfile -t IDS < <(git show 8bb837b:docs/cer/backlog.md \
  | grep '^| CER-003 ' | grep -o '`[^`]*`' | tr -d '`')
[ "${#IDS[@]}" -eq 3 ] || { echo "FAIL: expected 3 identifiers, got ${#IDS[@]}"; exit 1; }
args=(); for i in "${IDS[@]}"; do args+=(-e "$i"); done
hits=$(grep -rIl "${args[@]}" . --exclude-dir=.git || true)
[ -z "$hits" ] && echo "PASS: zero hits in the working tree" || { echo "FAIL:"; echo "$hits"; }
```

Acceptance: `PASS`. The assertion is about the **working tree only**. Git history still
carries the strings, and this story's own commit diff necessarily contains them on the
removed side — both are expected, neither is a failure, and the history residue is filed as
CER-008 (see Out of scope).

The marker probe — the resolution convention's first live use, verified by the spec-writer
against the real function on 2026-09-21 and returning `True` for the row text in
Instructions step 5:

```bash
PATH=$HOME/.local/bin:$PATH uv run --project ~/flex-marketplace-cache/flex-0.4.7 \
  python -c "
import sys; sys.path.insert(0, '$HOME/flex-marketplace-cache/flex-0.4.7/skills/pairmode/scripts')
import cer, pathlib
row = [l for l in pathlib.Path('docs/cer/backlog.md').read_text().splitlines() if l.startswith('| CER-003 ')][0]
print(cer.is_resolution_marked(row))
"
```

The remaining checks:

```bash
git diff --stat -- index.html gap-handoff.html README.md docs/stories/CONTENT/CONTENT-024.md
grep -c 'Name the class, not the instance' docs/ideology.md
grep -cE '^\| CER-[0-9]+ \|' docs/cer/backlog.md   # compare against the pre-build count
```

Acceptance: the marker probe prints `True`; the diff prints nothing; the ideology grep
prints at least `1`; the row count is not less than the pre-build count. Then read the four
edited passages and confirm the single-host DNS reason is still stated in each — that one is
a read, not a grep, because it is the part a grep cannot check.

## Out of scope

- **Git history.** Every commit before this one still carries the three strings, and a
  pickaxe search will find them. Rewriting history would invalidate the `cp-N` tags, so this
  story does not attempt it. The residue is filed as its own backlog row, CER-008, which
  this story must not resolve.
- Resolving or marking any backlog row other than CER-003 — CER-004 and CER-008 in
  particular. Those closures belong to CONTENT-025, CONTENT-027 and the operator's rulings.
- The published bundles. They are already clean (Recon), and the phase forbids touching them
  here.
- `docs/pairmode-wiring-audit.md`'s flex-cache paths — the same hygiene class, but
  CONTENT-025's subject, not this story's.
- Any change to the actual deployment. This story edits documentation only; the container,
  network and directory layout stay exactly as they are.
