# read-deploy-env.sh — shared reader for scripts/deploy.env, used by deploy.sh and
# drift-check.sh. Function definitions only: no top-level side effects, and not meant
# to be run directly. Each caller loads it from its own directory (never from the repo
# it was run in), so it carries the same trust as the calling script.
#
# Why the file is read as data (CER-024): both callers change directory to the root of
# whatever repository contains the caller's cwd, and then look for scripts/deploy.env
# there. A repository the operator does not control can ship that file. Handing it to
# the shell would run whatever it contains with the operator's privileges, so it is
# never handed to the shell. It is parsed line by line as KEY=value data instead, and
# every value is kept as literal text: `$(...)`, backticks and `$VAR` are never expanded.
#
# Accepted lines:
#   - blank lines;
#   - lines whose first non-blank character is `#`;
#   - `[export ]KEY=value`, where KEY is one of FORQSITE_HELP_DEPLOY_HOST,
#     FORQSITE_HELP_DEPLOY_DIR or FORQSITE_HELP_SITE_URL, and value is a double-quoted
#     string, a single-quoted string, or a bare token with no whitespace and no quote
#     characters (possibly empty).
# Any other line is refused by line number only; its content is never printed, so no
# part of a configured value reaches output.

# read_deploy_env <file> <caller>
#
# Parses <file>. On success returns 0 and sets DEPLOY_ENV_HOST, DEPLOY_ENV_DIR and
# DEPLOY_ENV_SITE_URL to the literal values of FORQSITE_HELP_DEPLOY_HOST,
# FORQSITE_HELP_DEPLOY_DIR and FORQSITE_HELP_SITE_URL in the file (empty when a key is
# absent; the last occurrence wins when a key repeats). The assignment targets are the
# fixed names above, chosen by a case over the allowlist — never a name taken from the
# file. On a refused or unreadable file, prints one line naming <caller> and the line
# number to stderr and returns 2.
read_deploy_env() {
  local file="$1" caller="$2"
  local line key value lineno=0
  local line_re='^[[:space:]]*(export[[:space:]]+)?(FORQSITE_HELP_DEPLOY_HOST|FORQSITE_HELP_DEPLOY_DIR|FORQSITE_HELP_SITE_URL)=("([^"]*)"|'"'"'([^'"'"']*)'"'"'|([^[:space:]"'"'"']*))[[:space:]]*$'
  local skip_re='^[[:space:]]*(#.*)?$'

  DEPLOY_ENV_HOST=""
  DEPLOY_ENV_DIR=""
  DEPLOY_ENV_SITE_URL=""

  if [ ! -r "$file" ]; then
    echo "${caller}: scripts/deploy.env is not readable" >&2
    return 2
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    line="${line%$'\r'}"
    if [[ "$line" =~ $skip_re ]]; then
      continue
    fi
    if ! [[ "$line" =~ $line_re ]]; then
      echo "${caller}: scripts/deploy.env line ${lineno} is not a KEY=value line for a known key" >&2
      return 2
    fi
    key="${BASH_REMATCH[2]}"
    # Exactly one of the three alternatives matched; the other two groups are empty.
    value="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
    case "$key" in
      FORQSITE_HELP_DEPLOY_HOST) DEPLOY_ENV_HOST="$value" ;;
      FORQSITE_HELP_DEPLOY_DIR) DEPLOY_ENV_DIR="$value" ;;
      FORQSITE_HELP_SITE_URL) DEPLOY_ENV_SITE_URL="$value" ;;
      *)
        echo "${caller}: scripts/deploy.env line ${lineno} is not a KEY=value line for a known key" >&2
        return 2
        ;;
    esac
  done < "$file"

  return 0
}
