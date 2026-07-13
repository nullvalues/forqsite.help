---
id: CONTENT-003
rail: CONTENT
title: UX fixes: hash routing, scroll reset, responsive layout, deep links, clipboard fallback (U1-U10)
status: draft
phase: "2"
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
  - gap-handoff.html
touches: []
---

## Requires

- Same bundle-format handling as CONTENT-001 — this story edits the DCLogic class
  embedded in each template, not just the HTML markup, so extract it, edit it as plain
  JS, `node --check` it, then reassemble.
- Ideally run after CONTENT-001/002 land, since this story's diffs touch the same
  script tags; coordinate rather than clobbering each other's edits mid-flight.
- A way to verify rendering: a headless browser (e.g. Chromium `--dump-dom`) is strongly
  preferred for this story specifically, since most of its changes are interactive/CSS
  behavior that a text diff can't confirm.

## Ensures

- `nav()` in both files' DCLogic sets `location.hash` on navigation, reads the hash
  (preferred over `startPage`) on load, and listens for `hashchange` so back/forward
  work.
- The dead `document.querySelector('[data-dc-main]')` selector in `nav()` is fixed: the
  actual scroll container gets a `data-dc-main` attribute, and `nav()` calls
  `m.scrollTo(0,0)` after `setState` so switching pages resets scroll position.
- `index.html` has at least one `@media` breakpoint (~800px) that stacks or collapses the
  fixed 248px sidebar on narrow viewports.
- All `<pre>` elements and the env-table's wrapping container have `overflow-x:auto`.
- All 11 references from `index.html` to `gap-handoff.html` link to `gap-handoff.html#gap-00n`
  anchors; `gap-handoff.html`'s item objects' `anchor` field renders as an actual element
  id matching those anchors; a scroll-to-hash call runs after the bundle's async render
  completes (native anchor scroll fires too early otherwise).
- The `href="#"` pseudo-links (e.g. non-negotiables item 04's `goPipeline` link) are
  replaced with real hash hrefs (`#pipeline`, `#backup`, `#providers`, etc.) once hash
  routing lands.
- The env search shows a "no keys match — clear search/section" row instead of a bare
  empty table when a search+filter combination yields zero rows.
- Both files declare an inline data-URI favicon (reuse the sidebar's existing SVG mark
  if there is one), and the vestigial `fonts.googleapis.com`/`fonts.gstatic.com`
  preconnect links are removed (fonts are already embedded as woff2 assets).
- `copyCmd`'s clipboard copy has a fallback (hidden textarea + `execCommand('copy')`, or
  a caught-rejection path that pre-selects the text) so it still works when the page is
  opened via `file://`, where `navigator.clipboard` requires a secure context.
- `gap-handoff.html` gets either clickable P0–P3 priority chips that scroll to the first
  item of that priority, or a compact per-item ID index at the top.

## Instructions

Verify each fix against the actual rendered DOM, not just the source edit — several of
these (scroll reset, hash routing, anchor scrolling) only manifest at runtime.

## Tests

- `node --check` on both edited DCLogic scripts.
- JSON round-trip check on both files.
- Headless-browser render of both files: confirm `data-dc-main` present, gap-handoff
  anchor ids present and matching index.html's links, no console errors.
- Manual/simulated check: navigating between pages resets scroll to top; the URL hash
  updates on nav and browser back restores the previous page.
