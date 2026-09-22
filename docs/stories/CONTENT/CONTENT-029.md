---
id: CONTENT-029
rail: CONTENT
title: Record the site-URL ruling in the rule it extends, and scrub what it now covers
status: draft
phase: "11"
story_class: doc
auth_gated: false
schema_introduces: false
touches:
  - docs/ideology.md
  - README.md
  - docs/architecture.md
  - docs/phases/phase-4.md
  - docs/stories/INFRA/INFRA-002.md
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->
## Context

The CP-11 security audit found the public site URL committed in live descriptions of the
architecture. The operator has ruled that the URL falls under `docs/ideology.md` § Name the class,
not the instance: this repository and its product are to be released as public sibling repos, and
a downstream adopter rebrands both, so the URL names our instance rather than the product. The
ruling has not been written down, so the next gate would raise the same question again. This
story records the ruling in the constraint it extends, then generalises the occurrences the
constraint now covers. It is CP-11 remediation (see the phase doc § CP-11 remediation) and the
last story before the CP-11 gates are re-run.

## Requires

- INFRA-009 complete. It is, per the phase-11 Stories table.
- `docs/ideology.md` § Name the class, not the instance exists in its current form.

## Ensures

- `docs/ideology.md` § Name the class, not the instance states that the public site URL is a
  deployment-specific identifier this rule covers, and gives the operator's reason: the
  repository and its product ship as public sibling repos, and a downstream adopter rebrands
  both. The paragraph does not contain the URL itself.
- Outside `index.html`, `gap-handoff.html`, and the executed or served files listed under Out of
  scope, no tracked file contains the public site URL, either as a scheme-qualified URL or as a
  bare hostname used as an address. Uses of `forqsite.help` as this project's or repository's
  *name* are not occurrences and stay unchanged.
- Each generalised occurrence keeps its reason. A reader can still learn how to reach the live
  site (see Instructions step 3), and can still work out the hosting arrangement by class: what
  serves it, what fronts it, and why. Forbidden proxy: a bare deletion, or a placeholder like
  `<site>` with no surrounding explanation, which passes the grep and loses the explanation.
- `git diff` shows no change to `index.html` or `gap-handoff.html`.

## Instructions

1. Re-derive the occurrence list. Do not trust the auditor's four files. Run the Tests grep over
   every tracked file, and read each hit to classify it: an *address* (in scope), or the
   *project/repo name* (leave it alone). The four files the auditor named are in `touches:`. If
   you find an address in any other documentation file, generalise it too and add that file to
   `touches:`.
2. In `docs/ideology.md` § Name the class, not the instance, add one short paragraph (two to four
   sentences) recording the ruling and its reason as stated in Ensures. Extend the rule. Do not
   restate it. Do not touch any other section of `docs/ideology.md`.
3. Generalise each occurrence by class, e.g. "the public site", "the site's public address", or
   "the edge proxy that fronts the container". For `README.md`, where a reader may need to reach
   the live site, say that the address is per-deployment and is published outside the tree, in
   the repository's homepage/website metadata. Do not invent an address and do not put one back.
   *Spec-writer resolution:* the phase doc requires that readers can still find the site, but it
   does not say how. The homepage-metadata pointer was chosen because it satisfies that
   requirement without breaking the constraint. The reviewer should confirm the operator accepts
   it (see Spec-writer notes).
4. Historical phase and story docs (`docs/phases/phase-4.md`, `docs/stories/INFRA/INFRA-002.md`)
   are generalised in place. Keep their meaning and record, and change only the identifier.
5. Findings and dated verification records also get the class form. The constraint prefers it
   wherever both forms work, and a finding that reports the URL must not itself carry it (a
   partial scrub is not a scrub).

Ideology check: the drafted steps preserve "Generated-artifact discipline" by never touching the
bundles, and apply "Name the class, not the instance" as written. No conflict.

## Tests

```bash
cd /mnt/work/forqsite.help
# 1. The address, in any form, outside the bundles. Expect only project-name uses, classified by the reviewer.
git grep -nIi 'forqsite\.help' -- . ':!index.html' ':!gap-handoff.html'
# 2. The scheme-qualified form, which must be zero.
git grep -nIiE 'https?://(www\.)?forqsite\.help' -- . ':!index.html' ':!gap-handoff.html' ; test $? -eq 1
# 3. The bundles are untouched.
git diff --quiet HEAD -- index.html gap-handoff.html
```

Acceptance: command 2 exits 0 (no matches) and command 3 exits 0. Every remaining hit from
command 1 is the project or repository name, not an address. The reviewer confirms this by
reading each hit. Documentation story: no test file expected.

## Out of scope

- `index.html` and `gap-handoff.html`. The published bundles are out of scope for this phase
  entirely, even where they carry the URL.
- Executed or served configuration, such as `nginx.conf` and `scripts/`. If one carries the
  address functionally (e.g. a `server_name`), do not edit it. Report the hit to the orchestrator
  as a finding. Changing served config needs a container action, and that is not a documentation
  change.
- Rewriting git history to remove past occurrences.
- Setting the repository's homepage/website metadata. That is an operator action outside the tree.
- Repository URLs (e.g. the GitHub remote of this repo or the product repo). The ruling covers the
  public site URL only.
- Renaming the project or repository, whose name is `forqsite.help`.

## Spec-writer notes

- The stub has no `primary_files:` field. This spec leaves the frontmatter as it is and declares
  the doc surfaces under `touches:`. A human should add `primary_files: [docs/ideology.md]` if the
  loop requires it.
- Instructions step 3's homepage-metadata pointer is the spec-writer's resolution of how "a
  reader can still find the live site". The operator should confirm it before build.
