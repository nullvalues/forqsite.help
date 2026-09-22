#!/usr/bin/env bash
#
# deploy-selftest.sh — exercises scripts/deploy.sh's refusals and happy path against a
# throwaway fixture git repository and a throwaway fixture "remote" directory, using a
# stub `ssh` placed first on PATH. The stub runs the remote command under `dash` (a
# real POSIX sh, not bash) so that any bash-only quoting the remote command relies on
# is exposed rather than silently passing (CER-025). Contacts no real host.
#
# Cases (see docs/stories/INFRA/INFRA-006.md § Tests, INFRA-011 for 6-7, INFRA-012 for 8-12):
#   1. missing config   — exit 2, message names both variable names, stub-ssh not invoked
#   2. dirty tree       — exit 3, message names the dirty bundle, target files untouched
#   3. happy path       — exit 0, target files match committed bytes, two .bak-<stamp>
#                          files sharing one stamp, success block printed
#   4. hash mismatch    — stub ssh corrupts the file after the copy step, exit 4, message
#                          names the failing bundle
#   5. dry run          — exit 0, stub-ssh marker file absent (no ssh invoked at all)
#   6. hostile alias    — exit 2, no ssh invoked, no local command execution, value not
#                          printed; repeated with --dry-run and with an alias containing
#                          a space (CER-019)
#   7. POSIX quoting    — remote directory name containing a space, a single quote and a
#                          tab; exit 0, bytes match, under the dash-backed stub ssh (CER-025)
#   8. staging symlinks — symlinks to a sentinel at every old-scheme stage name for the
#                          run's window: exit 0, bytes match, sentinel unchanged, no stage
#                          left; symlinks at index.html.bak-<S>: exit 5, sentinel unchanged
#                          (INFRA-012, CER-023)
#   9. first-write mode — under umask 077, files that did not exist are created 0644; an
#                          existing file keeps its inode and its 0640 mode (INFRA-012)
#  10. retention        — six past and BACKUP_KEEP future-dated verified sets, one
#                          unverified set, one malformed marker: exit 0, current set kept,
#                          exactly BACKUP_KEEP pattern markers, pruned sets gone,
#                          unverified set and malformed marker untouched (CER-027)
#  11. partial prune    — the second of two prune removals fails: exit 5, report names the
#                          first stamp as pruned and the second as failed (INFRA-012)
#  12. no prune on fail — hash-mismatch run over seeded sets: exit 4, nothing deleted, no
#                          marker written (INFRA-012)
#
# Exits non-zero if any case fails.

set -euo pipefail

if ! command -v dash >/dev/null 2>&1; then
  echo "deploy-selftest: dash is required (used as the stub remote shell) but not found on PATH" >&2
  exit 1
fi

REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
DEPLOY_SH="$REPO_ROOT/scripts/deploy.sh"

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

FIXTURE_REPO="$WORK_DIR/fixture-repo"
FIXTURE_TARGET="$WORK_DIR/fixture-target"
STUB_BIN="$WORK_DIR/stub-bin"
SSH_MARKER="$WORK_DIR/ssh-marker"
CORRUPT_FLAG="$WORK_DIR/corrupt-flag"

FAILURES=0
PASS_COUNT=0

report() {
  local name="$1" ok="$2" detail="$3"
  if [ "$ok" -eq 0 ]; then
    echo "PASS: $name"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL: $name — $detail"
    FAILURES=$((FAILURES + 1))
  fi
}

# --- Build fixture repo -------------------------------------------------------------
mkdir -p "$FIXTURE_REPO"
git -C "$FIXTURE_REPO" init -q
git -C "$FIXTURE_REPO" config user.email "selftest@example.invalid"
git -C "$FIXTURE_REPO" config user.name "deploy-selftest"
echo "fixture index bundle" > "$FIXTURE_REPO/index.html"
echo "fixture gap-handoff bundle" > "$FIXTURE_REPO/gap-handoff.html"
git -C "$FIXTURE_REPO" add index.html gap-handoff.html
git -C "$FIXTURE_REPO" commit -q -m "fixture: initial bundles"

# --- Build fixture "remote" target directory ----------------------------------------
mkdir -p "$FIXTURE_TARGET"

