#!/usr/bin/env bash
#
# deploy.sh — deploy the two published bundles (index.html, gap-handoff.html) to the
# configured per-site directory, over the configured ssh alias, at a git ref.
#
# What it does:
#   - Resolves the git repository containing the current working directory.
#   - Reads deployment target configuration (ssh alias + remote directory) from the
#     environment, falling back to a gitignored scripts/deploy.env when unset.
#   - Refuses to proceed, before any network contact, if either bundle is untracked at
#     the ref, or its working-tree or staged content differs from that ref ("dirty").
#   - Backs up each live bundle on the remote side to <name>.bak-<UTC stamp>, then
#     overwrites (never renames) each live bundle in place with the bytes of that
#     bundle at the given ref (default HEAD), then verifies each file's sha256 on the
#     far side against the same ref's bytes computed locally.
#   - After both bundles have been copied and hash-verified, generates a provenance
#     sidecar (scripts/make-provenance.sh --ref "$REF") and deploys it to
#     site-provenance.json using the same backup / overwrite-in-place / verify-sha256
#     sequence. The sidecar is written last, deliberately: it asserts "this commit is
#     deployed", and writing it before the bundles land would publish that claim even
#     if a later bundle copy then failed.
#   - Prints a pasteable success record. Never runs docker, docker compose, systemctl,
#     or any container/service restart — including for the one-time bind-mount this
#     script's sidecar requires. That mount (docker-compose.yml) and the container
#     recreate it needs are a one-time, documented, manual bootstrap: (a) run this
#     script once so site-provenance.json exists in the remote directory, (b) add the
#     mount, (c) recreate the container (`docker compose up -d`). Adding the mount
#     before step (a) makes Docker create a directory at that path instead of
#     bind-mounting a file, and the mount is then permanently wrong. Every deploy after
#     the one-time recreate is a plain copy, like the two bundles, and needs nothing
#     further.
#
# Usage:
#   deploy.sh [--ref <git-ref>] [--dry-run]
#
# Exit codes:
#   0  success
#   2  configuration missing (FORQSITE_HELP_DEPLOY_HOST / FORQSITE_HELP_DEPLOY_DIR)
#   3  dirty-tree refusal (untracked at the ref, or working tree / index differs)
#   4  hash verification failure (remote bytes do not match the ref's bytes)
#   5  transport/remote failure (ssh or a remote command failed)
#
# Notes:
#   - nginx.conf is also bind-mounted into the container, but unlike the two bundles a
#     change to it needs a container action (e.g. a config reload) to take effect. That
#     is deliberately outside what this script does; this script only ever touches the
#     two bundle files.
#   - The remote bind mount follows the file's inode, not its name. Each bundle must be
#     overwritten in place (copied over the existing file), never replaced by renaming a
#     new file over it — a rename would leave the container serving the old, now-unlinked
#     inode while the deploy appeared to succeed.

set -euo pipefail

BUNDLES=(index.html gap-handoff.html)
REF="HEAD"
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ref)
      REF="${2:?--ref requires an argument}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "deploy.sh: unrecognized argument: $1" >&2
      echo "usage: deploy.sh [--ref <git-ref>] [--dry-run]" >&2
      exit 2
      ;;
  esac
done

# --- This script's own location, for invoking its sibling make-provenance.sh -------
# Resolved from this script's own path, not from the deployed repo's root below: the
# two are the same in normal use, but a caller may run this script with its cwd set
# to a different repository (e.g. a fixture repo in provenance-selftest.sh), and the
# sibling generator to invoke is always the one next to this script.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAKE_PROVENANCE_SH="$SELF_DIR/make-provenance.sh"

# --- Repo resolution -----------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# --- Configuration ---------------------------------------------------------------
HOST="${FORQSITE_HELP_DEPLOY_HOST:-}"
DIR="${FORQSITE_HELP_DEPLOY_DIR:-}"

if [ -z "$HOST" ] || [ -z "$DIR" ]; then
  if [ -f "scripts/deploy.env" ]; then
    # shellcheck disable=SC1091
    source "scripts/deploy.env"
    HOST="${FORQSITE_HELP_DEPLOY_HOST:-$HOST}"
    DIR="${FORQSITE_HELP_DEPLOY_DIR:-$DIR}"
  fi
