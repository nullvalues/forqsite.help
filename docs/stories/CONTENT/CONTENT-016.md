---
id: CONTENT-016
rail: CONTENT
title: Add a Promoting a change section: the three streams, the environment roles, the lane diagram, and which collapses are safe
status: complete
phase: "8"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
touches: []
narrative_roles: []
---

## Context

The site gets a reader to a running instance and then stops. It shows an upgrade
command sequence with no failure model behind it: nothing on the page says which
parts of a change can be swapped back and which cannot, so a reader who hits a
destructive migration mid-rollover cannot learn from this site that the topology
it recommends is what made that fail. This story adds the missing theory as its
own page — the three streams, the environment roles, a lane diagram, and which
of those roles a one-box self-hoster may safely collapse. CONTENT-017 and
CONTENT-018 both name the streams this page defines, so it lands first.

## Requires

- The bundle-edit path: `scripts/bundle-template.py extract|inject|verify`. Extract
  once to a scratch file, make every edit there, inject once, verify. Do not
  hand-edit the encoded template inside `index.html`.
- the local forqsite clone checked out at `7089b9dc` (branch `main`). Its
  `docs/deployment/promotion-model.html` is the source model. Read it before
  writing. It is the internal statement; this page is the reader-facing one, with
  different vocabulary rules — not a copy.

## Ensures

A new `promote` page exists in `index.html`, reachable from the SELF-HOSTERS nav and
from `#promote`, carrying: the three-stream table with reversibility stated per
stream; the five environment roles under their plain names, each with the one class
of failure it exists to catch; a hand-authored inline `<svg>` lane diagram with no
external asset reference; the safe/unsafe collapse guidance with the
staging-into-production collapse advised against in terms of what cannot be undone;
a statement that the artifact is built once and promoted unchanged, phrased in the
site's existing non-docker/systemd vocabulary; and its own verification stamp
naming `2026-09-18` and `nullvalues/forqsite@7089b9dc`.

Forbidden proxies, each of which would satisfy a careless read of the above and
must not appear:

- The strings `R0`, `R1`, `R2`, `R3`, `R4` or the word `ring` anywhere in the
  rendered page. (Forbidden proxy: defining them once and then using them in prose.)
- Any container vocabulary — `docker`, `image`, `container`, `compose` — in the new
  page, other than the site's existing point that the repo compose files are dev
  conveniences. (Forbidden proxy: describing "promote the image".)
- Editing the existing sidebar stamp (`repo: nullvalues/forqsite@17b78645` /
  `verified: 2026-09-16`) instead of adding a section stamp. The rest of the page was
  not re-verified by this story and must not be restamped as if it were.
- A diagram box whose label is a verb (`build`, `restart`, `enable`, `promote`).
  Those are arrow labels; boxes hold states.

## Instructions

1. `python3 scripts/bundle-template.py extract index.html /tmp/tpl.html`. Edit
   `/tmp/tpl.html` only.

2. **Register the page.** In the `DCLogic` subclass `renderVals()`:
   - add `['promote','Promoting a change']` to the `navHosters` list, positioned
     after `['ops','Operations']` and before `['backup','Backup & recovery']`;
   - add `pPromote: page === 'promote'` alongside the other `p*` flags.
   Add `promote` to the `startPage` enum in the `data-props` attribute of the
   `<script type="text/x-dc">` tag, keeping that attribute's existing HTML-entity
   encoding. Routing needs nothing else — `nav(id)`/`goto(id)` already drive
   `location.hash` and the `hashchange` listener.

3. **Place the page block.** Insert a `<sc-if value="{{ pPromote }}">` block
   immediately after the `pOps` block closes and before the `pEnv` block, so markup
   order matches nav order. Follow the page shell the sibling pages use: a
   `<div data-screen-label="Promoting a change">` wrapper, the mono eyebrow
   `SELF-HOSTERS / PROMOTING A CHANGE`, an `<h1>`, a standfirst `<p>`, then `<h2>`
   sections — matching the inline-style conventions already on those pages.

4. **Content.** Four parts, in this order:
   - **The three streams.** A table: artifact (the built code, including every
     compiled-in pack) — reversible, swap back; schema (numbered SQL) — not
     reversible; content (stored block data reshaped for a pack upgrade) — not
     reversible, and no mechanism exists. State reversibility per row explicitly.
   - **The environment roles.** local, CI, standup, staging, production. One line
     each naming the single class of failure that role exists to catch — not what
     the machine is. Say in the same breath that these are roles, not five servers.
   - **The lane diagram** (step 5).
   - **Which collapses are safe.** local+CI costs reproducibility, not safety.
     standup into staging costs the fresh-install proof — acceptable on an existing
     instance, not before a first go-live. staging into production is the one to
     advise against, and the reason given must be that it removes the only rehearsal
     of the two streams that cannot be undone, never "process hygiene". Close with
     the plain conclusion: a one-box reader needs a second database they can throw
     away, not a second server.
   Also state, once and plainly, that the artifact is built once — from a pinned
   commit, a frozen lockfile and one provider manifest — and the same build is what
   every later environment runs; environments differ in which packs are enabled, not
   in what was compiled. Phrase it against the site's published path (`/opt/forqsite`,
   `pnpm build`, `systemctl restart`, `rolling-restart.sh`), and do not invent a
   release-directory or symlink scheme: the site does not document one. Check your
   wording against the "Production, without docker", "systemd units" and "Day-two
   runbook → Upgrade" sections before writing.