# --- Build stub ssh, first on PATH ---------------------------------------------------
mkdir -p "$STUB_BIN"
cat > "$STUB_BIN/ssh" <<STUB
#!/usr/bin/env bash
# Stub ssh for deploy-selftest.sh: ignores its first argument (the host alias) and
# runs the remainder of its arguments with dash -c (a real POSIX sh, not bash)
# against the fixture target directory, recording that it was invoked. Running under
# dash rather than bash is deliberate (CER-025): bash's \$'...' quoting only works
# under bash, and running the stub under bash would let that bash-only quoting pass
# even though the far account's login shell may be POSIX sh.
echo "invoked" >> "$SSH_MARKER"
shift
cmd="\$1"
out="\$(dash -c "\$cmd")"
status=\$?
case "\$cmd" in
  *"cat >"*)
    if [ -f "$CORRUPT_FLAG" ] && [ -f "$FIXTURE_TARGET/index.html" ]; then
      echo "corrupted" > "$FIXTURE_TARGET/index.html"
    fi
    ;;
esac
printf '%s\n' "\$out"
exit "\$status"
STUB
chmod +x "$STUB_BIN/ssh"

export PATH="$STUB_BIN:$PATH"
export FORQSITE_HELP_DEPLOY_DIR="$FIXTURE_TARGET"

run_deploy() {
  ( cd "$FIXTURE_REPO" && "$DEPLOY_SH" "$@" )
}

# =====================================================================================
# Case 1: missing config
# =====================================================================================
rm -f "$SSH_MARKER"
unset FORQSITE_HELP_DEPLOY_HOST || true
unset FORQSITE_HELP_DEPLOY_DIR || true
rm -f "$FIXTURE_REPO/scripts/deploy.env" 2>/dev/null || true

set +e
out_case1="$(run_deploy 2>&1)"
status_case1=$?
set -e

ok=0
detail=""
if [ "$status_case1" -ne 2 ]; then
  ok=1; detail="expected exit 2, got $status_case1"
elif ! printf '%s' "$out_case1" | grep -q "FORQSITE_HELP_DEPLOY_HOST"; then
  ok=1; detail="message did not name FORQSITE_HELP_DEPLOY_HOST"
elif ! printf '%s' "$out_case1" | grep -q "FORQSITE_HELP_DEPLOY_DIR"; then
  ok=1; detail="message did not name FORQSITE_HELP_DEPLOY_DIR"
elif [ -f "$SSH_MARKER" ]; then
  ok=1; detail="stub-ssh marker file present — ssh was invoked"
fi
report "missing config (exit 2, names both variables, no ssh)" "$ok" "$detail"

# Restore config for the remaining cases.
export FORQSITE_HELP_DEPLOY_HOST="fixture-host-alias"
export FORQSITE_HELP_DEPLOY_DIR="$FIXTURE_TARGET"

# =====================================================================================
# Case 6: hostile alias (CER-019) — a value beginning with "-" must never reach ssh.
# HOSTILE_MARKER stands in for the local command execution ssh's own option parser
# would perform (e.g. -oProxyCommand=touch <marker>) if the raw value were ever
# passed to a real ssh unvalidated; deploy.sh must refuse before invoking ssh (stub
# or real) at all, so HOSTILE_MARKER must never be created here either.
# =====================================================================================
HOSTILE_MARKER="$WORK_DIR/hostile-marker"

check_hostile_alias() {
  local name="$1" status="$2" out="$3" value="$4"
  local ok=0 detail=""
  if [ "$status" -ne 2 ]; then
    ok=1; detail="expected exit 2, got $status"
  elif [ -f "$SSH_MARKER" ]; then
    ok=1; detail="stub-ssh marker present — ssh was invoked"
  elif [ -f "$HOSTILE_MARKER" ]; then
    ok=1; detail="hostile marker file created — value was executed"
  elif printf '%s' "$out" | grep -F -- "$value" >/dev/null; then
    ok=1; detail="output contains the value"
  fi
  report "$name" "$ok" "$detail"
}

rm -f "$SSH_MARKER" "$HOSTILE_MARKER"
export FORQSITE_HELP_DEPLOY_HOST="-oProxyCommand=touch $HOSTILE_MARKER"
set +e
out_hostile="$(run_deploy 2>&1)"
status_hostile=$?
set -e
check_hostile_alias "hostile alias (exit 2, no ssh, no marker, value not printed)" "$status_hostile" "$out_hostile" "$FORQSITE_HELP_DEPLOY_HOST"

