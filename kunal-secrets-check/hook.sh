#!/usr/bin/env bash
# PreToolUse hook for the Bash tool (kunal-secrets-check).
# Runs scan.sh before `git commit` (staged files) and before `git push` (commits against the upstream).
# Denies only on BLOCK findings (real token shapes, forbidden file names). WARN never blocks.
# Fails OPEN: any doubt (no jq, not a commit/push, not a repo, no upstream) lets the command run.
#
# Known limits: `git commit -a` and `git add x && git commit` stage files at run time, so they are
# not visible to a pre-run check. The push check still covers them once committed.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd=$PWD

opts='([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--[a-z-]+(=[^[:space:]]+)?))*'
prefix='(^|[;&|(]|[[:space:]])git'"$opts"'[[:space:]]+'
mode=""
printf '%s\n' "$cmd" | grep -Eq "${prefix}commit([[:space:]]|\$)" && mode="commit"
printf '%s\n' "$cmd" | grep -Eq "${prefix}push([[:space:]]|\$)" && mode="push"
[ -z "$mode" ] && exit 0

dir="$cwd"
c_dir=$(printf '%s\n' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]"'"'"']+).*/\1/p' | head -1)
cd_dir=$(printf '%s\n' "$cmd" | sed -nE 's/.*(^|[;&|[:space:]])cd[[:space:]]+([^[:space:];&|"'"'"']+).*/\2/p' | head -1)
if [ -n "$c_dir" ]; then dir="$c_dir"; elif [ -n "$cd_dir" ]; then dir="$cd_dir"; fi
case "$dir" in "~"*) dir="$HOME${dir#\~}" ;; /*) ;; *) dir="$cwd/$dir" ;; esac
[ -d "$dir" ] || exit 0
git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

scan="$(cd "$(dirname "$0")" && pwd)/scan.sh"
[ -x "$scan" ] || exit 0

args=()
if [ "$mode" = "push" ]; then
  upstream=$(git -C "$dir" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
  [ -z "$upstream" ] && exit 0   # new branch, nothing to compare against
  args=(--base "$upstream")
fi

out=$(cd "$dir" && "$scan" "${args[@]}" 2>&1)
status=$?
[ "$status" -ne 1 ] && exit 0   # 0 = clean, 2 = scanner could not run: fail open

jq -n --arg r "kunal-secrets-check blocked this git $mode. Findings (values are never shown):
$out
Unstage or remove these, then try again. If a pushed secret is involved, rotate it." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