5. **The lane diagram.** One hand-authored inline `<svg>` — no `<img>`, no `<use
   href>`, no external URL, no library; styling inline or in a `<style>` inside the
   template, consistent with the zero-external-asset constraint in
   `docs/ideology.md`. Five horizontal lanes labelled with the plain environment
   names plus an unlabelled intake lane above them for a pack arriving from outside.
   Boxes are states (`Tarball`, `Attested`, `Published object`, `Pinned`, `Declared`,
   `Compiled artifact`, `Artifact`, `Loaded`, `Enabled`); arrows are operations
   (`intake`, `review`, `publish`, `install`, `declare`, `build`, `restart`,
   `enable`, `promote`). The promotion arrows leaving CI must be labelled so a reader
   can see the same artifact rides each one unchanged. Include a short "how to read
   this" note stating the boxes-are-states / arrows-are-operations grammar. Give the
   `<svg>` a `viewBox` and `width:100%; height:auto` so it scales, and wrap it in a
   horizontally scrollable container for narrow viewports. Do not carry over the
   source document's numbered lane labels.

6. **Verification stamp.** End the page with its own stamp line, in the mono/muted
   style the sidebar stamp uses, reading `verified 2026-09-18 against
   nullvalues/forqsite@7089b9dc`. Leave the global sidebar stamp untouched.

7. Do not narrate the change — no sentence describing what the site used to say or
   did not cover. Name no internal host, path or address; `/opt/forqsite` and
   `packs.forqsite.dev` are already published on this page and are fine.

8. `python3 scripts/bundle-template.py inject index.html /tmp/tpl.html`, then verify.

*Ideology note:* step 5's no-external-asset rule and step 1's extract/inject path are
written in to preserve the Zero-runtime-dependencies constraint (no override permitted)
and the Generated-artifact discipline constraint's Phase 2 loop-mediated exception.

*Scope note:* `scripts/bundle-template.py` and `docs/ideology.md` are named above and
are deliberately absent from `touches:` — both are read, neither is modified.
`index.html` is the only file this story writes.

*Proportionality note:* longer than a one-file `doc` story normally warrants because
this story authors an original diagram and is bound by two vocabulary constraints
(no numbered environments, no container terms) that a builder cannot infer.

## Tests

```bash
cd "$(git rev-parse --show-toplevel)"
python3 scripts/bundle-template.py verify index.html
python3 scripts/bundle-template.py extract index.html /tmp/check.html
node --check <(sed -n '/type="text\/x-dc"/,/<\/script>/p' /tmp/check.html | sed '1d;$d')
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 \
  --dump-dom "file://$PWD/index.html#promote" > /tmp/promote.dom
grep -c 'Promoting a change' /tmp/promote.dom
grep -Eic 'R[0-4]\b|\bring\b|docker|container|\bimage\b' /tmp/promote.dom
grep -c 'nullvalues/forqsite@7089b9dc' /tmp/promote.dom
grep -Eo '<(img|use|link|script)[^>]*(src|href)="(https?:|//)[^"]*"' /tmp/promote.dom | wc -l
```

Acceptance: `verify` reports byte-identical; `node --check` exits 0; the rendered
`#promote` DOM contains the page heading and the stamp; the forbidden-vocabulary grep
returns 0 within the new page block; no external `src`/`href` is introduced. Also open
`file://$PWD/index.html#promote` and confirm the SVG renders and
the nav entry highlights.

## Out of scope

- Rewriting "Provider packs (condensed)" (CONTENT-017), the Upgrade section
  (CONTENT-018), or Known gaps (CONTENT-019). This story adds the page they will
  reference; it adds no cross-links into it from those sections.
- Any claim about what a pack may store, the per-pack rejection failure, or the
  expand-and-contract rule. Those are CONTENT-017 and CONTENT-018 and carry their own
  verification.
- Building anything the model describes — no CI, no staging environment, no promotion
  script. The page must not imply forqsite ships tooling it does not ship.
- `gap-handoff.html`, the global sidebar stamp, and any correction to a fact
  established in Phase 6 (a factual error found here is recorded as a Phase 6 defect,
  not fixed in passing).