rm -f "$SSH_MARKER" "$HOSTILE_MARKER"
set +e
out_hostile_dry="$(run_deploy --dry-run 2>&1)"
status_hostile_dry=$?
set -e
check_hostile_alias "hostile alias with --dry-run (exit 2, no ssh, no marker, value not printed)" "$status_hostile_dry" "$out_hostile_dry" "$FORQSITE_HELP_DEPLOY_HOST"

rm -f "$SSH_MARKER" "$HOSTILE_MARKER"
export FORQSITE_HELP_DEPLOY_HOST="fixture alias with space"
set +e
out_hostile_space="$(run_deploy 2>&1)"
status_hostile_space=$?
set -e
check_hostile_alias "alias containing a space (exit 2, no ssh, no marker, value not printed)" "$status_hostile_space" "$out_hostile_space" "$FORQSITE_HELP_DEPLOY_HOST"

# Restore a valid alias for the remaining cases.
export FORQSITE_HELP_DEPLOY_HOST="fixture-host-alias"
rm -f "$SSH_MARKER" "$HOSTILE_MARKER"

# =====================================================================================
# Case 2: dirty tree
# =====================================================================================
rm -f "$SSH_MARKER"
echo "x" >> "$FIXTURE_REPO/index.html"

before_index_sha="$(sha256sum "$FIXTURE_TARGET/index.html" 2>/dev/null || true)"
before_gap_sha="$(sha256sum "$FIXTURE_TARGET/gap-handoff.html" 2>/dev/null || true)"

set +e
out_case2="$(run_deploy 2>&1)"
status_case2=$?
set -e

after_index_sha="$(sha256sum "$FIXTURE_TARGET/index.html" 2>/dev/null || true)"
after_gap_sha="$(sha256sum "$FIXTURE_TARGET/gap-handoff.html" 2>/dev/null || true)"

ok=0
detail=""
if [ "$status_case2" -ne 3 ]; then
  ok=1; detail="expected exit 3, got $status_case2"
elif ! printf '%s' "$out_case2" | grep -q "index.html"; then
  ok=1; detail="message did not name index.html as dirty"
elif [ -f "$SSH_MARKER" ]; then
  ok=1; detail="stub-ssh marker file present — ssh was invoked before the dirty refusal"
elif [ "$before_index_sha" != "$after_index_sha" ] || [ "$before_gap_sha" != "$after_gap_sha" ]; then
  ok=1; detail="fixture target files changed despite the refusal"
fi
report "dirty tree (exit 3, names bundle, target untouched)" "$ok" "$detail"

# Revert the dirtying edit.
git -C "$FIXTURE_REPO" checkout -q -- index.html

