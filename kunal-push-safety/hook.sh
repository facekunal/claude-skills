#!/usr/bin/env bash
# PreToolUse hook for the Bash tool (kunal-push-safety).
# Denies a `git push` that would land on the default branch from a different branch.
# Fails OPEN: any doubt (no jq, not a push, not a repo, odd quoting) lets the command run.
#
# Denied when:
#   - the current branch's upstream is main/master (or origin/HEAD's branch) but the branch name differs
#   - the push names a refspec ending in :main or :master (or pushes "main"/"master") from another branch

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd=$PWD

# Only act on commands that contain `git [global opts] push`.
push_re='(^|[;&|(]|[[:space:]])git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--[a-z-]+(=[^[:space:]]+)?))*[[:space:]]+push([[:space:]]|$)'
printf '%s\n' "$cmd" | grep -Eq "$push_re" || exit 0

# Work out which directory the push runs in: `git -C dir`, then `cd dir &&`, else cwd.
dir="$cwd"
c_dir=$(printf '%s\n' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]"'"'"']+).*/\1/p' | head -1)
cd_dir=$(printf '%s\n' "$cmd" | sed -nE 's/.*(^|[;&|[:space:]])cd[[:space:]]+([^[:space:];&|"'"'"']+).*/\2/p' | head -1)
if [ -n "$c_dir" ]; then dir="$c_dir"; elif [ -n "$cd_dir" ]; then dir="$cd_dir"; fi
case "$dir" in "~"*) dir="$HOME${dir#\~}" ;; /*) ;; *) dir="$cwd/$dir" ;; esac
[ -d "$dir" ] || exit 0
git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
[ -z "$branch" ] && exit 0   # detached HEAD: leave it to the skill

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

default_branch=$(git -C "$dir" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
is_default() { case "$1" in main|master) return 0 ;; esac; [ -n "$default_branch" ] && [ "$1" = "$default_branch" ]; }

# Explicit refspec to the default branch from another branch.
if ! is_default "$branch"; then
  if printf '%s\n' "$cmd" | grep -Eq "(:|[[:space:]])(main|master)([[:space:]]|$|;|&|\|)" \
     && printf '%s\n' "$cmd" | grep -Eq "push[^;&|]*[[:space:]](:?(main|master)|[^[:space:];&|]+:(main|master))([[:space:]]|$)"; then
    deny "kunal-push-safety: you are on '$branch' but this push targets the default branch. Push '$branch' to its own branch instead (git push -u origin $branch), or ask the user."
  fi
fi

# Upstream is the default branch while the local branch has another name.
upstream=$(git -C "$dir" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
if [ -n "$upstream" ]; then
  up_branch=${upstream#*/}
  if is_default "$up_branch" && [ "$branch" != "$up_branch" ]; then
    # A push that names its own destination explicitly is not affected by the upstream.
    if ! printf '%s\n' "$cmd" | grep -Eq "push[^;&|]*[[:space:]]-u[[:space:]]|push[^;&|]*--set-upstream|push[^;&|]*[[:space:]]${branch}([[:space:]]|$|;)"; then
      deny "kunal-push-safety: branch '$branch' tracks '$upstream', so a plain push would land on the default branch. Fix it first: git push -u origin $branch   (or git branch --set-upstream-to=origin/$branch if it already exists on the remote)."
    fi
  fi
fi

exit 0
