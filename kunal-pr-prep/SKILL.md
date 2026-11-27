---
name: kunal-pr-prep
description: Use when the user asks to open, create, or prepare a pull request, or says "raise a PR", "make a PR", or "ship this branch". Never opens a PR before the user has approved the diff.
---

# PR prep

Never open a PR straight away. Show the user exactly what will go in it, wait for a yes, then create it.

## 1. Read the repo's rules first

Look for `CONTRIBUTING.md`, a PR template (`.github/pull_request_template.md`), and any "PR hygiene" section in `AGENTS.md` or `CLAUDE.md`. Follow them. If one says the PR description needs specific answers, include them.

## 2. Find the right base and repo

```bash
git remote -v
git branch --show-current
git rev-parse --abbrev-ref @{u} 2>&1
```

- With several remotes (`origin`, `upstream`), work out which repo the PR belongs in. A fork's PR usually goes to `origin`, but confirm.
- **Stacked PR?** If this branch builds on another open PR's branch, the base is that lower branch, not `main`. Check with `gh pr list -R <owner>/<repo> --head <lower-branch>`. After the lower PR merges, the base changes to `main`. For fixes on a stack, use kunal-stacked-pr-fixes.
- Bare `gh pr ...` can resolve to the wrong repo. Always pass `-R <owner>/<repo>`.
- Run kunal-push-safety before pushing.

## 3. Show the evidence and stop

```bash
git fetch <remote>
git diff --stat <remote>/<base>...HEAD
git log <remote>/<base>..HEAD --oneline
~/.claude/skills/kunal-secrets-check/scan.sh --base <remote>/<base>
```

The diff uses three dots on purpose. It compares against the merge base, so it shows only what this branch adds. Two dots would also show everything the base branch gained since you branched, as if you had removed it.

Show all three outputs. Point out anything that should not be in the PR: local config, `.claude/settings.local.json`, group or personal files, generated output. If the scan reports a BLOCK, stop. Then **wait for approval**.

## 4. Write the body

Write for a reviewer who has not seen this work:

- **What and why** in two or three sentences.
- **How it works**, only if it is not obvious from the diff.
- **How it was tested**, with the real commands and results. Do not claim tests passed if they were not run.
- **Risks / follow-ups**, if any.
- Link the issue (`Closes #N`).

## 5. Create it

Prefer a draft PR unless the user says otherwise.

```bash
gh pr create -R <owner>/<repo> --base <base> --head <branch> --draft --title "<title>" --body-file <file>
```

End the PR body with the attribution line given by the session's system reminder, if there is one.

Report the PR URL and the base and head used.