# =====================================================================================
# Case 3: happy path
# =====================================================================================
rm -f "$SSH_MARKER"
rm -f "$FIXTURE_TARGET"/*.bak-* 2>/dev/null || true
# Pre-populate the fixture target with stand-in "live" bundles so the deploy has an
# existing file to back up (matching a real target, which is never empty).
echo "pre-existing live index bundle" > "$FIXTURE_TARGET/index.html"
echo "pre-existing live gap-handoff bundle" > "$FIXTURE_TARGET/gap-handoff.html"

set +e
out_case3="$(run_deploy 2>&1)"
status_case3=$?
set -e

committed_index_sha="$(git -C "$FIXTURE_REPO" show HEAD:index.html | sha256sum | cut -d' ' -f1)"
committed_gap_sha="$(git -C "$FIXTURE_REPO" show HEAD:gap-handoff.html | sha256sum | cut -d' ' -f1)"
target_index_sha="$(sha256sum "$FIXTURE_TARGET/index.html" | cut -d' ' -f1)"
target_gap_sha="$(sha256sum "$FIXTURE_TARGET/gap-handoff.html" | cut -d' ' -f1)"

bak_index=$(ls "$FIXTURE_TARGET"/index.html.bak-* 2>/dev/null || true)
bak_gap=$(ls "$FIXTURE_TARGET"/gap-handoff.html.bak-* 2>/dev/null || true)

ok=0
detail=""
if [ "$status_case3" -ne 0 ]; then
  ok=1; detail="expected exit 0, got $status_case3: $out_case3"
elif [ "$committed_index_sha" != "$target_index_sha" ]; then
  ok=1; detail="target index.html does not match committed bytes"
elif [ "$committed_gap_sha" != "$target_gap_sha" ]; then
  ok=1; detail="target gap-handoff.html does not match committed bytes"
elif [ -z "$bak_index" ] || [ -z "$bak_gap" ]; then
  ok=1; detail="expected .bak-<stamp> files not found"
else
  stamp_index="${bak_index##*.bak-}"
  stamp_gap="${bak_gap##*.bak-}"
  if [ "$stamp_index" != "$stamp_gap" ]; then
    ok=1; detail="backup stamps differ: $stamp_index vs $stamp_gap"
  elif ! printf '%s' "$out_case3" | grep -q "^deployed"; then
    ok=1; detail="success block not printed"
  fi
fi
report "happy path (exit 0, bytes match, shared stamp, success block)" "$ok" "$detail"

# Forbidden-proxy check: neither the fixture host alias nor the fixture target
# directory path may appear anywhere in the captured happy-path output.
ok=0
detail=""
if printf '%s' "$out_case3" | grep -F "$FORQSITE_HELP_DEPLOY_HOST" >/dev/null; then
  ok=1; detail="fixture host alias leaked into success output"
elif printf '%s' "$out_case3" | grep -F "$FIXTURE_TARGET" >/dev/null; then
  ok=1; detail="fixture target directory path leaked into success output"
fi
report "happy path output names no configuration value" "$ok" "$detail"

# =====================================================================================
# Case 7: POSIX quoting — remote directory name with a space, a single quote and a
# tab. Every value spliced into a remote command string must round-trip exactly
# under a real POSIX sh (dash), not just under bash's own $'...' quoting (CER-025).
# =====================================================================================
ODD_DIR_NAME="odd target $(printf '\047')quote$(printf '\t')tab"
FIXTURE_ODD_TARGET="$WORK_DIR/$ODD_DIR_NAME"
mkdir -p "$FIXTURE_ODD_TARGET"
echo "pre-existing live index bundle" > "$FIXTURE_ODD_TARGET/index.html"
echo "pre-existing live gap-handoff bundle" > "$FIXTURE_ODD_TARGET/gap-handoff.html"

rm -f "$SSH_MARKER"
export FORQSITE_HELP_DEPLOY_DIR="$FIXTURE_ODD_TARGET"

set +e
out_odd="$(run_deploy 2>&1)"
status_odd=$?
set -e

target_odd_index_sha="$(sha256sum "$FIXTURE_ODD_TARGET/index.html" 2>/dev/null | cut -d' ' -f1 || true)"
target_odd_gap_sha="$(sha256sum "$FIXTURE_ODD_TARGET/gap-handoff.html" 2>/dev/null | cut -d' ' -f1 || true)"

ok=0
detail=""
if [ "$status_odd" -ne 0 ]; then
  ok=1; detail="expected exit 0, got $status_odd: $out_odd"
elif [ "$committed_index_sha" != "$target_odd_index_sha" ]; then
  ok=1; detail="target index.html (odd dir) does not match committed bytes"
elif [ "$committed_gap_sha" != "$target_odd_gap_sha" ]; then
  ok=1; detail="target gap-handoff.html (odd dir) does not match committed bytes"
fi
report "POSIX quoting (dir name with space, quote and tab; exit 0, bytes match)" "$ok" "$detail"

# Restore the plain fixture target for the remaining cases.
export FORQSITE_HELP_DEPLOY_DIR="$FIXTURE_TARGET"
rm -f "$SSH_MARKER"

# =====================================================================================
# Case 4: hash mismatch
# =====================================================================================
rm -f "$SSH_MARKER"
rm -f "$FIXTURE_TARGET"/*.bak-* 2>/dev/null || true
: > "$CORRUPT_FLAG"

set +e
out_case4="$(run_deploy 2>&1)"
status_case4=$?
set -e

rm -f "$CORRUPT_FLAG"

ok=0
detail=""
if [ "$status_case4" -ne 4 ]; then
  ok=1; detail="expected exit 4, got $status_case4: $out_case4"
elif ! printf '%s' "$out_case4" | grep -q "index.html"; then
  ok=1; detail="message did not name index.html as the failing bundle"
fi
report "hash mismatch (exit 4, names failing bundle)" "$ok" "$detail"

# Restore the fixture target to a clean, matching state for the next case.
git -C "$FIXTURE_REPO" show HEAD:index.html > "$FIXTURE_TARGET/index.html"
git -C "$FIXTURE_REPO" show HEAD:gap-handoff.html > "$FIXTURE_TARGET/gap-handoff.html"
rm -f "$FIXTURE_TARGET"/*.bak-* 2>/dev/null || true

# =====================================================================================
# Case 5: dry run
# =====================================================================================
rm -f "$SSH_MARKER"

set +e
out_case5="$(run_deploy --dry-run 2>&1)"
status_case5=$?
set -e

ok=0
detail=""
if [ "$status_case5" -ne 0 ]; then
  ok=1; detail="expected exit 0, got $status_case5: $out_case5"
elif [ -f "$SSH_MARKER" ]; then
  ok=1; detail="stub-ssh marker file present — ssh was invoked during a dry run"
fi
report "dry run (exit 0, no ssh invoked)" "$ok" "$detail"

# =====================================================================================
# Shared helpers for the staging, backup and retention cases (INFRA-012).
# =====================================================================================
BACKUP_KEEP="$(sed -n 's/^BACKUP_KEEP=\([0-9][0-9]*\)$/\1/p' "$DEPLOY_SH" | head -n 1)"
if [ -z "$BACKUP_KEEP" ]; then
  echo "deploy-selftest: could not read BACKUP_KEEP from deploy.sh" >&2
  exit 1
fi
STAMP_RE='^[0-9]{8}T[0-9]{6}Z$'
SET_FILES=(index.html gap-handoff.html site-provenance.json)
SENTINEL="$WORK_DIR/sentinel"
SENTINEL_BYTES="sentinel — must never be written through"

stamp_at() { date -u -d "@$1" +%Y%m%dT%H%M%SZ; }

reset_sentinel() { printf '%s\n' "$SENTINEL_BYTES" > "$SENTINEL"; }
sentinel_intact() { [ "$(cat "$SENTINEL")" = "$SENTINEL_BYTES" ]; }

# A fresh target directory holding stand-in live bundles and a live sidecar.
fresh_target() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  echo "pre-existing live index bundle" > "$dir/index.html"
  echo "pre-existing live gap-handoff bundle" > "$dir/gap-handoff.html"
  echo '{"pre-existing": "live sidecar"}' > "$dir/site-provenance.json"
}

stamp_from_output() { printf '%s\n' "$1" | sed -n 's/^stamp[[:space:]]*//p' | head -n 1; }

