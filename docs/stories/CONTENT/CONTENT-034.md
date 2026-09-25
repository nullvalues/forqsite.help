---
id: CONTENT-034
rail: CONTENT
title: Replace env parsing in the backup, cron and restore blocks with forqsite's own loader
status: complete
phase: "12"
story_class: doc
auth_gated: false
schema_introduces: false
primary_files:
  - index.html
touches:
  - docs/cer/backlog.md
narrative_roles: []
---

## Context

cp-12's gates passed. A cold cross-corpus triage by two independent readers, followed by two
independent designs, then found that three copyable blocks on the Backup & recovery route
do not work against the release commit `1fda3228322d5ad779f44c321c4013ccd247b3fa`. The
operator decided the fix on 2026-09-25.

1. **Backup block.** It exports `DATABASE_URL=$(grep DATABASE_URL .env.local | cut -d= -f2-)`.
   `.env.local` is a copy of the release's `.env.local.example`, which has comment lines that
   also contain `DATABASE_URL`, so the grep returns four lines and `pg_dump` gets unusable
   input. The restore block parses the same way.
2. **Restore block.** It runs `createdb forqsite` and passes `forqsite` as the expected
   database name, but `DATABASE_URL` still comes from the live `.env.local`. So it does not
   target the database its own comment names. A bare `createdb` also skips pgvector, which
   `docs/first-run.md` says a superuser must create.
3. **Cron line.** It sources `/etc/forqsite/env`, a file forqsite never defines. A plain `.`
   also does not export the values to `backup.sh`.

The operator's design stops parsing altogether. Each script runs under dotenv-cli, which
forqsite already ships: `package.json` lists `"dotenv-cli": "^11.0.0"`, and `start`,
`db:migrate` and about 30 other scripts use `dotenv -e .env.local --`. Sourcing the file
instead is unsafe: `.env.local.example` contains `PLATFORM_ADMIN_NAME=Dev Admin`.

## Requires

- CONTENT-033 is merged.
- A fetched forqsite clone contains the release commit and has its dependencies installed
  (`node_modules/.bin/dotenv` exists). Its path is passed on the command line as
  `FORQSITE_CLONE` and is never written into the repo.
- `python3 scripts/bundle-template.py verify index.html` passes.

## Ensures

Compared with `git merge-base HEAD main`, `gap-handoff.html` and
`docs/claims-manifest.json` are byte-identical, and every stamp in `index.html` is
unchanged. Every change to the extracted `index.html` template sits between the "1 —
Database backup" and "2 — Media backup" headings, or between the "Restore procedure" and
"Recovery scenarios" headings. The Tests script checks the three blocks by running them.
It finds each block by its script path, unescapes it, and runs it in a scratch checkout
built from the release's own `.env.local.example`, with stub scripts and a stale multi-line
`DATABASE_URL` already exported. The results must be exact:
- The backup block hands `backup.sh` exactly the example's `DATABASE_URL` and
  `/var/backups/forqsite`.
- The restore block hands `restore.sh` that URL, the file's encryption key under the legacy
  name, and `<dump> forqsite_dev`.
- The cron job, run the way cron runs it with `node` on its PATH, hands `backup.sh` the URL
  and its own `BACKUP_DEST_DIR`, and prunes old dumps there. Without `node` on its PATH it
  fails.

The negative controls hold:
- The old grep line yields a multi-line value.
- The unsubstituted restore line does not parse under `bash -n`.
- With `.env.local` removed, the real release `restore.sh` prints
  `ERROR: AI_CREDENTIAL_ENCRYPTION_KEY not set`, exits 1 and calls no `psql`, and the block
  stops there.

`createdb`, `cut -d=` and `/etc/forqsite/env` no longer appear in the three blocks. The
rendered `#backup` DOM, with `<script>` stripped first, shows the new block lines and the
three captions. `docs/cer/backlog.md` gains three Do Now rows, CER-041, CER-042 and CER-043,
each carrying `**RESOLVED Phase 12 — CONTENT-034.**`. Nothing else in the backlog changes.

