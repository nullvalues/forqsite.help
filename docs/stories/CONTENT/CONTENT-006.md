---
id: CONTENT-006
rail: CONTENT
title: "Provider lifecycle: the registries are generated — correct the swap sequence and retire the false callout"
status: complete
phase: "5"
story_class: content
execution: orchestrator
primary_files:
  - index.html
touches: []
---

## Background

The provider lifecycle page instructed operators to hand-edit two source files
that are now generated, and carried a "VERIFIED" callout asserting the manual
step *had not* been engineered out. It has. Both
`server-provider-registry.ts` and `client-registry.ts` now open with
`GENERATED FILE — do not edit by hand` and are produced from the provider
manifest at prebuild, along with the transpile list.

This was the most load-bearing claim on the page, and following it would have an
operator editing a file whose contents are overwritten by the next build.

## Ensures

- The false callout is **replaced, not deleted**. A reader who remembers the old
  page is told the claim was retired and why; silently removing it would leave
  them wondering whether they misremembered.
- The webpack explanation is kept — the constraint is real and has not moved —
  but corrected on the one point that changed: who writes the entry.
- The swap sequence matches the platform's own install page, step for step.
- The trust-model note states that `REQUIRE_PACK_SIGNATURES` **defaults to off**.

## Why the step count went from six to seven

Not padding. The old sequence omitted two things an operator hits in practice and
folded a third into the wrong step:

- **Review is now step 1.** Manual review is the entire security boundary for
  third-party code, and it precedes the wiring rather than following it. The old
  list started at `pnpm add`.
- **Classify visibility is its own step.** Every newly loaded pack is seeded
  `private`, and a private pack cannot be enabled for any organisation. Skipping
  it looks exactly like a pack that failed to load — which is the support ticket
  this step exists to prevent.
- Registration is now a manifest entry via the admin form, not a source edit.

## Added: what the loader rejects

The page said validation failures were "fatal at boot" without distinguishing the
two classes. They behave very differently and an operator needs to tell them
apart: a per-pack rejection excludes that pack and names it in the admin UI while
every other pack keeps serving; the fatal class stops the process. Both are now
listed by cause.
