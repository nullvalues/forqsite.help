#!/usr/bin/env bash
#
# drift-check.sh — compares the bytes an HTTP request actually returns for the two
# published bundles (index.html, gap-handoff.html) against the bytes committed at a
# git ref, and exits non-zero when they differ. This is the served-bytes half of
# INFRA-006's copy-and-verify: deploy.sh verifies that the bytes it copied landed on
# the remote file; this script verifies that a request against the live URL returns
# those same bytes. Neither check alone closes the gap CER-014 records: a rename over
# a bundle leaves the container's bind mount serving an old, now-unlinked inode while
# the file on the remote directory (and any mtime/size/process check of it) still
# looks correct. Hashing the remote file instead of the bytes a request returns is
# exactly the proxy this script refuses to take, because that proxy is the one that
# would pass over a stale inode.
#
# What it does:
#   - Resolves the git repository containing the current working directory.
#   - Reads the site's base URL from the environment, falling back to a gitignored
#     scripts/deploy.env when unset (the same file, and the same read pattern,
#     deploy.sh already uses for its own two variables).
#   - For each bundle: fetches <base-url>/<bundle> to a file (never a shell variable —
#     command substitution strips trailing newlines and would report a false DRIFT on
#     a correct site), with an identity content-encoding and no redirect following,
#     and hashes the fetched bytes with sha256.
#   - Computes sha256 of `git show <ref>:<bundle>` (default ref HEAD) for the same
#     bundle, and compares.
#   - On a mismatch, walks the commits reachable from the ref that touched that
#     bundle, hashing each distinct blob, to name which committed version (if any)
#     the served bytes actually match — because "the bytes differ" is a weaker report
#     than "the bytes differ, and the site is serving commit <X>".
#   - Also fetches <base-url>/site-provenance.json (INFRA-008) and reports it as a
#     labelled *claim* alongside the per-bundle result — never as part of the match
#     decision. The sidecar can only ever add a failure: its claimed per-bundle
#     sha256 values are compared against the bytes this run actually fetched, and a
#     disagreement is reported with its own exit code, reachable only when no bundle
#     drifted (drift's exit 3 always outranks it). It can never supply a match,
#     suppress one, or turn a DRIFT into an ok — trusting a version string out of the
#     sidecar as the basis of the decision is exactly the proxy this script exists to
#     refuse; a stale or hand-written sidecar would lie, and the site would look
#     current because it said so.
#   - Prints one report block. Exits 0 only when every bundle's served bytes match the
#     ref's bytes and the sidecar did not contradict them.
#
# Usage:
#   drift-check.sh [--ref <git-ref>]
#
# Exit codes:
#   0   no drift — every bundle's served bytes match the ref (the sidecar, if present,
#       agreed, or was absent/unreadable — never part of this decision either way)
#   2   configuration missing (FORQSITE_HELP_SITE_URL)
#   3   drift detected — at least one bundle's served bytes do not match the ref
#       (outranks 6: always the exit when both are true)
#   4   fetch failure (non-2xx, a redirect, a connection failure, or a timeout)
#   5   a bundle is not tracked at the ref
#   6   provenance sidecar contradiction — the sidecar's claimed sha256 for a bundle
#       disagrees with that bundle's served bytes, and no bundle drifted (exit 3 takes
#       precedence whenever both conditions hold)
#   64  usage error (unrecognised argument, or --ref given with no value)
#
# Notes:
#   - Byte-level only, never render-level. This check never parses, greps or renders
#     the fetched HTML for a version string, a phase marker, or any other content
#     signal, and never consults mtime or size. The only thing read out of the fetched
#     bytes is their sha256. A render-based or DOM-based check would inherit the fact
#     that the bundles' rendering is not exercised by any check in this tree today —
#     that gap belongs to a sibling content phase, not this one.
#   - nginx.conf is bind-mounted into the container alongside the two bundles, but
#     unlike them it is never served: no HTTP request returns its bytes (it only sets
#     `listen`, `server_name`, `root`, `index`), so the invariant this script checks is
#     undefined for it. This script prints one explicit line saying so in every report
#     rather than silently omitting the file, or checking it over ssh and presenting
#     that as if it carried the same strength — an ssh comparison would assert a
#     different, weaker invariant (the file on the host equals the committed file,
#     which is the very proxy this script refuses for the bundles) and would make ssh
#     reachability a precondition of a check that otherwise needs only an HTTP client.
#     That is a config-drift check, if one is ever wanted; it is not this one.
#   - This script never runs docker, docker compose, ssh or scp. It makes an HTTP
#     request, nothing else.
#   - curl's redirect-following is off by default; this script does not turn it on, so
#     a 3xx response is never followed. It is still explicitly detected as a fetch
#     failure below, because "the bytes this URL returns" is the claim being checked,
#     and a redirect means some other URL answered it.
#   - The provenance sidecar can only ever add a failure because the bundle
#     match/drift decision is, and remains, served bytes vs `git show <ref>:<bundle>`
#     alone — the sidecar's repo_commit, its deployed_at, its claimed bundle sha256
#     values, and its mere presence are never the basis of that decision, only ever
#     reported alongside it.