# Seeds one backup set (three .bak-<stamp> files), with a marker when $3 is "verified".
seed_set() {
  local dir="$1" s="$2" kind="$3" n
  for n in "${SET_FILES[@]}"; do
    echo "seeded backup of $n at $s" > "$dir/$n.bak-$s"
  done
  if [ "$kind" = "verified" ]; then
    : > "$dir/.deploy-verified-$s"
  fi
}

# Verified marker names in a directory whose stamp matches the stamp pattern.
pattern_markers() {
  local dir="$1" f
  for f in "$dir"/.deploy-verified-*; do
    [ -e "$f" ] || continue
    f="${f##*/.deploy-verified-}"
    if [[ "$f" =~ $STAMP_RE ]]; then echo "$f"; fi
  done
}

PAST_STAMPS=()
for i in 1 2 3 4 5 6; do PAST_STAMPS+=("20200101T00000${i}Z"); done
FUTURE_STAMPS=()
for i in $(seq 1 "$BACKUP_KEEP"); do FUTURE_STAMPS+=("$(printf '20990101T%06dZ' "$i")"); done
UNVERIFIED_STAMP="20000101T000000Z"
MALFORMED_MARKER=".deploy-verified-19990101T000000Z-x"

# Clears backups and markers, then seeds six past verified sets, BACKUP_KEEP verified
# sets dated 2099, one unverified set older than all of them, and one marker whose
# name fails the stamp pattern.
seed_retention() {
  local dir="$1" s
  rm -f "$dir"/*.bak-* "$dir"/.deploy-verified-*
  for s in "${PAST_STAMPS[@]}" "${FUTURE_STAMPS[@]}"; do seed_set "$dir" "$s" verified; done
  seed_set "$dir" "$UNVERIFIED_STAMP" unverified
  : > "$dir/$MALFORMED_MARKER"
}

# =====================================================================================
# Case 8: staging symlinks (CER-023) — a symlink planted at every old-scheme stage name
# (.<name>.deploy-<S>.tmp) for the run's time window is never written through.
# =====================================================================================
SYM_TARGET="$WORK_DIR/symlink-target"
fresh_target "$SYM_TARGET"
reset_sentinel
now="$(date -u +%s)"
for off in $(seq 0 10); do
  S="$(stamp_at $((now + off)))"
  for n in "${SET_FILES[@]}"; do
    ln -s "$SENTINEL" "$SYM_TARGET/.${n}.deploy-${S}.tmp"
  done
done

export FORQSITE_HELP_DEPLOY_DIR="$SYM_TARGET"
set +e
out_sym="$(run_deploy 2>&1)"
status_sym=$?
set -e

left_stage=""
for f in "$SYM_TARGET"/.*.deploy-*; do
  [ -e "$f" ] || [ -L "$f" ] || continue
  [ -L "$f" ] && continue   # the planted symlinks themselves
  left_stage="$f"
done

ok=0
detail=""
if [ "$status_sym" -ne 0 ]; then
  ok=1; detail="expected exit 0, got $status_sym: $out_sym"
elif ! sentinel_intact; then
  ok=1; detail="sentinel outside the target was written through a planted stage symlink"
elif [ "$(sha256sum "$SYM_TARGET/index.html" | cut -d' ' -f1)" != "$committed_index_sha" ]; then
  ok=1; detail="target index.html does not match committed bytes"
elif [ "$(sha256sum "$SYM_TARGET/gap-handoff.html" | cut -d' ' -f1)" != "$committed_gap_sha" ]; then
  ok=1; detail="target gap-handoff.html does not match committed bytes"
elif [ -n "$left_stage" ]; then
  ok=1; detail="a stage file was left in the target: ${left_stage##*/}"
