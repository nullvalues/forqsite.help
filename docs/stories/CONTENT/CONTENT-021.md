---
id: CONTENT-021
rail: CONTENT
title: Correct the rolling-restart.sh claim on the Promoting a change page
status: draft
phase: "9"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
touches: []
narrative_roles: []
---

<!-- If this story changes any documented architecture, add docs/architecture.md to the touches: list above. -->

## Context

CONTENT-016 shipped the Promoting a change page with one sentence that contradicts two
things this site already publishes: `systemctl restart forqsite forqsite-scheduler (or
rolling-restart.sh, if you run two instances behind Caddy)`. The Process supervision
page's "Zero-downtime restarts, non-docker" section says the repo's rolling-restart story
is docker-shaped and that the *same pattern* works with two systemd instances — the
operator's own manual swap, not that script. GAP-004, on this site's own Known gaps list,
records that `rolling-restart.sh` points at the wrong compose path. So the page hands a
systemd reader a command the site elsewhere documents as both wrong-shaped and broken for
their arrangement. This story corrects that one sentence, points it at the manual
two-instance swap the site already describes, and carries the guardrail CONTENT-018's spec
had and CONTENT-016's lacked — which is precisely how the defect shipped.

## Requires

- The bundle-edit path: `scripts/bundle-template.py extract|inject|verify`. Extract once to
  a scratch file, edit only there, inject once, verify. Do not hand-edit the encoded
  `__bundler/template` payload inside `index.html`.
- `/mnt/work/forqsite` at `7089b9dc`. The evidence below was re-verified there on
  2026-09-21: `scripts/rolling-restart.sh:18` drives `docker compose -f
  docker-compose.rolling.yml`, `:21,30,40,49` stop and `up -d --build` the two *container*
  services `forqsite_a`/`forqsite_b`, and `:24,33,43,52` poll `localhost:3000`/`:3001` —
  the ports `docs/deployment/docker-compose.rolling.yml:18-19,34-35` publish. The compose
  file the script names by bare filename lives under `docs/deployment/`, which is GAP-004's
  wrong-path finding. Both files are byte-identical between `7089b9dc` and current `main`,
  so the page's existing stamp commit stays correct.
- The promote page's cross-link handler already exists: `goSupervision: this.nav('supervision')`
  is in `renderVals()` (added by CONTENT-018). No new handler is needed.

## Ensures