set -euo pipefail

BUNDLES=(index.html gap-handoff.html)
REF="HEAD"

# --- Argument parsing --------------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    --ref)
      if [ "$#" -lt 2 ]; then
        echo "drift-check.sh: --ref requires an argument" >&2
        echo "usage: drift-check.sh [--ref <git-ref>]" >&2
        exit 64
      fi
      REF="$2"
      shift 2
      ;;
    *)
      echo "drift-check.sh: unrecognized argument: $1" >&2
      echo "usage: drift-check.sh [--ref <git-ref>]" >&2
      exit 64
      ;;
  esac
done

# --- Repo resolution -----------------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# --- Configuration -------------------------------------------------------------------
BASE_URL="${FORQSITE_HELP_SITE_URL:-}"

if [ -z "$BASE_URL" ]; then
  if [ -f "scripts/deploy.env" ]; then
    # shellcheck disable=SC1091
    source "scripts/deploy.env"
    BASE_URL="${FORQSITE_HELP_SITE_URL:-$BASE_URL}"
  fi
fi

if [ -z "$BASE_URL" ]; then
  echo "drift-check.sh: missing configuration — set FORQSITE_HELP_SITE_URL" >&2
  echo "drift-check.sh: in the environment, or in scripts/deploy.env" >&2
  exit 2
fi

BASE_URL="${BASE_URL%/}"

# --- Fetch one bundle's served bytes to a file (never a shell variable) --------------
# Prints a message to stderr and returns 4 on any non-2xx, redirect, connection
# failure, or timeout. Writes the fetched bytes to "$1/$2" on success.
fetch_bundle() {
  local scratch="$1" bundle="$2"
  local url="${BASE_URL}/${bundle}"
  local out status
  set +e
  out="$(curl --silent --show-error \
       --header 'Accept-Encoding: identity' \
       --header 'Cache-Control: no-cache' \
       --connect-timeout 10 --max-time 60 \
       --output "${scratch}/${bundle}" \
       --write-out '%{http_code} %{redirect_url}' \
       "$url" 2>"${scratch}/${bundle}.curlerr")"
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    echo "drift-check.sh: fetch failed for ${bundle}: $(cat "${scratch}/${bundle}.curlerr")" >&2
    return 4
  fi
  local http_code redirect_url
  http_code="${out%% *}"
  redirect_url="${out#* }"
  case "$http_code" in
    2??)
      return 0
      ;;
    3??)
      echo "drift-check.sh: fetch failed for ${bundle}: redirected (${http_code}) to ${redirect_url:-<none>}" >&2
      return 4
      ;;
    *)
      echo "drift-check.sh: fetch failed for ${bundle}: HTTP ${http_code}" >&2
      return 4
      ;;
  esac
}

# --- Fetch the provenance sidecar (INFRA-008) — additional context only, never part
# of the match decision. A fetch failure, a non-2xx/redirect, or a body that does not
# parse as the expected fixed shape is reported as a plain line, never an error, and
# changes no exit code. Returns non-zero (caller-checked, not `set -e`-propagated) on
# any such failure; success writes the raw body to "$1/site-provenance.json".
fetch_provenance() {
  local scratch="$1"
  local url="${BASE_URL}/site-provenance.json"
  local out status
  set +e
  out="$(curl --silent --show-error \
       --header 'Accept-Encoding: identity' \
       --header 'Cache-Control: no-cache' \
       --connect-timeout 10 --max-time 60 \
       --output "${scratch}/site-provenance.json" \
       --write-out '%{http_code}' \
       "$url" 2>"${scratch}/site-provenance.curlerr")"
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    return 1
  fi
  case "$out" in
    2??) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Name which commit the served bytes match, when they do not match the ref -------
# Walks commits reachable from $REF that touched $bundle, newest first, hashing each
# distinct blob until one matches $served_sha. Prints its report line either way; a
# no-match is a real state of the world (hand-edited on the host, or deployed from a
# ref outside this history), not a failure of the check.
report_matching_commit() {
  local bundle="$1" served_sha="$2"
  local -A seen_oids=()
  local commit oid blob_sha match_commit=""
  while IFS= read -r commit; do
    oid="$(git rev-parse "${commit}:${bundle}" 2>/dev/null)" || continue
    if [ -n "${seen_oids[$oid]:-}" ]; then
      continue
    fi
    seen_oids[$oid]=1
    blob_sha="$(git cat-file blob "$oid" | sha256sum | cut -d' ' -f1)"
    if [ "$blob_sha" = "$served_sha" ]; then
      match_commit="$commit"
      break
    fi
  done < <(git rev-list "$REF" -- "$bundle")

  if [ -n "$match_commit" ]; then
    local short date subject behind
    short="$(git rev-parse --short "$match_commit")"
    date="$(git log -1 --format=%cd --date=short "$match_commit")"
    subject="$(git log -1 --format=%s "$match_commit")"
    behind="$(git rev-list --count "${match_commit}..${REF}")"
    echo "  live bytes match  ${short} ${date} \"${subject}\"  (${behind} commits behind the ref)"
  else
    echo "  served bytes match no commit in this history that touched ${bundle} — hand-edited on the host, or deployed from a ref outside this history"
  fi
}

