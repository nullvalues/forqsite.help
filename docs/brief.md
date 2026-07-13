# Brief — forqsite.help

> This is a one-page project brief. It answers **what** and **why**.
> Design decisions and implementation choices belong in `docs/architecture.md`.

---

## What this project produces

Administrator documentation site for forqsite (self-hosted multi-tenant website builder), plus a dev-to-prod gap analysis doc

---

## Why it exists

forqsite.com is dogfooded as a tenant on a forqsite install; this docs site deliberately is NOT, so docs stay available when a forqsite instance is down

---

## Core beliefs

> What does this project believe? State convictions as positive claims.
> These are the values that shaped the design — what the project prefers and why.

- Docs must survive infra failure — this site must never depend on the thing it documents.
- Self-containment over convenience — no build step, no external assets, even though it
  makes hand-editing harder.
- Generated artifacts over hand-maintained source — `index.html` and `gap-handoff.html`
  are compiled bundles re-exported from a design session, not edited by hand.

---

## Accepted tradeoffs

> Decisions that had a real cost. What was given up, and why the exchange was worth it.
> A second implementation should understand what alternatives were considered and rejected.

- Gave up easy incremental hand-editing (single giant inlined HTML files are unwieldy to
  diff/patch) in exchange for zero runtime dependencies and true portability.
- Gave up a live, queryable backlog format for `gap-handoff.html` in exchange for keeping
  it in the same zero-dependency, offline-readable bundle as the rest of the docs.

---

## Constraints

_Explicit constraints the operator has placed on scope or approach:_

- No server, no database, no build step for anything published under this repo.
- Do not make this site a forqsite tenant — that would defeat its purpose.

---

## Not in scope

_Things that might seem related but are intentional omissions:_

- Hosting forqsite.com itself, or any other dogfooded forqsite property.
- A CMS, admin UI, or dynamic content pipeline for these docs.
- Real-time sync of `gap-handoff.html` with the actual state of `nullvalues/forqsite` —
  it's pruned manually as gap items land upstream.

---

## What a second implementation must preserve

> The irreducible requirements. An implementation that violates these is not this project.
> Everything else is negotiable.

- Zero runtime dependencies: openable from `file://`, offline, or any static file server.
- Independence from forqsite itself — must remain hostable even when every forqsite
  instance is down.
- Fully inlined single-file HTML documents (no external font/style/script requests).

---

## Operator contact

_(not specified)_


---

_These three documents should be sufficient for any model or toolchain to cold-start this project and reproduce a valid variant without prior session context._

- `docs/brief.md` — what and why (operator intent)
- `docs/architecture.md` — how and architectural decisions
- Current phase file from `docs/phases/` (or `docs/phase-prompts.md` for legacy projects)
