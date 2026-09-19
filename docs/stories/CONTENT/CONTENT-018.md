---
id: CONTENT-018
rail: CONTENT
title: Add the expand-and-contract rule to Day-two runbook Upgrade, derived from the rolling-restart topology
status: draft
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

The Upgrade section of the Day-two runbook is six commands in a black box and nothing
else: `git pull`, `pnpm install --frozen-lockfile`, `pnpm db:migrate`, `pnpm build`,
`systemctl restart`. It is a correct recipe with no failure model behind it. A reader who
follows it, hits a destructive migration part-way through a rollover, and then puts the
previous code back has no way to learn from this site that the topology the site itself
offers for zero-downtime restarts is what made that fail, or that the schema did not come
back with the code. This story adds the constraint and its origin to that section: one
database serving two code versions, therefore every migration readable by the previous
version, therefore a destructive change is two releases — and a rollback instruction that
says what rolling back does not undo, in the same breath as the steps for doing it. It
places the whole thing inside the **artifact** and **schema** streams that Promoting a
change (`#promote`) already names, referencing that vocabulary and never redefining it.

## Requires

- The bundle-edit path: `scripts/bundle-template.py extract|inject|verify`. Extract once
  to a scratch file, edit only there, inject once, verify. Do not hand-edit the encoded
  `__bundler/template` payload inside `index.html`.
- CONTENT-016 complete: the `promote` page exists and defines the **artifact**, **schema**
  and **content** streams, and `goPromote: this.nav('promote')` already exists in
  `renderVals()` (added by CONTENT-017). This section uses those words in that sense and
  does not restate their definitions.
- `/mnt/work/forqsite` checked out at `7089b9dc` (branch `main`), clean. Every claim below
  was verified there on 2026-09-19; the citations in `## Instructions` are the evidence a
  reviewer re-checks, at that commit.

## Ensures

The "Upgrade" section of the Operations page states, as verified fact: that running two
instances behind Caddy for a zero-downtime restart means **one database serving two code
versions** for the duration of the rollover, because both instances take the same
environment and therefore the same database; that the same window exists for a
single-instance operator, because the published order applies the migration before the
build and the restart; that every migration must therefore be readable by the **previous**
version — additive first (add, backfill, write both), drop the old shape in a later
release; that a destructive change is **two releases, never one**; and that putting the
previous pin back rebuilds and restarts the old code but leaves the migration applied,
stated inside the rollback instruction itself rather than as a separate caution. The
section ends with its own stamp reading `verified 2026-09-19 against
nullvalues/forqsite@7089b9dc`.

Forbidden proxies, each of which would satisfy a careless read of the above and must not
appear:

