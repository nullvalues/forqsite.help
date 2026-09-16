---
era: "001"
phase_class: production
---

# forqsite.help — Phase 6: Full structural back-check, and a verification stamp

← [Phase 5: SDK 5.0.0 and the generated-registry ingestion path](phase-5.md)

## Goal

Re-verify **every** factual claim on the site against forqsite's current source,
fix what has drifted, and put a visible "last verified" stamp on the page so the
next reader can tell how old the answer is without asking.

## Why this phase exists

Phase 5 scoped itself to what PM100-main provably changed and said so in its own
"What is NOT in scope" section. That was a defensible call and it was the wrong
one: the operator read the updated site, still saw findings they recognised as
old, and could not tell from the page whether anything had been checked. Both
complaints are correct.

A docs site with no verification date is not a document, it is a rumour. The
reader has no way to distinguish "checked last week and still true" from "written
once and never revisited" — and this site had both on the same page.

## Baseline

Every claim in this phase was checked against `nullvalues/forqsite` at the commit
recorded in INFRA-005's stamp. Where a claim is now wrong, the story says what
the source actually shows.

## What the back-check found

**The env-var reference is missing five keys**, four declared and one not:

| Key | Why it matters |
|---|---|
| `TRUST_PROXY_CLIENT_IP` | defaults `true` |
| `TRUST_PROXY_FORWARDED_HOST` | defaults `true` |
| `IMPORT_WORK_DIR` | moves the import working set to another volume |
| `CONTENT_IMPORT_MAX_UPLOAD_BYTES` | upload bound |
| `TRUST_PROXY_CLIENT_IP_HEADER` | **required in practice, declared nowhere** |

The last is the important one and is a documentation defect with a real failure
mode. It is deliberately excluded from the config registry (Story SEC-045), but
when `TRUST_PROXY_CLIENT_IP` is true — which is the **default** — the platform
throws unless it is set to `x-forwarded-for` or `x-real-ip`, with no fallback
between them. So the out-of-the-box configuration fails closed on a variable
absent from both the config registry and this site's table.

**Corrected during the build:** forqsite's own `docs/configuration.md` *does*
document it, and the other three proxy/import keys too. The gap was this site's
alone, not forqsite's. An earlier draft of this spec said a self-hoster "has
nothing to search for", which overstated it — they have the repo's own
configuration reference. What they did not have is any mention on the site that
sends them to production.

**Nine keys on the site are absent from the config registry and all nine are
correct.** They are read from scripts, the seed, or `process.env` directly.
Checked individually rather than assumed stale, because pruning them would have
removed true content — the same trap CONTENT-008 avoided with the gap ledger.

**Two shipped commands appear nowhere on the site:** `pnpm conformance:walk` and
`pnpm verify:provider-pins`. Both are provider-lifecycle gates, which makes their
absence worse than an ordinary omission — Phase 5 rewrote that very page.

**The pack store is undocumented entirely.** `packs.forqsite.dev` exists, is
live, and has a documented publish procedure with a hard ordering constraint
(review → record → upload → pin) and an immutability rule. The site's provider
lifecycle covers installing a pack and never says where a reviewed pack is
published or that republishing a key is forbidden.

**GAP-010 is half-fixed.** Two of the four keys it names as missing from
`configuration.md` are now documented there; two others it does not name are
still missing. The row is narrowed to what is still true rather than left to
imply more than it should.

**GAP-003 through GAP-009 are all still open**, and their cited evidence still
matches the source line for line. Re-verified, not assumed.

## Stories

| ID | Title | Status |
|----|-------|--------|
| INFRA-005 | Add a "last verified" stamp: date plus the forqsite commit it was checked against | complete |
| CONTENT-010 | Env reference: add the four missing keys and the required-but-undeclared proxy header | complete |
| CONTENT-011 | Add the two missing gate commands and document the pack store publish path | complete |
| CONTENT-012 | Narrow GAP-010 to what is still true; fix the priority chips | complete |

## Story ordering

INFRA-005 first: the stamp is what every other story's claim hangs off, and a
content fix landing before the stamp exists produces a page that is correct and
still unverifiable. The three CONTENT stories are independent.

## Public-repo constraint

Unchanged from Phase 5, and it binds CONTENT-011 hardest. The pack store's
endpoint, credentials and DMZ addressing are operator infrastructure and are
**not** recorded even in forqsite's own repository. The site documents that the
store exists, its public hostname (already public), the publish *order* and the
immutability rule — and no address, no credential, no internal network detail.

## What is NOT in scope

- **Fixing the eight open gaps.** They are forqsite's work, not this site's; the
  site's job is to report them accurately, which it now does.
- **Automating the sync.** Still the right answer and still unbuilt. The stamp
  makes the staleness visible, which is the cheap half.

## Schema delivery

| Object | Management surface | Exception |
|---|---|---|
| _(none — two static HTML files)_ | | |

---

### CP-6 result

**Phase complete.** Four stories. The back-check found more than expected, and
two of the findings were defects this project had itself shipped.

**A live defect from Phase 5.** The gap handoff's priority chips are hardcoded,
not computed. CONTENT-008 removed the only P0 item and left the chip claiming
**P0 — BLOCKS FRESH CLONE × 1**, with a click target resolving to an undefined
anchor. The live site told every reader there was an open blocker preventing a
fresh clone — the most alarming claim the page can make — about the very item
that phase had just fixed. Phase 5's render check missed it because it asserted
on gap IDs, and chips contain none.

**A defect caught before shipping.** The first GAP-010 edit sliced the `mk()`
call on a delimiter that also occurs inside the data, swallowing an argument
boundary and leaving `evidence` bound to a string. The page died on load with
every gap invisible. Static validation passed it; the render caught it. That is
twice now.

Both are written up in CONTENT-012 rather than quietly fixed, because the pattern
matters more than either instance: **an assertion that does not name the thing it
is protecting will pass while that thing is broken.**

### CP-6 Cold-eyes checklist

- [ ] written-never-read — does anything this phase persists have no reader?
- [ ] required-never-written — does any read path depend on a value no writer produces?
- [ ] duplicate state — is any fact now stored twice with independent writers?
- [ ] round-trip — does every edited bundle still extract, re-inject and render?
- [ ] public hygiene — does any shipped file name an internal path, host or address?
- [ ] verified-not-assumed — is every pruned or altered claim backed by a check against source?
