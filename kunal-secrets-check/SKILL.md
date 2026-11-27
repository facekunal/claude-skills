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

## What to scan

The staged changes and the commits about to be pushed:

```bash
git diff --cached --name-only
git diff --cached -U0 | grep -nEi '(api[_-]?key|secret|token|passw(or)?d|private[_-]?key|bearer |authorization)' | sed -E 's/(=|:)[[:space:]]*.{4,}/\1 <redacted>/'
git diff <remote>/<base>..HEAD --name-only
```

Also look for these file names in the change set, whatever their content:

- `.env`, `.env.*` (except `.env.example` with placeholder values)
- `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `credentials*.json`, `service-account*.json`
- `settings.local.json`, `.npmrc`, `.netrc`, cloud config files with tokens

Known token shapes to flag: `AKIA...` (AWS), `ghp_` / `github_pat_`, `sk-` (API keys), `xox[bp]-` (Slack), `-----BEGIN ... PRIVATE KEY-----`, JWTs (`eyJ...`), long hex or base64 strings assigned to a key-like name.

If `gitleaks` or `trufflehog` is installed, run it as well and treat its findings as authoritative.

## If something is found

1. Stop. Do not commit or push.
2. Tell the user: file, line, and the type of secret, with the value redacted.
3. Offer to unstage (`git restore --staged <file>`) and to add the file to `.gitignore`.
4. If it was **already committed**, say so clearly. Removing it from the latest commit is not enough: the secret is in history, and a pushed secret should be treated as leaked and **rotated**. Do not rewrite shared history without the user's explicit approval.

## If nothing is found

Say what you scanned (staged files, N commits against `<base>`). Do not claim the change is "safe", only that the scan found nothing.