- Presenting expand-and-contract as advice, best practice, or something a careful operator
  "should" do. It is forced by the topology the site publishes. (Forbidden proxy: "it is
  good practice to keep migrations backward-compatible".)
- Any wording that implies a migration can be undone — a down step, a reverse migration, a
  `db:rollback`, or "restore from backup" offered as if it were the schema's return path.
  Nothing of the kind ships (see step 4's evidence).
- Telling a systemd reader to run `rolling-restart.sh`. The script that ships drives
  `docker compose` against the repo's rolling compose file; the site's non-docker
  two-instance arrangement is the operator's own. (Forbidden proxy: naming the script as
  the instruction for the published production path.)
- Putting the "rolling back the artifact does not roll back the schema" point in its own
  warning box, footnote, or later paragraph. The phase doc requires it in the same breath
  as the rollback instruction. (Forbidden proxy: a correct sentence in a coloured callout
  underneath the steps.)
- Implying the two-code-versions window belongs only to two-instance operators, or that a
  single-box reader is exempt. (Forbidden proxy: scoping the whole section under a
  "if you run two instances" heading.)
- Prescribing a second server, a staging host, or any environment the reader must build.
  The safe-collapse guidance lives on `#promote`; this section links to it.
- Re-defining artifact / schema / content, or introducing a fourth stream.
- The strings `R0`–`R4` or the word `ring` — they appear in the source model
  (`promotion-model.html:297,385`) and must not travel here.
- Editing the global sidebar stamp (`repo: nullvalues/forqsite@17b78645` /
  `verified: 2026-09-16`) instead of adding a section stamp.
- Changing the six-command upgrade block itself or any other Phase 6 fact. A factual error
  found in them is recorded as a Phase 6 defect, not fixed here.

## Instructions

1. `python3 scripts/bundle-template.py extract index.html /tmp/tpl.html`. Edit
   `/tmp/tpl.html` only. The target is the `<h2>Upgrade</h2>` block inside the `pOps` page,
   immediately before `<h2>Provider packs (condensed)</h2>`. Keep the existing six-command
   `<pre>` block and its COPY control exactly as they are and build the new material around
   them, matching that page's inline-style conventions.

2. **Cross-links.** Add `goSupervision: this.nav('supervision')` beside `goPromote` in
   `renderVals()` (it does not exist yet) and use it once, for the two-instance topology,
   which the site documents under "Zero-downtime restarts, non-docker" on the Process
   supervision page. Use the existing `goPromote` once for the streams and the
   safe-collapse guidance. Two links, no more.

3. **Why there are two code versions.** State the topology consequence, not the topology —
   the supervision page already describes the arrangement. Two instances behind Caddy with
   `lb_policy first`, health-checked on `/api/health`, are restarted one at a time so one
   keeps serving while the other comes back; both take the same environment, so both talk
   to the same database. For the length of the rollover the database is at the new schema
   while one instance is still running the old code. Evidence:
   `docs/deployment/docker-compose.rolling.yml:3-5` (two instances, Caddy routing on
   `/api/health`), `:20-21` and `:36-37` (both services take `env_file: .env.local` — one
   `DATABASE_URL`, one database); `scripts/rolling-restart.sh:7-15` (stop A, wait until it
   stops serving, rebuild, wait healthy, then the same for B).
   Then close the single-box gap in the same passage: the window is not a two-instance
   luxury. The published order on this very page runs `pnpm db:migrate` at step four and
   the restart at step six, so on one host the old process serves against the new schema
   for however long `pnpm build` takes. Say it plainly — one instance shortens the window;
   it does not remove it.

4. **The rule that forces.** Every migration must be readable by the **previous** version.
   Additive first: add the column, backfill it, ship code that writes both shapes — then
   drop the old shape in a later release, once nothing running still needs it. A
   destructive change is **two releases, never one**. Give the reader the reason the drop
   cannot simply be reverted: migrations are numbered SQL files applied in journal order by
   `pnpm db:migrate`, and there is no down step — 95 forward `.sql` files under
   `src/db/migrations`, ordered by `meta/_journal.json`, no down file among them, and no
   rollback script in `package.json`. Evidence: `package.json:25` (`db:migrate` =
   `drizzle-kit migrate`), `drizzle.config.ts:9` (`out: './src/db/migrations'`),
   `src/db/migrations/meta/_journal.json` (`idx`/`tag` ordering), `package.json:9-47` (no
   down or rollback script). forqsite's own history has the pair: the RBAC tables were
   added in `0050_rbac_schema_and_seed.sql` and the legacy tables dropped in
   `0051_rbac_drop_legacy_tables.sql`, two separate releases (`a242b05c`, then `4a429dab`).
   Use it as the worked example — it is real, and it is the shape the reader has to copy.

5. **Rollback, with the limit inside it.** Add the rollback instruction the section does not
   currently carry, phrased against the site's published path: put the previous pin back —
   the same commit, the same lockfile, the same `config/providers.json` — then
   `pnpm install --frozen-lockfile`, `pnpm build`, restart. The sentence that gives those
   steps must also say, in itself, that the migration stays applied: the migration ran
   before the restart, so this returns the code and not the schema, and the old code now
   runs against the new schema permanently rather than for a rollover. Do not split that
   into a step plus a warning. Do not offer a way to reverse the migration, and do not
   offer a database restore as one — backup and recovery is a separate runbook with its own
   scope, and reaching for it here would mean discarding everything written since the
   upgrade.

6. **The failure that does not announce itself.** One short passage, because CP-8 requires
   silent failures named at the point the reader would hit them: a forgotten `pnpm
   db:migrate` does not stop a start. The prestart check warns and always exits 0, and it
   only compares tables that migrations create — a migration that adds a column to an
   existing table passes it silently. Evidence: `package.json:42` (`prestart`),
   `scripts/check-migrations.ts:42` (`CREATE TABLE` names only), `:60-64` ("Always exit 0:
   missing tables produce a WARN but must not block startup"). Tell the reader where the
   line is: the process log.

7. **Stamp.** End the section — after the new material and before the "Provider packs
   (condensed)" heading — with its own stamp line in the mono/muted style the promote and
   provider-pack sections use: `verified 2026-09-19 against nullvalues/forqsite@7089b9dc`.
   Leave the global sidebar stamp untouched.

8. Do not narrate the change — no sentence describing what this section used to say or
   omit. Name no internal host or path beyond what the site already publishes.

9. `python3 scripts/bundle-template.py inject index.html /tmp/tpl.html`, then verify.

*Ideology note:* step 1's extract/inject path is written in to preserve the
Generated-artifact discipline constraint under its Phase 2 loop-mediated exception; the
section adds prose and two `nav` handlers only, with no external asset, so the
Zero-runtime-dependencies constraint (no override permitted) is untouched.

*Scope note:* `scripts/bundle-template.py` is read, not modified; the forqsite paths cited
above are evidence in a sibling repository and are deliberately absent from `touches:`.
`index.html` is the only file this story writes. Spec-preflight warnings on `/api/health`,
`DATABASE_URL` and `FORQSITE_ROLLING_RESTART` are expected and left standing: all are
defined in `nullvalues/forqsite`, not in this static-site tree.

*Verification note:* the phase doc's first bullet says "the site recommends two instances
behind a proxy". What the site actually publishes is narrower and the section must match
it: the two-instance arrangement is offered for when the standard restart's ~10–20s is not
acceptable, not as the default. Step 3 is therefore written as a conditional the reader
opts into, with step 3's closing paragraph carrying the rule across to the single-instance
case so the constraint does not read as optional. The shipped `scripts/rolling-restart.sh`
is `docker compose`-shaped (`:18`) and is not the non-docker path's tooling; nothing in
this section may present it as such.

*Proportionality note:* longer than a one-file `doc` story normally warrants because every
sentence it instructs is a claim about a second repository and carries its own citation,
and because two of the four "Done when" bullets are constrained in how they may be
phrased (same-breath rollback, no advice-voice) in ways a builder cannot infer.

## Tests

```bash
cd /mnt/work/forqsite.help
python3 scripts/bundle-template.py verify index.html
python3 scripts/bundle-template.py extract index.html /tmp/check.html
node --check <(sed -n '/type="text\/x-dc"/,/<\/script>/p' /tmp/check.html | sed '1d;$d')
chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 \
  --dump-dom 'file:///mnt/work/forqsite.help/index.html#ops' > /tmp/ops.dom
grep -ci 'two releases, never one' /tmp/ops.dom
grep -ci 'previous version' /tmp/ops.dom
grep -c 'db:migrate' /tmp/ops.dom
grep -c 'nullvalues/forqsite@7089b9dc' /tmp/ops.dom
grep -Eic 'R[0-4]\b|\bring\b' /tmp/ops.dom
grep -Eic 'down migration|roll(ing)? back the migration|db:rollback' /tmp/ops.dom
grep -Eo '<(img|use|link|script)[^>]*(src|href)="(https?:|//)[^"]*"' /tmp/ops.dom | wc -l
```

Acceptance: `verify` reports byte-identical; `node --check` exits 0; the rendered `#ops`
DOM contains the two-releases sentence, the previous-version rule, the stamp, and the
unchanged six-command block; the build-process-vocabulary grep and the
reversible-migration grep both return 0; no external `src`/`href` is introduced. Also open
`file:///mnt/work/forqsite.help/index.html#ops` and confirm both new links navigate (to
`#supervision` and `#promote`), the COPY control on the upgrade block still works, and the
rollback instruction and the schema-stays-applied clause are in the same sentence, not
split across a step and a callout.

## Out of scope

- A diagram. The window is drawn once, on `#promote` (CONTENT-016); this section links
  there rather than authoring a second SVG.
- The Provider packs (condensed) section (CONTENT-017, complete) and the Known gaps entry
  for the content stream (CONTENT-019) — including the field-key-rename failure, which is
  CONTENT-019's and must not be pre-empted here.
- The Backup & recovery page. This section may not send the reader there as a schema
  rollback route, and does not change what that page says.
- The Process supervision page's "Zero-downtime restarts, non-docker" section — linked to,
  not rewritten, and not restamped.
- Proposing or implying any tooling forqsite does not ship: no down migrations, no
  rollback script, no promotion script, no non-docker rolling-restart script.
- `gap-handoff.html`, the global sidebar stamp, and any correction to a Phase 6 fact (a
  factual error found here is recorded as a Phase 6 defect, not fixed in passing).
