---
id: CONTENT-009
rail: CONTENT
title: "Day-two runbook: correct the condensed provider-pack steps to match"
status: complete
phase: "5"
story_class: content
execution: orchestrator
primary_files:
  - index.html
touches: []
---

## Background

The day-two runbook carried its own four-step condensed version of the pack
install, including "Register the static import in `server-provider-registry.ts` —
skip this and the pack silently never loads."

That instruction is now doubly wrong: the file is generated, and the failure it
warns about no longer exists in that form. A stale shortcut is more dangerous
than a stale long-form page, because the shortcut is what a hurried operator
actually follows.

## Ensures

- Five steps that agree with the provider lifecycle page and the platform's own
  install page.
- The "not registered" symptom is given its real meaning — a stale generated
  registry, fixed by rebuilding, never by editing.
- Signature enforcement is described as **off by default**, matching the
  lifecycle page. The previous wording ("require ed25519 signatures: set …") read
  as though it were already in force.

## Also corrected in the backup section

Two places described `config/providers.json` as "hand-edited". It is written by
the platform-admin install form. The substance was and remains correct and
important — it is gitignored, so a rebuilt host cannot reproduce the provider set
without it — and only the authorship claim changed.