Forbidden proxy:
- asserting the blocks by matching their text instead of executing them
- a flag, file or script name written from memory instead of from the release commit or
  `dotenv --help` in the clone

## Instructions

1. **Workflow.** Follow `docs/architecture.md` § Editing procedure: `verify`, then `extract`
   into a scratch directory outside the repo, edit only there, then `inject` and `verify`.
2. **Backup block.** Use the operator's text. HTML-escape it inside the `<pre>`, and keep the
   leading U+200B if the block starts with a comment, as the others do:
   ```
   # run from the forqsite checkout the app runs from — values come from its .env.local
   export BACKUP_DEST_DIR=/var/backups/forqsite
   export BACKUP_S3_TARGET=myminio/backups/forqsite   # optional offsite mirror of the dump dir
   pnpm exec dotenv -o -e .env.local -- scripts/backup.sh   # → forqsite_YYYYMMDD_HHMMSS.sql.gz
   ```
   Add to the caption below it: `dotenv -e .env.local` is the loader that forqsite's own
   `pnpm start` and `pnpm db:migrate` use, so the dump comes from the database the app runs
   against. `-o` makes the file win over anything already exported in the shell. If the
   values live in a process manager instead, export `DATABASE_URL` from there. Keep the
   caption's existing sentences. The "never on the command line" sentence is CONTENT-035's.
3. **Cron block.** Keep the `/etc/cron.d/forqsite-backup` comment line. Replace the job with
   cron.d variable lines and one job. `BACKUP_DEST_DIR=/var/backups/forqsite` is needed
   because `backup.sh` and the `find` prune both read it from cron's environment, not from
   dotenv. Use a `PATH=` line if you choose. Write the job as
   `15 2 * * * forqsite cd /opt/forqsite && node_modules/.bin/dotenv -o -e .env.local -- scripts/backup.sh && find "$BACKUP_DEST_DIR" …`.
   `/opt/forqsite` matches the systemd units' `WorkingDirectory`. Use no `%`, because cron
   turns it into a newline. State the assumption on the page, in a comment or the caption:
   `node_modules/.bin/dotenv` is a shell shim that runs `node` from `PATH`, so cron's `PATH`
   must reach `node`. Claim nothing beyond what the Tests script runs.
4. **Restore block.** Use the operator's text. Escape `<target-database-name>` and
   `<media-bucket>` as `&lt;…&gt;`:
   ```
   # run from the checkout whose .env.local names the database you are restoring INTO:
   #   rehearsal — a second checkout whose .env.local points at a spare database
   #   disaster recovery — the production checkout, once its database is recreated empty
   # the target must be empty (restore.sh drops nothing) with pgvector already created by a superuser
   # key first — the script refuses to run without it (legacy var name, see GAP-008)
   export AI_CREDENTIAL_ENCRYPTION_KEY="$(pnpm exec dotenv -o -e .env.local -p FORQSITE_CREDENTIALS_ENCRYPTION_KEY)"
   # usage: scripts/restore.sh <backup-file.sql.gz> <expected-database-name> — refuses unless DATABASE_URL resolves to that database
   pnpm exec dotenv -o -e .env.local -- scripts/restore.sh /var/backups/forqsite/forqsite_20260101_120000.sql.gz <target-database-name>
   # prints row counts: organisations / tenants / pages / blocks — sanity-check them
   mc mirror --overwrite /var/backups/forqsite/media/ myminio/<media-bucket>   # media back — disaster recovery only; in a rehearsal mirror into a spare bucket
   ```
   Below the block's container, add a caption `<div>` in the page's caption style. It says:
   - You choose the target by choosing the checkout. `restore.sh` writes to whatever
     database that checkout's `.env.local` names in `DATABASE_URL`, and the typed name must
     match it.
   - For a rehearsal, copy `.env.local` into the second checkout and change only
     `DATABASE_URL`. The encryption key must stay the production one, or restored AI
     credentials will not decrypt.
   - A failed restore stops at the first error and leaves a partial database, so drop and
     recreate the target before retrying.

   Check each fact against the script at the release commit (`ON_ERROR_STOP=1`, the
   `current_database()` check). In your report, list every line you removed from the old
   block and say why. The old first comment and `createdb` are replaced by design.
