#!/usr/bin/env bash
# kunal-secrets-check scanner.
# Prints only "LEVEL file:line kind" or "LEVEL file kind". It never prints a matched value.
#
# Usage: scan.sh [--base <ref>]
#   default     scan the staged changes (git diff --cached)
#   --base REF  also scan the files changed in REF..HEAD (commits about to be pushed)
#
# Exit codes: 0 no blocking findings, 1 blocking findings, 2 not a git repo / bad usage.
# BLOCK = real token shapes and forbidden file names. WARN = keyword assigned a long value.

base=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="${2:-}"; shift 2 ;;
    *) echo "usage: scan.sh [--base <ref>]" >&2; exit 2 ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)" || exit 2

blocked=0

# kind|ERE pattern. Real token shapes with realistic lengths only.
block_patterns='aws-access-key|AKIA[0-9A-Z]{16}
github-token|(ghp|gho|ghs|ghu)_[A-Za-z0-9]{36}
github-fine-grained-token|github_pat_[A-Za-z0-9_]{22,}
api-key-sk|sk-[A-Za-z0-9_-]{20,}
slack-token|xox[bp]-[A-Za-z0-9-]{10,}
jwt|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}
private-key|-----BEGIN [A-Z ]*PRIVATE KEY-----'

warn_patterns='keyword-with-long-value|(api[_-]?key|secret|token|passw(or)?d)[A-Za-z_]*["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+_-]{16,}'

forbidden_names='(^|/)\.env(\.[^/]*)?$|\.(pem|key|p12)$|(^|/)id_rsa|(^|/)credentials[^/]*\.json$|(^|/)service-account[^/]*\.json$|(^|/)settings\.local\.json$|(^|/)\.npmrc$|(^|/)\.netrc$'

# scan_files <rev-or-empty> <file>...   (empty rev = the index)
scan_files() {
  local rev="$1"; shift
  [ $# -eq 0 ] && return 0
  local line kind pat level out
  while IFS='|' read -r kind pat; do
    [ -z "$kind" ] && continue
    if [ -n "$rev" ]; then
      out=$(git grep -n -I -E -e "$pat" "$rev" -- "$@" 2>/dev/null | sed "s#^$rev:##" | cut -d: -f1,2)
    else
      out=$(git grep --cached -n -I -E -e "$pat" -- "$@" 2>/dev/null | cut -d: -f1,2)
    fi
    [ -n "$out" ] && while IFS= read -r line; do echo "BLOCK $line $kind"; blocked=1; done <<EOF
$out
EOF
  done <<EOF
$block_patterns
EOF
  while IFS='|' read -r kind pat; do
    if [ -n "$rev" ]; then
      out=$(git grep -n -I -E -i -e "$pat" "$rev" -- "$@" 2>/dev/null | sed "s#^$rev:##" | cut -d: -f1,2)
    else
      out=$(git grep --cached -n -I -E -i -e "$pat" -- "$@" 2>/dev/null | cut -d: -f1,2)
    fi
    [ -n "$out" ] && while IFS= read -r line; do echo "WARN  $line $kind"; done <<EOF
$out
EOF
  done <<EOF
$warn_patterns
EOF
}

check_names() {
  local f
  for f in "$@"; do
    case "$f" in *.env.example|.env.example) continue ;; esac
    if printf '%s\n' "$f" | grep -Eq "$forbidden_names"; then
      echo "BLOCK $f forbidden-file-name"; blocked=1
    fi
  done
}

staged=()
while IFS= read -r -d '' f; do staged+=("$f"); done < <(git diff --cached --name-only --diff-filter=ACMR -z)

if [ ${#staged[@]} -gt 0 ]; then
  check_names "${staged[@]}"
  scan_files "" "${staged[@]}"
fi
echo "scanned: ${#staged[@]} staged file(s)"

if [ -n "$base" ]; then
  git rev-parse --verify -q "$base" >/dev/null || { echo "unknown base ref: $base" >&2; exit 2; }
  ranged=()
  while IFS= read -r -d '' f; do ranged+=("$f"); done < <(git diff --name-only --diff-filter=ACMR -z "$base"...HEAD)
  if [ ${#ranged[@]} -gt 0 ]; then
    check_names "${ranged[@]}"
    scan_files "HEAD" "${ranged[@]}"
  fi
  echo "scanned: ${#ranged[@]} file(s) changed in $base...HEAD (content at HEAD)"
fi

if [ "$blocked" -eq 1 ]; then
  echo "RESULT: blocking findings. Do not commit or push."
  exit 1
fi
echo "RESULT: no blocking findings (this is not a guarantee the change is safe)."
exit 0