fi
report "staging symlinks (exit 0, bytes match, sentinel unchanged, no stage left)" "$ok" "$detail"

# Backup-name symlinks: a symlink at index.html.bak-<S> for the run's window must make
# the deploy refuse (exit 5), never write through it.
BAKSYM_TARGET="$WORK_DIR/backup-symlink-target"
fresh_target "$BAKSYM_TARGET"
reset_sentinel
now="$(date -u +%s)"
for off in $(seq 0 10); do
  ln -s "$SENTINEL" "$BAKSYM_TARGET/index.html.bak-$(stamp_at $((now + off)))"
done

export FORQSITE_HELP_DEPLOY_DIR="$BAKSYM_TARGET"
set +e
out_baksym="$(run_deploy 2>&1)"
status_baksym=$?
set -e

ok=0
detail=""
if [ "$status_baksym" -ne 5 ]; then
  ok=1; detail="expected exit 5, got $status_baksym: $out_baksym"
elif ! sentinel_intact; then
  ok=1; detail="sentinel outside the target was written through a planted backup symlink"
elif ! printf '%s' "$out_baksym" | grep -q "index.html"; then
  ok=1; detail="refusal did not name index.html"
elif printf '%s' "$out_baksym" | grep -F "$BAKSYM_TARGET" >/dev/null; then
  ok=1; detail="refusal named the target directory"
fi
report "backup symlinks (exit 5, sentinel unchanged, names the file not the directory)" "$ok" "$detail"

# =====================================================================================
# Case 9: first-write mode — a destination that did not exist is created 0644 (never
# the mktemp stage's 0600), even under a restrictive umask; an existing destination
# keeps its inode and its operator-set mode.
# =====================================================================================
MODE_TARGET="$WORK_DIR/first-write-target"
rm -rf "$MODE_TARGET"
mkdir -p "$MODE_TARGET"
echo "pre-existing live index bundle" > "$MODE_TARGET/index.html"
chmod 0640 "$MODE_TARGET/index.html"
before_mode_inode="$(stat -c '%i' "$MODE_TARGET/index.html")"

export FORQSITE_HELP_DEPLOY_DIR="$MODE_TARGET"
set +e
out_mode="$( umask 077; run_deploy 2>&1 )"
status_mode=$?
set -e

mode_of() { stat -c '%a' "$1" 2>/dev/null || echo missing; }
ok=0
detail=""
if [ "$status_mode" -ne 0 ]; then
  ok=1; detail="expected exit 0, got $status_mode: $out_mode"
