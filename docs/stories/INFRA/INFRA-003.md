---
id: INFRA-003
rail: INFRA
title: "Bundle template extract/inject tool, with a proven byte-identical round-trip"
status: complete
phase: "5"
story_class: infra
execution: orchestrator
primary_files:
  - scripts/bundle-template.py
touches: []
---

## Background

Gates every content story in this phase. `index.html` and `gap-handoff.html` are
self-extracting bundles: the page is built at runtime from a JSON-encoded
template inside a `<script type="__bundler/template">` element. The markup is not
in the file as markup, so neither a text editor nor a search-and-replace over the
bundle can change the page safely.

## Ensures

- `extract`, `inject` and `verify` subcommands.
- `verify` re-encodes the template already in the file and asserts the result is
  byte-identical, on both bundles, before any edit.
- `inject` re-parses what it is about to write and refuses if the round-trip does
  not reproduce the input.

## The detail that makes hand-editing unsafe

The encoder escapes every `/` as `/`. That is not cosmetic. The template
contains its own `</script>` sequences; unescaped, they terminate the script
element carrying them and truncate the page. A naive `json.dumps` omits it, which
is exactly what the first round-trip attempt did — it produced a 5,000-character
diff on a file nothing had edited.

`verify` exists to catch that class: if this script's encoder ever drifts from the
bundler's, injecting would rewrite every byte of the template and bury the real
edit in the diff. It fails loudly and says so rather than writing.

## Proven before use

```
index.html:       OK — round-trip is byte-identical (125,641 chars)
gap-handoff.html: OK — round-trip is byte-identical (37,953 chars)
```

A no-op extract→inject cycle on `index.html` was also run and `cmp` confirmed the
file was unchanged, byte for byte.