The Promoting a change page no longer names `rolling-restart.sh` anywhere; the
built-once passage instead gives `systemctl restart forqsite forqsite-scheduler` as the
restart, and, for a reader who cannot accept that restart's ~10–20s, points at the site's
own manual two-instance swap under Process supervision → "Zero-downtime restarts,
non-docker" via the existing `goSupervision` handler; the page's stamp reads `verified
2026-09-21 against nullvalues/forqsite@7089b9dc`; and the two other occurrences of
`rolling-restart.sh` in the template are unchanged, leaving exactly two in the whole file.

Forbidden proxies, each of which would satisfy a careless read of the above and must not
appear:

- Naming `rolling-restart.sh` as the command — or one of the commands, or a parenthetical
  alternative — for the site's non-docker/systemd path, in this section or in any future
  promotion/restart prose anywhere on the site. The script that ships drives
  `docker compose` against the repo's rolling compose file; the site's non-docker
  two-instance arrangement is the operator's own manual A-then-B swap. (Forbidden proxy:
  keeping the script name but hedging it — "or `rolling-restart.sh`, adapted", "the
  equivalent of `rolling-restart.sh`", a footnote saying it needs editing first.) This
  generalises CONTENT-018's guardrail: it binds every story that touches promotion or
  restart prose, not just this one.
- Touching either of the other two occurrences. Both are correct in context and out of
  scope: the Provider lifecycle page's swap step 5 cites the script only for the A-then-B
  *order* it encodes ("the A-then-B order `rolling-restart.sh` encodes"), which is a true
  statement about the script; and the GAP-004 entry's wrong-compose-path finding is the
  reason this correction exists. (Forbidden proxy: a global search-and-replace, or "fixing"
  GAP-004's wording while here.)
- Any container vocabulary — `docker`, `image`, `container`, `compose` — introduced into
  the promote page. The page has none today and the replacement must not explain why the
  script is wrong by describing what it is. (Forbidden proxy: "`rolling-restart.sh` is for
  the docker topology" as the fix — the script must simply not appear.)
- The strings `R0`–`R4` or the word `ring`.
- Editing the global sidebar stamp (`repo: nullvalues/forqsite@17b78645` / `verified:
  2026-09-16`) instead of the promote page's own stamp.
- Narrating the correction — any sentence describing what the page used to say.
- Prescribing tooling forqsite does not ship: no non-docker rolling-restart script, no
  promotion script, no release-directory or symlink scheme.

## Instructions

1. `python3 scripts/bundle-template.py extract index.html /tmp/tpl.html`. Edit
   `/tmp/tpl.html` only. The target is the single `<p>` in the `PAGE: PROMOTING A CHANGE`
   block that begins "**The artifact is built once**" — the paragraph between the page
   standfirst and the `<h2>The three streams</h2>` heading.

2. **The correction.** Replace only the trailing clause. After the build, the commands left
   are `systemctl restart forqsite forqsite-scheduler` and enabling packs per organisation
   — full stop, no parenthetical. Then, if a reader cannot accept that restart's brief
   unavailability, send them to the arrangement this site actually publishes: two systemd
   instances behind Caddy, restarted one at a time by hand, described under "Zero-downtime
   restarts, non-docker" on the Process supervision page. Make that a link, using the
   existing `goSupervision` handler and the same clickable-span styling the page's other
   cross-links use. Do not restate the topology — the supervision page owns it. Leave the
   rest of the paragraph (pin, lockfile, `config/providers.json`, "environments differ in
   which packs are switched on") exactly as it is.

3. **Stamp.** Update the promote page's own stamp line (the mono/muted `verified …` div at
   the end of the page, after "Which collapses are safe") to read `verified 2026-09-21
   against nullvalues/forqsite@7089b9dc`. The commit is unchanged because the script and
   compose file it rests on are byte-identical there and at current `main`; only the date
   moves. Leave the global sidebar stamp and every other section stamp untouched.

4. `python3 scripts/bundle-template.py inject index.html /tmp/tpl.html`, then verify.

*Ideology note:* step 1's extract/inject path preserves the Generated-artifact discipline
constraint under its Phase 2 loop-mediated exception; the change is prose plus one existing
nav handler, so the Zero-runtime-dependencies constraint (no override permitted) is
untouched.

*Scope note:* `scripts/bundle-template.py` is read, not modified, and the `/mnt/work/forqsite`
paths cited are evidence in a sibling repository — both are deliberately absent from
`touches:`. `index.html` is the only file this story writes. Spec-preflight warnings on
`/api/health` or `FORQSITE_ROLLING_RESTART`-class names are expected: they are defined in
`nullvalues/forqsite`, not in this static-site tree. Preflight's three findings
(`/api/health`, `FORQSITE_ROLLING_RESTART`, `scripts/bundle-template.py`) are expected and
left standing, as they were on CONTENT-016 and CONTENT-018.

*Proportionality note:* longer than a one-sentence correction normally warrants because the
phase doc requires this story to carry a generalised forbidden-proxy guardrail for all
future promotion/restart prose, and because two nearby occurrences of the same string are
correct and must be explicitly fenced off so a builder does not over-correct.

## Tests

```bash
cd /mnt/work/forqsite.help
python3 scripts/bundle-template.py verify index.html
python3 scripts/bundle-template.py extract index.html /tmp/check.html
node --check <(sed -n '/type="text\/x-dc"/,/<\/script>/p' /tmp/check.html | sed '1d;$d')
sed -n '/PAGE: PROMOTING A CHANGE/,/PAGE: ENV REFERENCE/p' /tmp/check.html | grep -c 'rolling-restart'
grep -c 'rolling-restart\.sh' /tmp/check.html
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 \
  --dump-dom 'file:///mnt/work/forqsite.help/index.html#promote' > /tmp/promote.dom
grep -c 'verified 2026-09-21 against nullvalues/forqsite@7089b9dc' /tmp/promote.dom
grep -c 'systemctl restart forqsite forqsite-scheduler' /tmp/promote.dom
sed -n '/PAGE: PROMOTING A CHANGE/,/PAGE: ENV REFERENCE/p' /tmp/check.html \
  | grep -Eic 'R[0-4]\b|\bring\b|docker|container|\bimage\b|compose'
```

Acceptance: `verify` reports byte-identical; `node --check` exits 0; the promote-page range
contains zero `rolling-restart` matches while the whole template still contains exactly two
`rolling-restart.sh` occurrences (Provider lifecycle swap step 5, GAP-004); the rendered
`#promote` DOM carries the new stamp and the plain `systemctl restart` command; the
forbidden-vocabulary grep over the promote-page range returns 0 (it returns 0 today — the
page has no container vocabulary to begin with). Also open `file:///mnt/work/forqsite.help/index.html#promote`
and confirm the new link navigates to `#supervision`. Finally, `git diff index.html` must
show changes confined to the promote page's built-once paragraph and its stamp line.

## Out of scope

- The Provider lifecycle page's swap step 5 and the GAP-004 entry — both correct in
  context, both untouched (see Forbidden proxies).
- The Process supervision page's "Zero-downtime restarts, non-docker" section: linked to,
  not rewritten, not restamped. Adding a non-docker restart procedure to this site is not
  this story's work.
- The Operations page's Upgrade section (CONTENT-018) and its stamp, and every other Phase
  8 content decision — this phase reopens only the one factual defect.
- `gap-handoff.html`, the global sidebar stamp, and the GAP-012 public-hygiene question
  (a backlog item and an operator ruling, per the phase doc).
