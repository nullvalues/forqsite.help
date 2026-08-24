---
id: SHADOW-REVIEWER-000
role: SHADOW-REVIEWER
title: The shadow-reviewer — role ideology
status: draft
era: "005"
surfaces: [CLAUDE.build.md, procedure]
rails: [INFRA]
stories: [INFRA-358, INFRA-359, INFRA-455, INFRA-458, INFRA-459, INFRA-460]
---

## Narrative

The shadow-reviewer is the only role in the loop that runs *alongside* the
builder instead of before or after it — concurrent, in the same disposable
worktree, largely passive. Its whole value proposition is cheap early
warning: catch a drifting build while it is still in progress, when a
suggestion is easy to act on, instead of waiting for the reviewer's PASS/FAIL
verdict to be the first signal the builder ever sees. It self-directs: no
lock file, no request marker, no orchestrator-issued dispatch prompt beyond
"look again" — it reads the worktree's own git state to decide for itself
whether there is new work worth a pass.

The role shipped in three separable pieces (INFRA-358's shell and procedure,
INFRA-359's `concurrent` dispatch wiring), and for a full phase after that
had no narrative and no discovery surface of its own — a live instance of
exactly the gap INFRA-457 names and this scan (INFRA-458) now catches
mechanically.

## Always true

- Runs concurrently with the builder in the same worktree; never dispatched
  serially, before, or after.
- Writes only to the shared `.pairmode-suggestions.md` file — never to story
  files, never to the code under review, never anywhere else.
- Self-directs each pass from the worktree's own git state (`git log`/
  `git status`/`git diff` against its own last-seen bookmark); no lock file,
  no marker, no orchestrator-side request state.
- Offers advisory, take-it-or-leave-it suggestions only — the builder is
  never required to act on them.

## Never

- Never writes code, never commits, never blocks the build.
- Never dispatched a second time while a prior dispatch is still in flight —
  serialization is structural, not lock-enforced.
- Never assumes it is the only reader/writer of the shared suggestions file
  ordering guarantee beyond its own bookmark discipline.

## Open gaps

- Advisory-only means a genuinely load-bearing catch (something the builder
  should have been blocked on, not merely nudged about) has no escalation
  path beyond the free-text suggestion itself — there is no severity field,
  and no mechanism ties an ignored suggestion back to a reviewer or
  cold-eyes finding for follow-up.
- This narrative was itself absent for a full phase after the role's shell,
  procedure, and dispatch wiring shipped (INFRA-358/INFRA-359) — the first
  landing-spot gap `dark_feature_scan.py` (INFRA-458) was built to catch.