elif [ "$(mode_of "$MODE_TARGET/gap-handoff.html")" != "644" ]; then
  ok=1; detail="newly created gap-handoff.html has mode $(mode_of "$MODE_TARGET/gap-handoff.html"), expected 644"
elif [ "$(mode_of "$MODE_TARGET/site-provenance.json")" != "644" ]; then
  ok=1; detail="newly created site-provenance.json has mode $(mode_of "$MODE_TARGET/site-provenance.json"), expected 644"
elif [ "$(mode_of "$MODE_TARGET/index.html")" != "640" ]; then
  ok=1; detail="existing index.html mode changed to $(mode_of "$MODE_TARGET/index.html"), expected 640"
elif [ "$(stat -c '%i' "$MODE_TARGET/index.html")" != "$before_mode_inode" ]; then
  ok=1; detail="existing index.html was replaced (inode changed)"
elif [ "$(sha256sum "$MODE_TARGET/index.html" | cut -d' ' -f1)" != "$committed_index_sha" ]; then
  ok=1; detail="target index.html does not match committed bytes"
fi
report "first-write mode (new files 0644 under umask 077; existing file keeps inode and mode)" "$ok" "$detail"

# =====================================================================================
# Case 10: retention (CER-027) — future-dated verified sets never displace the current
# set; unverified sets and malformed marker names are never touched.
# =====================================================================================
RET_TARGET="$WORK_DIR/retention-target"
fresh_target "$RET_TARGET"
seed_retention "$RET_TARGET"

export FORQSITE_HELP_DEPLOY_DIR="$RET_TARGET"
set +e
out_ret="$(run_deploy 2>&1)"
status_ret=$?
set -e
ret_stamp="$(stamp_from_output "$out_ret")"

# Expected pruned: every past stamp, plus the oldest future stamps beyond KEEP - 1.
expected_pruned=("${PAST_STAMPS[@]}" "${FUTURE_STAMPS[@]:0:$(( ${#FUTURE_STAMPS[@]} - (BACKUP_KEEP - 1) ))}")

ok=0
detail=""
if [ "$status_ret" -ne 0 ]; then
  ok=1; detail="expected exit 0, got $status_ret: $out_ret"
elif ! [[ "$ret_stamp" =~ $STAMP_RE ]]; then
  ok=1; detail="could not read the run's stamp from the success block"
elif [ ! -e "$RET_TARGET/.deploy-verified-$ret_stamp" ]; then
  ok=1; detail="current set's marker missing"
else
  for n in "${SET_FILES[@]}"; do
    if [ ! -f "$RET_TARGET/$n.bak-$ret_stamp" ]; then ok=1; detail="current set's $n backup missing"; fi
  done
fi
if [ "$ok" -eq 0 ]; then
  marker_count="$(pattern_markers "$RET_TARGET" | wc -l)"
  if [ "$marker_count" -ne "$BACKUP_KEEP" ]; then
    ok=1; detail="expected $BACKUP_KEEP pattern markers, found $marker_count"
  fi
fi
if [ "$ok" -eq 0 ]; then
  for s in "${expected_pruned[@]}"; do
    for f in "${SET_FILES[@]/%/.bak-$s}" ".deploy-verified-$s"; do
      if [ -e "$RET_TARGET/$f" ]; then ok=1; detail="pruned stamp's file still present: $f"; fi
    done
  done
fi
if [ "$ok" -eq 0 ]; then
  for f in "${SET_FILES[@]/%/.bak-$UNVERIFIED_STAMP}" "$MALFORMED_MARKER"; do
    if [ ! -e "$RET_TARGET/$f" ]; then ok=1; detail="unverified or malformed entry was removed: $f"; fi
  done
  if [ "$(cat "$RET_TARGET/index.html.bak-$UNVERIFIED_STAMP")" != "seeded backup of index.html at $UNVERIFIED_STAMP" ]; then
    ok=1; detail="unverified set's content changed"
  fi
fi
if [ "$ok" -eq 0 ] && ! printf '%s\n' "$out_ret" | grep -q "^pruned .*${PAST_STAMPS[0]}"; then
  ok=1; detail="success block has no pruned line naming the pruned stamps"
fi
report "retention (current set kept, $BACKUP_KEEP verified markers, pruned sets gone, unverified + malformed untouched)" "$ok" "$detail"

