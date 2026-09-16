---
id: CONTENT-011
rail: CONTENT
title: "Add the two missing gate commands and document the pack store publish path"
status: complete
phase: "6"
story_class: content
execution: orchestrator
primary_files:
  - index.html
touches: []
---

## Background

Comparing the site's command surface against `package.json` found two shipped
commands documented nowhere, both provider-lifecycle gates — on the page Phase 5
had just rewritten.

- `pnpm conformance:walk` — packs the SDK artifacts, scaffolds a pack against
  them, installs, boots, and asserts on served bytes. Roughly three minutes, and
  **not** part of `pnpm test`, which is exactly why it needs documenting.
- `pnpm verify:provider-pins` — asserts every HTTPS pack pin has a matching
  review record with a byte-identical hash. **Nothing runs it automatically**;
  this repository has no CI.

`pnpm generate:registries` was added alongside, since Phase 5's rewrite refers to
the generated registries throughout without ever naming the command.

## The pack store was undocumented entirely

`packs.forqsite.dev` is live and has a documented procedure, and the site's
provider lifecycle covered installing a pack while never saying where a reviewed
pack is published. Added as its own section with the two things that are easy to
get wrong:

- **The order is load-bearing.** Review → record → upload → pin.
  `verify:provider-pins` asserts the lockfile pin matches a committed review
  record byte for byte, so recording the review *before* uploading is what makes
  that assertion hold. Reversing the middle two steps produces a pin nothing
  backs.
- **Keys are never overwritten.** A changed pack is published as a new version,
  never republished under the same name — otherwise a consumer pinning by
  version cannot tell two artifacts apart and the hash it pinned stops matching.

## Public-repo constraint

Hardest here, and honoured: the section names the public hostname (already
public), states that the vhost is GET/HEAD-only and that publishing is
authenticated from inside the operator network — and gives **no** endpoint, no
credentials, no bucket addressing, no internal IP. Asserted by the render check,
which greps the rendered page for internal addresses.
