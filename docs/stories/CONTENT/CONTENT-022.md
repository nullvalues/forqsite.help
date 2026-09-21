---
id: CONTENT-022
rail: CONTENT
title: Bring architecture.md and the era ledger current with how this project is actually built
status: draft
phase: "9"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - docs/architecture.md
touches:
  - docs/eras/001-initial.md
narrative_roles: []
---

## Context

Phase 8's checkpoint-docs gate returned FAIL and blocked CP-8 with five findings, all
of them the same defect in two forms: the cold-start documents describe a project that
no longer exists. `docs/architecture.md`'s Editing procedure still prescribes a manual
`JSON.stringify` splice, but all four Phase 8 stories (`8466711`, `7c8d14a`, `915de21`,
`fee0091`) edited the bundles exclusively through `scripts/bundle-template.py`, which
the module tree does not mention at all; the doc names no era and no phase later than
4; and `docs/eras/001-initial.md`'s phase ledger still shows four phases, all
`planned`, while `docs/phases/index.md` records seven complete. This story corrects the
documents to match the repository. The gate is re-run against phase 8 after it merges,
so each Ensures assertion below maps onto one gate finding.

## Requires

- `scripts/bundle-template.py` exists and is the tool Phase 8 used — read it before
  writing the Editing procedure; describe its real interface, not the story prompts'
  paraphrase of it.
- `docs/phases/index.md` is the source of truth for phase status. It is read, never
  written, by this story.

## Ensures

`docs/architecture.md` documents the `scripts/bundle-template.py extract|inject|verify`
path (with the round-trip and headless-render verification requirements preserved),
lists `scripts/` in its Module structure tree, and names both era `001`
(`docs/eras/001-initial.md`) and Phase 7 as the most recently complete phase; and
`docs/eras/001-initial.md`'s Phases table lists phases 1-9 with statuses byte-identical
in meaning to `docs/phases/index.md` — 1-7 `complete`, 8 and 9 `planned` — with
`docs/phases/index.md` itself unchanged by this story.

## Instructions

1. **Editing procedure** (`docs/architecture.md:60-67`). Rewrite it around
   `scripts/bundle-template.py`, keeping everything in the current text that is still
   true. Concretely:
   - Name the three subcommands as the script itself defines them:
     `bundle-template.py extract <bundle.html> <out.template.html>`,
     `bundle-template.py inject <bundle.html> <in.template.html>`,
     `bundle-template.py verify <bundle.html>`. Invoked as `python3 scripts/bundle-template.py …`.
   - State the workflow Phase 8 actually used: `verify` before editing (confirms the
     script's encoder still matches the bundler's), `extract` once to a scratch file,
     make every edit in the unpacked template, `inject` once, `verify` again.
   - State why hand-splicing is now wrong rather than merely discouraged: the encoder
     escapes every `/` as `/`, and the template contains its own `</script>`
     sequences that would terminate the carrying script element if left unescaped.
   - **Keep** the surviving requirements: `node --check` on any edited script, a JSON
     round-trip check on the re-encoded payload (now performed by `verify`), and a
     headless-browser render (e.g. Chromium `--dump-dom`) for any interactive/CSS
     change, because a text diff cannot confirm runtime behaviour like scroll reset or
     hash routing.
   - The `docs/stories/CONTENT/CONTENT-001.md` pointer may stay only if relabelled as
     the historical pre-script example; it must not read as current guidance.
2. **Module structure** (`docs/architecture.md:34-41`). Add a `scripts/` entry with
   `bundle-template.py` beneath it, commented as the canonical bundle-edit tool.
3. **Era and phase currency.** Add a short section (before `## Module structure` is
   fine) naming the active era as `001` with a link to `docs/eras/001-initial.md`, and
   the most recently complete phase as Phase 7 (`Write for the reader, not about the
   work`) per `docs/phases/index.md`, stating explicitly that `docs/phases/index.md` is
   the source of truth for phase status and this line is a pointer, not a second
   record. Leave the existing `phase 4` / `Phase 2` mentions in Deployment and
   Protected files alone — they are historical attributions, not currency claims.
4. **Era ledger** (`docs/eras/001-initial.md` Phases table). Replace the four-row table
   with rows for phases 1-9, titles and statuses copied from `docs/phases/index.md`:
   phases 1-7 `complete`; phase 8 `planned`; phase 9 `planned`. Phase 8 is
   content-complete but untagged — no `cp-8` tag exists and checkpoint-tag has not run
   — so it stays `planned` here exactly as it reads in the index; phase 9 is this
   phase, also `planned`. A later checkpoint updates both files together; this story
   does not anticipate it.
5. **CONTENT-020's audit.** If `docs/pairmode-wiring-audit.md` exists in the tree when
   you build, add a one-line pointer to it from `docs/architecture.md` (one sentence
   saying where this repo's pairmode wiring divergences are recorded). Do not restate
   its findings. If the file is absent, add nothing.

**Forbidden proxies.** Each of these would make a check pass without making the claim
true:
- Editing `docs/phases/index.md` to match the stale ledger. The ledger is corrected to
  the index, never the reverse.
- Marking any phase `complete` that has not been checkpointed — specifically phase 8.
  Content-complete is not tagged.
- Documenting a procedure nobody follows: leaving the manual `JSON.stringify` splice in
  place as an "alternative path", or adding the script as an aside beside it. The
  script is the path.
- Satisfying the era/phase reference with a bare mention of the strings `001` or
  `Phase 7` somewhere in the file with no statement of what they are.
- Deleting the round-trip or headless-render requirements as part of the rewrite
  because the script now performs one of them.

## Tests

No test suite exists (static HTML; `CLAUDE.md`'s test command is a no-op). Verify by
inspection plus:

```bash
grep -n "bundle-template.py" docs/architecture.md
grep -n "scripts/" docs/architecture.md
grep -n "001-initial\|Phase 7" docs/architecture.md
grep -c "^| [1-9] " docs/eras/001-initial.md
git diff --name-only   # must not list docs/phases/index.md
```

Acceptance: the first three greps each return at least one line; the fourth returns
`9`; the fifth shows only `docs/architecture.md` and `docs/eras/001-initial.md`. The
real acceptance is checkpoint-docs re-run against `--phase-key 8` returning PASS, which
the orchestrator runs after merge, not the builder.

## Out of scope

- Re-running or re-recording the CP-8 checkpoint verdict — that is the phase's closing
  step, performed after all three Phase 9 stories merge.
- Any edit to `index.html` or `gap-handoff.html`. This story touches documentation
  only; CONTENT-021 owns the `#promote` prose defect.
- Filling in `docs/architecture.md`'s empty `## Domain model`, `## Layer rules`, and
  `## Non-negotiables` sections. They are stale in a different way and no gate finding
  names them.
- Changing `docs/phases/index.md`, any phase doc, or the era doc's Rails table.
