#!/usr/bin/env bash
#
# deploy-selftest.sh — exercises scripts/deploy.sh's refusals and happy path against a
# throwaway fixture git repository and a throwaway fixture "remote" directory, using a
# stub `ssh` placed first on PATH. The stub runs the remote command under `dash` (a
# real POSIX sh, not bash) so that any bash-only quoting the remote command relies on
# is exposed rather than silently passing (CER-025). Contacts no real host.
#
# Cases (see docs/stories/INFRA/INFRA-006.md § Tests, INFRA-011 for 6-8):
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
echo ""
echo "deploy-selftest: $PASS_COUNT passed, $FAILURES failed"
if [ "$FAILURES" -ne 0 ]; then
  exit 1
fi
exit 0