# --- Work ------------------------------------------------------------------------------
SCRATCH="$(mktemp -d)"
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

declare -A SERVED_SHA
declare -A COMMITTED_SHA

for bundle in "${BUNDLES[@]}"; do
  if ! git cat-file -e "${REF}:${bundle}" 2>/dev/null; then
    echo "drift-check.sh: ${bundle} is not tracked at ref ${REF}" >&2
    exit 5
  fi

  fetch_bundle "$SCRATCH" "$bundle"

  SERVED_SHA["$bundle"]="$(sha256sum "${SCRATCH}/${bundle}" | cut -d' ' -f1)"
  COMMITTED_SHA["$bundle"]="$(git show "${REF}:${bundle}" | sha256sum | cut -d' ' -f1)"
done

REF_FULL="$(git rev-parse "$REF")"
REF_SHORT="$(git rev-parse --short "$REF")"
REF_SUBJECT="$(git log -1 --format=%s "$REF")"

printf 'ref                %s  %s "%s"\n' "$REF_FULL" "$REF_SHORT" "$REF_SUBJECT"

DRIFT_COUNT=0
for bundle in "${BUNDLES[@]}"; do
  if [ "${SERVED_SHA[$bundle]}" = "${COMMITTED_SHA[$bundle]}" ]; then
    printf '%-18s  ok  %s\n' "$bundle" "${SERVED_SHA[$bundle]}"
  else
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
    printf '%-18s  DRIFT\n' "$bundle"
    printf '  served            %s\n' "${SERVED_SHA[$bundle]}"
    printf '  committed         %s\n' "${COMMITTED_SHA[$bundle]}"
    report_matching_commit "$bundle" "${SERVED_SHA[$bundle]}"
  fi
done

printf '%-18s  not served — bind-mounted only; no request returns its bytes, so this check cannot cover it\n' "nginx.conf"

# --- Provenance sidecar report — a claim, never a match. See header notes. ----------
PROVENANCE_CONTRADICTION=0
if fetch_provenance "$SCRATCH"; then
  provenance_file="${SCRATCH}/site-provenance.json"
  claimed_commit="$(sed -n 's/.*"repo_commit": "\([^"]*\)".*/\1/p' "$provenance_file")"
  claimed_deployed_at="$(sed -n 's/.*"deployed_at": "\([^"]*\)".*/\1/p' "$provenance_file")"
  claimed_index_sha="$(sed -n 's/.*"index\.html": "\([^"]*\)".*/\1/p' "$provenance_file")"
  claimed_gap_sha="$(sed -n 's/.*"gap-handoff\.html": "\([^"]*\)".*/\1/p' "$provenance_file")"

  if [ -z "$claimed_commit" ] || [ -z "$claimed_deployed_at" ] || \
     [ -z "$claimed_index_sha" ] || [ -z "$claimed_gap_sha" ]; then
    echo "provenance         absent or unreadable — the bundle result above does not depend on it"
  else
    declare -A CLAIMED_SHA
    CLAIMED_SHA["index.html"]="$claimed_index_sha"
    CLAIMED_SHA["gap-handoff.html"]="$claimed_gap_sha"
    printf 'provenance         claims %s deployed %s  (claim, not the basis of the result above)\n' \
      "${claimed_commit:0:7}" "$claimed_deployed_at"
    for bundle in "${BUNDLES[@]}"; do
      if [ "${CLAIMED_SHA[$bundle]}" != "${SERVED_SHA[$bundle]}" ]; then
        PROVENANCE_CONTRADICTION=1
        printf '  provenance claim for %-18s disagrees with served bytes\n' "$bundle"
        printf '    claimed           %s\n' "${CLAIMED_SHA[$bundle]}"
        printf '    served            %s\n' "${SERVED_SHA[$bundle]}"
      fi
    done
  fi
else
  echo "provenance         absent or unreadable — the bundle result above does not depend on it"
fi

if [ "$DRIFT_COUNT" -ne 0 ]; then
  echo "result             DRIFT — ${DRIFT_COUNT} of ${#BUNDLES[@]} served bundles does not match the ref"
  exit 3
fi

if [ "$PROVENANCE_CONTRADICTION" -ne 0 ]; then
  echo "result             provenance contradiction — the sidecar's claimed bundle hash disagrees with served bytes, though no bundle drifted"
  exit 6
fi

echo "result             ok — served bytes match the ref for all ${#BUNDLES[@]} bundles"
exit 0
