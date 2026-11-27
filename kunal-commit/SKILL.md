---
name: kunal-commit
description: Use when the user asks to commit, save, or checkpoint changes, or when a task is finished and the work needs committing. Not for opening a pull request (kunal-pr-prep) or pushing (kunal-push-safety).
---

# Commit

One focused commit, with the right files, in the repo's own style, after a secrets scan. Commit only when the user has asked for it, or when the task you were given includes committing.

## 1. Read the repo's commit rules

Check `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and `git log --oneline -15`. Follow the convention you find (for example concise imperative messages such as `Add PDF chunking pipeline`). If the repo has no convention, use a short imperative subject under about 70 characters.

## 2. Look at what changed

```bash
git status -sb
git diff --stat
git diff --cached --stat
```

Decide which files belong to this one change. Do not use `git add -A` or `git add .` when the working tree holds anything else. Name the files:

```bash
git add <file> <file>
```

Leave out, and point out to the user: unrelated edits, files that were already modified before you started, generated output, local config (`.claude/settings.local.json`, `.env`), and data folders the repo says not to commit. If one change is really two (for example a fix and a refactor), make two commits.

## 3. Scan for secrets

```bash
~/.claude/skills/kunal-secrets-check/scan.sh
```

On a BLOCK, stop and follow kunal-secrets-check. Do not commit.

## 4. Write the message

- Subject: what the commit does, in the imperative, in the repo's style.
- Body (only when the why is not obvious from the diff): one or two sentences on why, not a list of files.
- End with the attribution line given by the session's system reminder, if there is one.

Use a heredoc so the formatting survives:

```bash
git commit -m "$(cat <<'EOF'
<subject>

<optional body>

<attribution line, if any>
EOF
)"
```

## 5. Check the result

```bash
git show --stat HEAD
git status -sb
```

Report the short SHA, the subject, the files included, and what was left uncommitted on purpose. Never use `--no-verify` to get past a failing hook. If a hook fails, fix the cause and make a new commit. Do not `--amend` a commit that has already been pushed.

Do not push. Pushing goes through kunal-push-safety.