fi

if [ -z "$HOST" ] || [ -z "$DIR" ]; then
  echo "deploy.sh: missing configuration — set FORQSITE_HELP_DEPLOY_HOST and FORQSITE_HELP_DEPLOY_DIR" >&2
  echo "deploy.sh: in the environment, or in scripts/deploy.env" >&2
  exit 2
fi

# --- Dirty check (before any network contact) -------------------------------------
dirty_found=0
for bundle in "${BUNDLES[@]}"; do
  if ! git cat-file -e "${REF}:${bundle}" 2>/dev/null; then
    echo "deploy.sh: ${bundle} is not tracked at ref ${REF} (untracked)" >&2
    dirty_found=1
    continue
  fi
  if ! git diff --quiet "${REF}" -- "${bundle}"; then
    echo "deploy.sh: ${bundle} is dirty (unstaged working-tree changes differ from ref ${REF})" >&2
    dirty_found=1
  fi
  if ! git diff --quiet --cached "${REF}" -- "${bundle}"; then
    echo "deploy.sh: ${bundle} is dirty (staged changes differ from ref ${REF})" >&2
    dirty_found=1
  fi
done

if [ "$dirty_found" -ne 0 ]; then
  exit 3
fi

# --- Stamp -------------------------------------------------------------------------
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "deploy.sh: dry run — all local checks passed, no ssh will be invoked"
  echo "deploy.sh: would deploy ref ${REF} (resolved $(git rev-parse "${REF}")) with stamp ${STAMP}"
  for bundle in "${BUNDLES[@]}"; do
    sha="$(git show "${REF}:${bundle}" | sha256sum | cut -d' ' -f1)"
    echo "deploy.sh: would back up and overwrite ${bundle} (sha256 ${sha}) on the configured target"
  done
  echo "deploy.sh: would generate and deploy site-provenance.json (after both bundles verify):"
  "$MAKE_PROVENANCE_SH" --ref "$REF"
  exit 0
fi

# --- Per-bundle deploy: one ssh invocation per step ---------------------------------
declare -A REMOTE_SHA
declare -A LOCAL_SHA

for bundle in "${BUNDLES[@]}"; do
  LOCAL_SHA["$bundle"]="$(git show "${REF}:${bundle}" | sha256sum | cut -d' ' -f1)"
  tmp_name=".${bundle}.deploy-${STAMP}.tmp"

  # Step 1: backup the live file on the far side, if present.
  backup_cmd="cd $(printf '%q' "$DIR") && if [ -f $(printf '%q' "$bundle") ]; then cp -p $(printf '%q' "$bundle") $(printf '%q' "${bundle}.bak-${STAMP}"); fi"
  if ! ssh "$HOST" "$backup_cmd"; then
    echo "deploy.sh: remote backup step failed for ${bundle}" >&2
    exit 5
  fi

  # Step 2: stream the ref's bytes to a temp file, then overwrite the live file in
  # place (never rename over it — see header note on bind-mount inode following).
  copy_cmd="cd $(printf '%q' "$DIR") && cat > $(printf '%q' "$tmp_name") && cp $(printf '%q' "$tmp_name") $(printf '%q' "$bundle") && rm -f $(printf '%q' "$tmp_name")"
  if ! git show "${REF}:${bundle}" | ssh "$HOST" "$copy_cmd"; then
    echo "deploy.sh: remote copy step failed for ${bundle}" >&2
    exit 5
  fi

  # Step 3: hash the remote file and compare against the ref's bytes, hashed locally.
  verify_cmd="cd $(printf '%q' "$DIR") && if ! command -v sha256sum >/dev/null 2>&1; then echo deploy.sh: remote has no sha256sum >&2; exit 5; fi; sha256sum $(printf '%q' "$bundle")"
  if ! remote_out="$(ssh "$HOST" "$verify_cmd")"; then
    echo "deploy.sh: remote verify step failed for ${bundle}" >&2
    exit 5
  fi
  REMOTE_SHA["$bundle"]="$(printf '%s\n' "$remote_out" | cut -d' ' -f1)"
done

