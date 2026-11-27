---
name: kunal-worktree-task
description: Use when starting a side task, parallel work, or a risky change that should not touch the current checkout, and when giving subagents isolated worktrees. Creates a git worktree from an exact base commit, verifies it, and cleans up afterwards.
---

# Worktree for a task

A worktree is a second checkout of the same repo in another folder. Use it so work does not disturb the current branch, uncommitted changes, or a checkout that something else runs from.

## Ask first when

The current checkout is a live install (a service, host, or containers read from it) or has uncommitted work. Say what you plan to do and ask before creating or removing anything.

## Create

1. Decide the **base commit** and write it down as an exact SHA:
   ```bash
   git fetch origin
   git rev-parse origin/main        # or the feature branch the work builds on
   ```
2. Create the worktree on a new branch with no upstream tracking:
   ```bash
   git worktree add --no-track -b <task-branch> ../<repo>-<task> <base-sha>
   ```
3. **Verify** before editing anything:
   ```bash
   cd ../<repo>-<task> && git log -1 --oneline && git branch --show-current && git status -sb
   ```
   The HEAD must be the SHA from step 1. Tools that make worktrees for you can silently start from `main` instead of your feature branch, so always check.
4. Dependencies are not shared. Install them in the new folder if the task needs them, using the repo's own command and lockfile rules.

## Subagents in worktrees

- Put the **exact base SHA** in the subagent's prompt.
- Tell it to run `git log -1` and `git reset --hard <sha>` if HEAD differs, before editing.
- When taking its commits back, check that each commit's parent is that SHA (`git log --format='%h %p'`).

## Finish and clean up

1. Run the repo's checks inside the worktree. Read the output.
2. Push with kunal-push-safety. Check the branch's upstream first.
3. Remove it once the work is merged or abandoned:
   ```bash
   git worktree remove ../<repo>-<task>
   git branch -d <task-branch>      # -D only if the work was cherry-picked, and tell the user
   git worktree prune
   ```
4. Delete leftover agent branches (`worktree-agent-*`) after their commits are applied.

Never remove a worktree that has uncommitted changes without showing them to the user first.