5. **Backlog.** Add CER-041 to CER-043 to Do Now, directly below CER-040. The Date is
   `2026-09-25` and the Phase is `12`. Each row states the stale text, the release-commit
   fact and the fix, and ends with `**RESOLVED Phase 12 — CONTENT-034.**`:
   - CER-041: the grep parsing. Source `security-auditor (CP-12)`.
   - CER-042: the restore target. Source `cold-eyes triage (CP-12)`.
   - CER-043: the cron line. Source `CONTENT-034 design`.

   If those IDs are taken when you build, use the next free ones and say so. Name no host,
   directory or URL of ours.
6. **No manifest or stamp change.** The Backup & recovery route is unstamped
   (CONTENT-030: stamped claims only).

Ideology: the blocks now call forqsite's own loader and cite its own files ("Cite the source
that makes a claim checkable"). The Tests script runs the blocks instead of reading them
("Assert the invariant, not a proxy for it"). The bundle changes only through
`bundle-template.py` (Generated-artifact discipline). `/opt/forqsite` and
`/var/backups/forqsite` are the page's existing example paths for the reader's own install,
not ours.

Preflight notes: `docs/claims-manifest.json` and `gap-handoff.html` are named only to
assert that they do not change. The upper-case names the preflight flags (`DATABASE_URL`,
`BACKUP_DEST_DIR`, `BACKUP_S3_TARGET`, the two key names) are forqsite environment variables,
and `GAP`/`INTO` are page text, not constants in this repo. Length: this spec runs past the ~100-line guideline because
the Tests script is the executable proof the operator asked for. It was dry-run against a
scratch copy carrying the design text.

## Tests

The project has no test suite. The reviewer's Bash guard blocks typed `git show`/`git grep`.
Save this block to a scratch file outside the repo, then run it from the repo root with
`FORQSITE_CLONE=<clone path> bash <file>`. It uses `pnpm exec` if `pnpm` is on `PATH`. If it
is not, the script falls back to `node_modules/.bin/dotenv` and prints a `NOTE:` saying so.

