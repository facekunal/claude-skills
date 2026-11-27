---
name: kunal-push-safety
description: Use before any `git push`, and when creating a branch from a remote ref (origin/main, upstream/main). Verifies the branch's upstream is the same-named branch and not main, so a push can never land on the default branch by accident.
---

# Push safety

A branch cut from `origin/main` with plain `checkout -b` tracks `origin/main`. A later `git push` then sends the commit straight to main. This has happened. Run these checks every time.

## Creating a branch

Always cut it with `--no-track`:

```bash
git checkout --no-track -b <name> origin/main
git push -u origin <name>
```

If the work belongs to an issue that already has a branch checked out, stay on that branch. Do not create a new one. Ask only if the current branch clearly belongs to different work.

## Before every push

Run and read the output:

```bash
git branch --show-current
git rev-parse --abbrev-ref @{u} 2>&1
git remote -v
```

Stop and tell the user if any of these is true:

- The upstream is `origin/main`, `origin/master`, or the repo's default branch, while the current branch is a different name.
- There is no upstream and the push command does not name the branch explicitly.
- The push would be a force push (`--force`, `--force-with-lease`) on a shared or stacked branch.
- The remote is not the one the user expects (for example `upstream` instead of `origin`).

If the upstream is wrong, fix it before pushing:

```bash
git branch --set-upstream-to=origin/<same-name-branch>   # branch exists on the remote
git push -u origin <name>                                # first push of a new branch
```

## Live-install checkouts

If the checkout is the running install (production host, service, or containers read from it), changing HEAD or committing there can break the next restart. Say so and ask before creating a branch, committing, or switching. Prefer a separate worktree (see kunal-worktree-task).

## Report

State the branch, its upstream, and the remote in one line before pushing, for example: `feat/x -> origin/feat/x (origin = hyvdotme/hyv)`. Push only after the user has seen it, unless they already told you to push.
