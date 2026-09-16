---
era: "001"
phase_class: production
---

# forqsite.help — Phase 7: Write for the reader, not about the work

← [Phase 6: Full structural back-check, and a verification stamp](phase-6.md)

## Goal

Make both documents state **what is true now**, for **a person standing forqsite
up**. Remove the page's account of its own editing history, and reframe the
gap document away from an AI work-order into something a human can use.

## Two problems, one cause

Phases 5 and 6 corrected the facts and, in doing so, wrote the corrections
*into the page*. The site now tells readers what it used to say:

- "**CHANGED** — The manual step has been engineered out. Earlier versions of
  this page said the opposite, and named it GAP-011 — that gap has shipped."
- "**FIXED** — A fresh clone completes this flow. Earlier versions of this page
  reported it blocked…"
- "Two items have closed since the first pass … and are removed."
- "Re-verified and NARROWED: SMTP_HOST is now documented, so it is no longer
  part of this finding."

None of that is documentation. A reader arriving today does not care what the
page said last month; they care whether a fresh clone works and how a pack gets
registered. Correction notices are a changelog, and this site has git for that.

The same instinct produced comparative prose where plain description belonged —
"that constraint has not moved", "what changed is who writes it", "still needs" —
each measuring the present against an unstated past the reader never saw.

**The fix is not to soften these. It is to state the current behaviour and
delete the comparison.**

## The gap document has no clear reader

Worse, and the reason this phase exists at all.

| Where | What it says |
|---|---|
| `<title>` | forqsite — dev → prod gap handoff |
| eyebrow | DEV → PROD GAP HANDOFF |
| h1 | **Work items for Claude Code** |
| intro | "Eight **stories** … acceptance criteria in the repo's **story format**" |
| link from the docs | "Gap handoff for **Claude Code** →" |
| call to action | "**Take these to Claude Code.**" |

Three problems:

1. **"Gap handoff" means nothing to a reader.** It is internal vocabulary —
   a handoff between whom, of what? The document never says.
2. **It addresses a harness, not a person.** Docs are written for humans. A
   human may well drive a harness to do the work — that is their choice and a
   good one — but the document must not assume it, and naming one specific tool
   in the title assumes it twice over.
3. **"Stories", "story format", "acceptance criteria", "rails" are the
   build process leaking through.** They describe how *this project* tracks work.
   A self-hoster does not have those conventions and does not need them.

## What the document actually is

A list of the places where forqsite, today, does not yet get a competent Linux
admin from clone to a running, recoverable production instance — with enough
detail to work around each one or fix it.

That is genuinely useful and worth keeping prominent. It needs to say so.

Reframed:

| Element | To |
|---|---|
| title / eyebrow / h1 | **Known gaps** — "What isn't ready yet" |
| audience line | the person evaluating or standing this up |
| `PROPOSED APPROACH` | **HOW TO FIX IT** |
| `ACCEPTANCE CRITERIA` | **DONE WHEN** |
| `SUGGESTED SEQUENCING` | **WHERE TO START** |
| link + CTA | "Known gaps →" / "See the known gaps" |

The GAP-0NN identifiers stay. They are stable, referenced from the pipeline
diagram, and useful to cite — an identifier is not jargon.

## What stays

**The verified stamp stays.** A "verified on DATE against COMMIT" line is a
statement about the document's current freshness, not about its history — it
tells a reader how much to trust what they are reading. That is the opposite of
a correction notice, and Phase 6 added it for a good reason.

**The eight gaps stay, with their evidence.** They are current state.

## Stories

| ID | Title | Status |
|----|-------|--------|
| CONTENT-013 | Reframe the gap document for a human self-hoster; retire the Claude Code framing | complete |
| CONTENT-014 | Strip correction notices and comparative phrasing from the docs site | complete |
| CONTENT-015 | Re-point every cross-reference to the renamed document | complete |

## Story ordering

CONTENT-013 sets the vocabulary; CONTENT-015 propagates it. CONTENT-014 is
independent of both.

## What is NOT in scope

- **Changing any fact.** Phase 6 verified them; this phase changes how they are
  worded, not what they claim. Any factual change found here is a defect in
  Phase 6 and gets recorded as one rather than fixed silently.
- **Rewriting the phase docs and stories in this repo.** They are build records
  and *should* read as history — that is their job. The rule in this phase
  applies to the two published HTML files, not to `docs/`.

## Schema delivery

| Object | Management surface | Exception |
|---|---|---|
| _(none — two static HTML files)_ | | |

---

### CP-7 result

**Phase complete.** Three stories.

One finding worth carrying forward: the gap document's "where to start" section
opened by telling the reader to do **GAP-002 first** and routed around
**GAP-011** — both removed in Phase 5, so the very first instruction pointed at
something that appeared nowhere on the page. Phase 5 and Phase 6 both missed it
because both asserted on IDs in the *items array*, and this was prose.

That is the third time a check has passed while the thing it existed to protect
was broken, and each time for the same reason: **the assertion looked at the data
structure, not at what the reader sees.** The Phase 7 check greps rendered text.

### CP-7 Cold-eyes checklist

- [ ] written-never-read — does anything this phase persists have no reader?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] round-trip — does every edited bundle still extract, re-inject and render?
- [ ] public hygiene — does any shipped file name an internal path, host or address?
- [ ] no self-narration — does any published page describe its own editing history?
- [ ] no build-process vocabulary — do the published pages use terms only this project's process defines?