# =====================================================================================
# Case 11: partial prune failure — the second of two prune removals fails; the report
# names the first stamp as pruned and the second as the one that failed, and never
# claims that no backups were pruned.
# =====================================================================================
PART_TARGET="$WORK_DIR/partial-prune-target"
fresh_target "$PART_TARGET"
# BACKUP_KEEP - 1 kept plus exactly two to prune.
part_stamps=()
for i in $(seq 1 $((BACKUP_KEEP + 1))); do part_stamps+=("$(printf '20200101T%06dZ' "$i")"); done
for s in "${part_stamps[@]}"; do seed_set "$PART_TARGET" "$s" verified; done
first_pruned="${part_stamps[0]}"
failing="${part_stamps[1]}"
# A non-empty directory where a backup file is expected: rm -f cannot remove it.
rm -f "$PART_TARGET/index.html.bak-$failing"
mkdir -p "$PART_TARGET/index.html.bak-$failing/blocker"

export FORQSITE_HELP_DEPLOY_DIR="$PART_TARGET"
set +e
out_part="$(run_deploy 2>&1)"
status_part=$?
set -e

ok=0
detail=""
if [ "$status_part" -ne 5 ]; then
  ok=1; detail="expected exit 5, got $status_part: $out_part"
elif ! printf '%s\n' "$out_part" | grep -i "pruned" | grep -q "$first_pruned"; then
  ok=1; detail="report does not name $first_pruned as pruned: $out_part"
elif ! printf '%s\n' "$out_part" | grep -i "fail" | grep -q "$failing"; then
  ok=1; detail="report does not name $failing as the failed stamp: $out_part"
elif printf '%s\n' "$out_part" | grep -qi "no backups were pruned\|no backups pruned"; then
  ok=1; detail="report claims no backups were pruned after one removal succeeded: $out_part"
elif [ -e "$PART_TARGET/.deploy-verified-$first_pruned" ] || [ -e "$PART_TARGET/gap-handoff.html.bak-$first_pruned" ]; then
  ok=1; detail="first stamp's files were not actually removed"
elif ! printf '%s\n' "$out_part" | grep -qi "verified"; then
  ok=1; detail="report does not say the files verified"
fi
report "partial prune failure (exit 5, names the pruned stamp and the failed one)" "$ok" "$detail"
rm -rf "$PART_TARGET"

# =====================================================================================
# Case 12: no prune on failure — a hash-mismatch run deletes nothing and writes no
# marker.
# =====================================================================================
fresh_target "$FIXTURE_TARGET"
seed_retention "$FIXTURE_TARGET"
seeded_names=()
for s in "${PAST_STAMPS[@]}" "${FUTURE_STAMPS[@]}"; do
  seeded_names+=("${SET_FILES[@]/%/.bak-$s}" ".deploy-verified-$s")
done
seeded_names+=("${SET_FILES[@]/%/.bak-$UNVERIFIED_STAMP}" "$MALFORMED_MARKER")
markers_before="$(cd "$FIXTURE_TARGET" && ls -A | grep '^\.deploy-verified-' | sort)"

export FORQSITE_HELP_DEPLOY_DIR="$FIXTURE_TARGET"
: > "$CORRUPT_FLAG"
set +e
out_noprune="$(run_deploy 2>&1)"
status_noprune=$?
set -e
rm -f "$CORRUPT_FLAG"
markers_after="$(cd "$FIXTURE_TARGET" && ls -A | grep '^\.deploy-verified-' | sort)"

ok=0
detail=""
if [ "$status_noprune" -ne 4 ]; then
  ok=1; detail="expected exit 4, got $status_noprune: $out_noprune"
elif [ "$markers_before" != "$markers_after" ]; then
  ok=1; detail="marker set changed on a failed run"
else
  for f in "${seeded_names[@]}"; do
    if [ ! -e "$FIXTURE_TARGET/$f" ]; then ok=1; detail="seeded file removed on a failed run: $f"; fi
  done
fi
report "no prune on failure (exit 4, every seeded file present, no marker written)" "$ok" "$detail"

export FORQSITE_HELP_DEPLOY_DIR="$FIXTURE_TARGET"

# =====================================================================================
echo ""
echo "deploy-selftest: $PASS_COUNT passed, $FAILURES failed"
if [ "$FAILURES" -ne 0 ]; then
  exit 1
fi
exit 0
