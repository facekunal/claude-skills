---
name: kunal-stacked-pr-fixes
description: Use when addressing review comments on a stacked PR series (PR B based on PR A, and so on). All fixes go as new commits on the top branch; lower branches are never edited, rebased, or force-pushed.
---

# Fixes in a stacked PR series

In a stack (`A <- B <- C`), a fix committed into a lower branch forces a rebase and force-push of every branch above it. That disturbs the whole stack, so do not do it.

## Rule

Every fix goes as a **new commit on the top branch of the stack**, even when the review thread is on a lower PR. Lower PRs carry the bug until the top PR merges.

## Steps

1. Identify the stack and its top branch. Check each PR's base branch with `gh pr view <n> -R <owner>/<repo> --json baseRefName,headRefName`.
2. Check out the top branch at its remote head:
   ```bash
   git fetch origin
   git checkout <top-branch>
   git status -sb          # must show it is up to date with origin/<top-branch>
   ```
3. Read each review comment. Group them as must-fix, needs discussion, or not applicable. Give your reasoning before changing code.
4. Make one focused commit per fix, or per tightly related group. The message names the PR it answers. Follow the repo's own commit convention (check `AGENTS.md`, `CONTRIBUTING.md`, and `git log`). If the repo has none, use something like `Fix empty list handling (review on #422)`.
5. Run the checks the repo requires (tests, typecheck, lint) and read the results.
6. Push normally. **No `--force`, no `--force-with-lease`.** If the push is rejected, stop and tell the user. Do not force.
7. Reply on each thread, including threads on lower PRs, with the commit SHA and the PR it landed in:
   ```bash
   gh api -X POST repos/<owner>/<repo>/pulls/<pr-number>/comments/<comment-id>/replies -f body="Fixed in <sha>, landing in #<top-pr>."
   ```
   Get the `<comment-id>` from `gh api repos/<owner>/<repo>/pulls/<pr-number>/comments`. Do not resolve threads on someone else's review. Let the reviewer do that.

## Never

- Commit to a lower branch.
- Rebase or restack branches.
- Force-push any branch in the stack.

If a fix truly cannot work unless a lower branch changes, stop and ask the user. Explain why.