# --- Verify --------------------------------------------------------------------------
mismatch=0
for bundle in "${BUNDLES[@]}"; do
  if [ "${REMOTE_SHA[$bundle]}" != "${LOCAL_SHA[$bundle]}" ]; then
    echo "deploy.sh: hash mismatch for ${bundle}" >&2
    mismatch=1
  fi
done

if [ "$mismatch" -ne 0 ]; then
  exit 4
fi

# --- Provenance sidecar: generated and deployed only after both bundles above have
# copied and hash-verified successfully. Written last, deliberately (see header) —
# it asserts "this commit is deployed", and a failure here must never leave a stale
# or partial sidecar published as if it were current.
SIDECAR_NAME="site-provenance.json"
SIDECAR_CONTENT="$("$MAKE_PROVENANCE_SH" --ref "$REF")"
SIDECAR_LOCAL_SHA="$(printf '%s' "$SIDECAR_CONTENT" | sha256sum | cut -d' ' -f1)"
sidecar_tmp_name=".${SIDECAR_NAME}.deploy-${STAMP}.tmp"

# Step 1: backup the live sidecar on the far side, if present.
sidecar_backup_cmd="cd $(printf '%q' "$DIR") && if [ -f $(printf '%q' "$SIDECAR_NAME") ]; then cp -p $(printf '%q' "$SIDECAR_NAME") $(printf '%q' "${SIDECAR_NAME}.bak-${STAMP}"); fi"
if ! ssh "$HOST" "$sidecar_backup_cmd"; then
  echo "deploy.sh: remote backup step failed for ${SIDECAR_NAME}" >&2
  exit 5
fi

# Step 2: stream the generated bytes to a temp file, then overwrite the live file in
# place (never rename over it — see header note on bind-mount inode following).
sidecar_copy_cmd="cd $(printf '%q' "$DIR") && cat > $(printf '%q' "$sidecar_tmp_name") && cp $(printf '%q' "$sidecar_tmp_name") $(printf '%q' "$SIDECAR_NAME") && rm -f $(printf '%q' "$sidecar_tmp_name")"
if ! printf '%s' "$SIDECAR_CONTENT" | ssh "$HOST" "$sidecar_copy_cmd"; then
  echo "deploy.sh: remote copy step failed for ${SIDECAR_NAME}" >&2
  exit 5
fi

# Step 3: hash the remote file and compare against the locally-computed hash of the
# generated bytes.
sidecar_verify_cmd="cd $(printf '%q' "$DIR") && if ! command -v sha256sum >/dev/null 2>&1; then echo deploy.sh: remote has no sha256sum >&2; exit 5; fi; sha256sum $(printf '%q' "$SIDECAR_NAME")"
if ! sidecar_remote_out="$(ssh "$HOST" "$sidecar_verify_cmd")"; then
  echo "deploy.sh: remote verify step failed for ${SIDECAR_NAME}" >&2
  exit 5
fi
SIDECAR_REMOTE_SHA="$(printf '%s\n' "$sidecar_remote_out" | cut -d' ' -f1)"

if [ "$SIDECAR_REMOTE_SHA" != "$SIDECAR_LOCAL_SHA" ]; then
  echo "deploy.sh: hash mismatch for ${SIDECAR_NAME}" >&2
  exit 4
fi

# --- Success record --------------------------------------------------------------------
RESOLVED_REF="$(git rev-parse "${REF}")"

echo "deployed  ${RESOLVED_REF}   (${REF})"
echo "stamp     ${STAMP}"
echo "index.html         ${LOCAL_SHA[index.html]}  verified"
echo "gap-handoff.html   ${LOCAL_SHA[gap-handoff.html]}  verified"
echo "site-provenance.json   ${SIDECAR_LOCAL_SHA}  verified"
echo "backups   index.html.bak-${STAMP}, gap-handoff.html.bak-${STAMP}, site-provenance.json.bak-${STAMP}"
echo "target    the configured per-site directory, via the configured ssh alias"
echo "next      run the drift check to confirm the bytes a request returns (INFRA-007); on a"
echo "          host that has never served site-provenance.json, first add its bind-mount to"
echo "          docker-compose.yml and recreate the container (docker compose up -d) — this"
echo "          deploy alone does not add the mount or touch the container"

exit 0
