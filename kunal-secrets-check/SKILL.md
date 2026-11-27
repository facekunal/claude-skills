---
name: kunal-secrets-check
description: Use before any git commit, push, or pull request, and whenever reading or showing config or env files. Scans what is about to be committed for API keys, tokens, private keys, and .env content, and never prints a secret value.
---

# Secrets check

## Hard rules

- **Never print a secret value**, not in chat, not in a command's output, not in a PR body, not in a log you create. Report the file, the line number, and the kind of secret only.
- Do not `cat`, `head`, or `grep -n` a `.env` file in a way that shows values. To check what keys exist, list names only:
  ```bash
  sed 's/=.*//' .env
  ```
- Do not send secrets to any outside service or tool.

## Enforced by a hook as well

`hook.sh` in this folder runs `scan.sh` before every `git commit` (staged files) and `git push` (commits against the upstream), and denies on BLOCK findings only. It is wired in `~/.claude/settings.json`. Limits: it cannot see files that `git commit -a` or a `git add … && git commit` in the same command stage at run time, and it fails open when the repo path comes from a shell variable. The push check catches those once they are committed. Keep running the scan yourself before committing.

## What to scan

Run the bundled script from inside the repo. It scans the staged changes, and with `--base` also the files changed in the commits about to be pushed:

```bash
~/.claude/skills/kunal-secrets-check/scan.sh                      # staged changes
~/.claude/skills/kunal-secrets-check/scan.sh --base <remote>/<base>   # staged + commits about to be pushed
```

It prints only `LEVEL file:line kind`. It never prints a matched value, so its output is safe to show. Do not replace it with a raw `git diff | grep`, because that prints the secret into the session before any redaction.

- **BLOCK** (exit 1): real token shapes (AWS `AKIA…`, `ghp_`/`github_pat_`, `sk-`, Slack `xox[bp]-`, two-part JWTs, private-key headers) and forbidden file names (`.env` and `.env.*` except `.env.example`, `*.pem`, `*.key`, `*.p12`, `id_rsa*`, `credentials*.json`, `service-account*.json`, `settings.local.json`, `.npmrc`, `.netrc`).
- **WARN** (exit 0): a key-like name (`api_key`, `secret`, `token`, `password`) assigned a long value. Look at each one by file and line, without printing the value, and decide.

Untracked and unstaged files are not scanned. Stage the files first, or check them by name.

If `gitleaks` or `trufflehog` is installed, run it as well and treat its findings as authoritative.

## If something is found

1. Stop. Do not commit or push.
2. Tell the user: file, line, and the type of secret, with the value redacted.
3. Offer to unstage (`git restore --staged <file>`) and to add the file to `.gitignore`.
4. If it was **already committed**, say so clearly. Removing it from the latest commit is not enough: the secret is in history, and a pushed secret should be treated as leaked and **rotated**. Do not rewrite shared history without the user's explicit approval.

## If nothing is found

Say what you scanned (the script prints the file counts). Do not claim the change is "safe", only that the scan found nothing.
