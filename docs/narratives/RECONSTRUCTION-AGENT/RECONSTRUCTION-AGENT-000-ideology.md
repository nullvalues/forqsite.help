---
id: RECONSTRUCTION-AGENT-000
role: RECONSTRUCTION-AGENT
title: The reconstruction-agent — role ideology
status: draft
era: "005"
surfaces: [reconstruction, procedure]
rails: [INFRA]
stories: [INFRA-458, INFRA-460]
---

## Narrative

The reconstruction-agent is deliberately not part of the build loop. It is a
blank-slate exercise: given `docs/reconstruction.md` (an ideology brief
generated from `ideology.md` and the project's brief, never the codebase
itself) it produces a competing implementation and fills in
`docs/RECONSTRUCTION.md` with an honest, evidence-backed scoring report. Its
purpose is validation, not construction — it exists to answer "does this
project's stated ideology actually constrain an independent implementation
the way we believe it does," a question the build loop itself cannot answer
because the build loop already has the codebase in front of it.

Unlike every other harness role, it is never dispatched with a `model:`
override from `model_selector.py` — reconstruction is explicitly exempt from
the model-tiering the rest of the fleet uses, because the task's difficulty
(build a whole project from ideology alone) does not vary per-story the way
build-loop work does.

## Always true

- Works only from `docs/reconstruction.md` (the ideology brief) — never reads
  the original codebase unless it is explicitly provided alongside the brief.
- Produces both a working implementation and a filled-in
  `docs/RECONSTRUCTION.md` scoring report, never one without the other.
- Reports divergences from the original honestly, including a below-original
  score with justification when warranted — an inflated score defeats the
  exercise's purpose.

## Never

- Never asks the original team for implementation details not already in the
  brief.
- Never part of the story-build loop's dispatch map
  (`ACTION_SUBAGENT_TYPE`) — there is no `spawn-reconstruction-agent`
  `next-action` and none is planned; it is invoked directly, outside
  `CLAUDE.build.md`'s loop.
- Never apologizes for or minimizes a deliberate divergence — divergence
  from the original is the point of the exercise, not a defect in it.

## Open gaps

- This narrative was missing for the entire lifetime of the role's shell
  and templates (`agents/reconstruction-agent.md`,
  `docs/reconstruction.md.j2`, `RECONSTRUCTION.md.j2`) until INFRA-458 —
  a capability with no landing spot for as long as the role has existed.
- No standing discovery surface tells an operator when the last
  reconstruction run happened, how it scored, or whether the ideology brief
  it worked from is stale relative to the current `docs/architecture.md` —
  running it remains an entirely manual, operator-initiated act.