```bash
set -e
: "${FORQSITE_CLONE:?set FORQSITE_CLONE to the local forqsite clone}"
S=$(mktemp -d); BASE=$(git merge-base HEAD main)
git diff --quiet $BASE -- gap-handoff.html docs/claims-manifest.json
python3 scripts/bundle-template.py verify index.html
python3 scripts/bundle-template.py extract index.html $S/new.html
git show $BASE:index.html > $S/base-bundle.html
python3 scripts/bundle-template.py extract $S/base-bundle.html $S/base.html
for f in new base; do grep -oE 'nullvalues/forqsite@[0-9a-f]{7,40}' $S/$f.html > $S/$f.stamps; done
cmp $S/new.stamps $S/base.stamps
python3 -c "import re; [open(f'$S/s{i}.js','w').write(b) for i,b in enumerate(re.findall(r'<script type=\"text/x-dc\"[^>]*>(.*?)</script>', open('$S/new.html').read(), re.S))]"
for f in $S/s*.js; do node --check $f; done
timeout 60 chromium --headless --disable-gpu --no-sandbox --virtual-time-budget=5000 --dump-dom "file://$PWD/index.html#backup" > $S/dom-backup 2>/dev/null
git diff -U0 $BASE -- docs/cer/backlog.md > $S/backlog.diff
python3 - "$S" <<'EOF'
import difflib, html, os, re, shutil, subprocess, sys, time
S = sys.argv[1]; clone = os.environ['FORQSITE_CLONE']
REL = '1fda3228322d5ad779f44c321c4013ccd247b3fa'
URL = 'postgresql://forqsite:changeme@127.0.0.1:5432/forqsite_dev'; KEY = 'k3y+/=Z'
def git(*a): return subprocess.run(['git', '-C', clone, *a], capture_output=True, text=True)
for path, lit in [('package.json', '"dotenv-cli": "^11.0.0"'), ('package.json', '"start": "dotenv -e .env.local -- next start'),
                  ('package.json', '"db:migrate": "dotenv -e .env.local -- drizzle-kit migrate"'),
                  ('.env.local.example', 'DATABASE_URL=' + URL), ('.env.local.example', 'PLATFORM_ADMIN_NAME=Dev Admin'),
                  ('scripts/restore.sh', 'Usage: scripts/restore.sh <backup-file.sql.gz> <expected-database-name>'),
                  ('scripts/restore.sh', 'echo "ERROR: AI_CREDENTIAL_ENCRYPTION_KEY not set.'),
                  ('docs/first-run.md', 'and created by a superuser')]:
    assert git('grep', '-q', '-F', '-e', lit, REL, '--', path).returncode == 0, f'{lit!r} not in {path} at release'
assert os.path.exists(f'{clone}/node_modules/.bin/dotenv'), 'the clone has no installed dotenv-cli'
# 1. scope: every change sits inside the backup+cron section or the restore section of the base template
B = open(f'{S}/base.html').read().splitlines(True); N = open(f'{S}/new.html').read().splitlines(True)
def at(lines, s):
    i = [k for k, l in enumerate(lines) if s in l]; assert len(i) == 1, f'anchor {s!r}: {len(i)} hits'; return i[0]
R = [(at(B, '>1 — Database backup</h2>'), at(B, '>2 — Media backup')), (at(B, '>Restore procedure</h2>'), at(B, '>Recovery scenarios</h2>'))]
for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, B, N, autojunk=False).get_opcodes():
    if tag != 'equal': assert any(s < i1 <= e and i2 <= e for s, e in R), f'change outside the two passages at base lines {i1}-{i2}'
# 2. the three blocks, anchored on the script path
pres = [html.unescape(p).replace('\u200b', '') for p in re.findall(r'<pre\b[^>]*>(.*?)</pre>', ''.join(N), re.S)]
def one(f, what):
    x = [p for p in pres if f(p)]; assert len(x) == 1, f'{what}: {len(x)} blocks'; return x[0]
cron = one(lambda p: '/etc/cron.d/forqsite-backup' in p, 'cron')
bk = one(lambda p: 'scripts/backup.sh' in p and '/etc/cron.d/' not in p, 'backup')
rs = one(lambda p: 'scripts/restore.sh' in p, 'restore')
for blk in (bk, cron, rs): assert 'cut -d=' not in blk and '/etc/forqsite/env' not in blk, 'old env parsing left in a block'
assert 'createdb' not in rs, 'createdb still in the restore block'
# 3. harness: the release's own .env.local.example, a known key, stub scripts, the clone's dotenv-cli
T = f'{S}/run'
for d in ('scripts', 'bin', 'backups'): os.makedirs(f'{T}/{d}')
env_src = git('show', f'{REL}:.env.local.example').stdout
env_file = re.sub(r'(?m)^FORQSITE_CREDENTIALS_ENCRYPTION_KEY=.*$', 'FORQSITE_CREDENTIALS_ENCRYPTION_KEY=' + KEY, env_src)
assert env_file != env_src; open(f'{T}/.env.local', 'w').write(env_file)
os.symlink(f'{clone}/node_modules', f'{T}/node_modules'); open(f'{T}/package.json', 'w').write('{"name":"t","private":true}\n')
def stub(name, body): open(name, 'w').write('#!/bin/sh\n' + body + '\n'); os.chmod(name, 0o755)
for s in ('backup', 'restore'):
    stub(f'{T}/scripts/{s}.sh', f'printf "%s|%s|%s|%s\\n" "$DATABASE_URL" "$AI_CREDENTIAL_ENCRYPTION_KEY" "$BACKUP_DEST_DIR" "$*" >> {T}/rec.{s}')
stub(f'{T}/bin/mc', f'echo mc >> {T}/mc.calls'); stub(f'{T}/bin/psql', f'echo psql >> {T}/psql.calls')
base_env = {k: v for k, v in os.environ.items() if not k.startswith(('BACKUP_', 'AI_CREDENTIAL', 'FORQSITE_CRED', 'DATABASE_URL'))}
base_env['PATH'] = f'{T}/bin:' + base_env['PATH']
if not shutil.which('pnpm', path=base_env['PATH']):
    print('NOTE: pnpm unavailable; blocks run with node_modules/.bin/dotenv in place of pnpm exec dotenv')
    bk, rs = (b.replace('pnpm exec dotenv', 'node_modules/.bin/dotenv') for b in (bk, rs))
def run(block):
    return subprocess.run(['bash', '-e', '-c', block], cwd=T, env=dict(base_env, DATABASE_URL='stale\nvalue'), capture_output=True, text=True)
def rec(s): return open(f'{T}/rec.{s}').read().splitlines() if os.path.exists(f'{T}/rec.{s}') else []
# 4. backup block, with a stale multi-line DATABASE_URL already exported
p = run(bk); assert p.returncode == 0, p.stderr
assert rec('backup') == [f'{URL}||/var/backups/forqsite|'], rec('backup')
# 5. restore block, placeholders substituted
inv = [l for l in rs.splitlines() if 'scripts/restore.sh ' in l and not l.lstrip().startswith('#')]
assert len(inv) == 1, 'restore invocation count'
assert subprocess.run(['bash', '-n', '-c', inv[0]], capture_output=True).returncode != 0, 'unsubstituted placeholder line parses'
run_rs = rs.replace('<target-database-name>', 'forqsite_dev').replace('<media-bucket>', 'spare')
assert subprocess.run(['bash', '-n', '-c', run_rs]).returncode == 0, 'restore block does not parse after substitution'
dump = [w for w in inv[0].split() if w.endswith('.sql.gz')]; assert len(dump) == 1
p = run(run_rs); assert p.returncode == 0, p.stderr
assert rec('restore') == [f'{URL}|{KEY}||{dump[0]} forqsite_dev'], rec('restore')
assert os.path.exists(f'{T}/mc.calls'), 'the media line did not run'
os.remove(f'{T}/mc.calls')
# 6. negative controls
p = subprocess.run(['bash', '-c', 'grep DATABASE_URL .env.local | cut -d= -f2-'], cwd=T, capture_output=True, text=True)
assert '\n' in p.stdout.strip(), 'the old grep line no longer yields a multi-line value'
open(f'{T}/scripts/restore.sh', 'w').write(git('show', f'{REL}:scripts/restore.sh').stdout)
os.rename(f'{T}/.env.local', f'{T}/env.saved')
p = run(run_rs)
assert p.returncode == 1 and 'ERROR: AI_CREDENTIAL_ENCRYPTION_KEY not set' in p.stdout, (p.returncode, p.stdout)
assert not os.path.exists(f'{T}/psql.calls') and not os.path.exists(f'{T}/mc.calls'), 'the block ran on past a refused restore'
os.rename(f'{T}/env.saved', f'{T}/.env.local')
# 7. cron: the file's variable lines and its one job, run as cron runs it (sh -c, cron's environment)
lines = [l for l in cron.splitlines() if l.strip() and not l.lstrip().startswith('#')]
job = [l for l in lines if not re.match(r'[A-Za-z_]+=', l)]
assert len(job) == 1, 'cron job line count'
cmd = job[0].split(None, 6)[6]
assert '%' not in cmd, 'cron turns % into a newline'
cd = re.match(r'cd (\S+) && ', cmd); assert cd, 'the job does not cd into the checkout'
cvars = dict(l.split('=', 1) for l in lines if l not in job)
assert cvars.get('BACKUP_DEST_DIR'), 'BACKUP_DEST_DIR is not set in the cron file'
cmd = cmd.replace(cd.group(1), T, 1)
old, new = f'{T}/backups/forqsite_20000101_000000.sql.gz', f'{T}/backups/forqsite_29990101_000000.sql.gz'
for x in (old, new): open(x, 'w').close()
os.utime(old, (time.time() - 20 * 86400,) * 2)
cenv = {'HOME': T, 'SHELL': '/bin/sh', 'BACKUP_DEST_DIR': f'{T}/backups'}
p = subprocess.run(['/bin/sh', '-c', cmd], env=dict(cenv, PATH=os.path.dirname(shutil.which('node')) + ':/usr/bin:/bin'), capture_output=True, text=True)
assert p.returncode == 0, p.stderr
assert rec('backup')[-1] == f'{URL}||{T}/backups|', rec('backup')
assert not os.path.exists(old) and os.path.exists(new), 'the prune step did not see BACKUP_DEST_DIR'
nonode = f'{S}/nonode'; os.makedirs(nonode)
for tool in ('sh', 'sed', 'dirname', 'uname', 'find'): os.symlink(shutil.which(tool), f'{nonode}/{tool}')
n = len(rec('backup'))
p = subprocess.run(['/bin/sh', '-c', cmd], env=dict(cenv, PATH=nonode), capture_output=True, text=True)
assert p.returncode != 0 and len(rec('backup')) == n, 'the job ran without node on its PATH'
# 8. rendered DOM of #backup, <script> stripped first (CER-005, CER-012)
flat = html.unescape(re.sub(r'<[^>]+>', '', re.sub(r'(?is)<script\b.*?</script>', '', open(f'{S}/dom-backup').read()))).replace('\u200b', '')
for blk in (b for b in pres if 'scripts/backup.sh' in b or 'scripts/restore.sh' in b):
    for l in blk.splitlines():
        if l.strip(): assert l.strip() in flat, f'not rendered: {l[:70]}'
assert 'cut -d=' not in flat and 'createdb' not in flat, 'old text still rendered'
between = lambda x, y: flat.split(x, 1)[1].split(y, 1)[0]
assert 'dotenv -e .env.local' in between('forqsite_YYYYMMDD_HHMMSS.sql.gz', 'Schedule it'), 'backup caption does not name the loader'
cz = between('/etc/cron.d/forqsite-backup', '2 — Media backup'); assert 'PATH' in cz and 'node' in cz, 'cron caveat missing'
assert 'DATABASE_URL' in between('mc mirror --overwrite /var/backups', 'Recovery scenarios'), 'restore sentence missing'
# 9. backlog: three new Do Now rows, nothing else
d = open(f'{S}/backlog.diff').read().splitlines()
minus = [l for l in d if l.startswith('-') and not l.startswith('---')]
plus = [l for l in d if l.startswith('+') and not l.startswith('+++')]
assert not minus and len(plus) == 3, 'backlog changed beyond three added rows'
row = {l[1:].split('|')[1].strip(): l for l in plus}
for i, src in (('CER-041', 'security-auditor (CP-12)'), ('CER-042', 'cold-eyes triage (CP-12)'), ('CER-043', 'CONTENT-034 design')):
    r = row[i]; assert '**RESOLVED Phase 12 — CONTENT-034.**' in r and f'| {src} |' in r and r.rstrip().endswith('| 12 |'), i
bl = open('docs/cer/backlog.md').read()
assert bl.index('| CER-043 ') < bl.index('## Do Later'), 'rows not in Do Now'
for l in plus + [l for l in N if l not in B]:
    assert not re.search(r'/mnt/|/home/|~/(?!\.pgpass)', l) and clone not in l, f'host path in added line: {l[:80]}'
print('OK')
EOF
```

Pass means the script prints `OK` and exits 0. The reviewer also reads the three blocks and
the captions against the clone at the release commit. The prose must say what the scripts
do, not just contain the checked words. If the builder used IDs other than CER-041 to
CER-043, the reviewer changes those IDs in the check to match.

## Out of scope

- The "Passwords come via PGPASSWORD/~/.pgpass, never on the command line" sentence, and
  new GAP entries for the upstream runbook and `backup.sh` defects. Both belong to
  CONTENT-035.
- The Process supervision route's systemd units, which keep
  `EnvironmentFile=/etc/forqsite/env`.
- The Media backup block, the Recovery scenarios table, the drill, and any stamp or
  manifest change.
- Whether a restore run by a non-superuser stops on pgvector's extension comment. That is
  untested and is filed as a Do Later row by CONTENT-036.
- Deploy. The post-merge step in CONTENT-032 covers it, and it runs after CONTENT-036
  merges.
