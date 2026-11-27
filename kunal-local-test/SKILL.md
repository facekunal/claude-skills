---
name: kunal-local-test
description: Use when asked to run, test, smoke-test, or verify an app locally, or to confirm a change works in the running app and not just in unit tests. Covers backend-only, frontend-only, full-stack, and custom setups (Python/uv, Node/TypeScript, Docker Compose).
---

# Local App Testing

## Overview

Prove a change works by running the real app and observing real output. Pick one mode, run its steps, and report evidence (commands, status codes, screenshots), not assumptions.

**Core principle:** discover how the project runs itself, then use its own commands. Do not invent a second convention.

## Step 1: Detect the mode

Read these before running anything: `AGENTS.md`/`CLAUDE.md`, `README.md`, `package.json` scripts, `pyproject.toml`, `Makefile`, `docker-compose*.yml`, `.env.example`.

| Signal | Mode |
|---|---|
| API/CLI/worker only, no UI assets | **Backend** |
| UI only, talks to a mocked or remote API | **Frontend** |
| Both a server and a UI in this repo, or compose with several services | **Full-stack** |
| None of the above, or user names a special setup | **Custom** |

If two modes fit, state which you chose and why in one line. Ask only if running the wrong one would be costly.

## Step 2: Shared preflight (all modes)

1. Use the project's package manager: `uv` for Python, the lockfile's manager for Node (`pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `yarn.lock` → yarn). Never add a second one.
2. Install deps with the canonical command (`uv sync`, `pnpm install`, ...).
3. Config comes from `.env` copied from `.env.example`. Never print secret values; show key names only. Never commit `.env`.
4. Check ports are free before starting: `lsof -i :<port>`. If taken, report what holds it; do not kill processes you did not start.
5. Docker: confirm the daemon is up (`docker info`; on this machine Colima: `colima status`, start with `colima start`).
6. Start long-running servers with `run_in_background`, redirect logs to the scratchpad directory, and poll a health endpoint rather than sleeping.
7. Stop everything you started when done (see Cleanup).

## Mode: Backend

1. Run the automated suite first (`uv run pytest`, `npm test`/`pnpm test`). Fix nothing yet; note failures.
2. Start dependencies (`docker compose up -d <db/cache services>`), wait for healthy.
3. Start the server (e.g. `uv run uvicorn app.main:app --port 8000`, `npm run dev`).
4. Poll the health route until it returns 200, with a timeout.
5. Exercise the changed behavior with `curl`/CLI: one happy path, one invalid input, one missing-auth or missing-data case. Record status code and a trimmed body.
6. Check the server log for tracebacks or unhandled errors.

## UI scenario list (Frontend and Full-stack modes)

Before driving the browser, write 3 to 6 scenarios from the diff (`git diff <base>...HEAD`) and show them to the user. Each scenario is one line: name, action, expected result. Always include the changed behavior's happy path, then add the relevant ones from this menu:

| Scenario | What to check |
|---|---|
| Empty state | No data or first-time user renders a sensible view |
| Invalid input | Empty or malformed fields show validation and do not submit |
| API error | Stub a 4xx/5xx or network failure (`page.route`); UI shows an error and does not crash |
| Loading | Slow response shows a spinner or skeleton; double-click does not double-submit |
| Navigation and state | Reload, back/forward, and deep links keep the right state |
| Auth | Logged-out access to a protected page redirects |
| Responsive | Layout works at about 390 px wide |
| Accessibility basics | Keyboard reachable, labels present, focus visible (use the snapshot's accessibility tree) |
| Cleanliness | No console errors, no failed requests |
| Boundary (full-stack only) | UI action sends the right API request, data persists, and survives a reload |

Skip menu items the diff cannot affect, and say which were skipped. Record pass or fail per scenario with a screenshot path.

## Saving scenarios as specs (optional)

Only when the user asks, or the repo already has Playwright specs (`playwright.config.*`, `tests/`, `e2e/`):

1. Convert only scenarios that passed into spec files, following the existing spec style, locators and folder. If none exist, ask before adding `@playwright/test` as a dependency.
2. Use role and label locators, not CSS selectors from the snapshot refs. Stub APIs with `page.route`. Do not hardcode secrets or real credentials.
3. Run the new specs with the project's runner (`npx playwright test <file>`) and confirm they pass before reporting them.
4. Keep `.playwright-mcp/`, `test-results/`, and `playwright-report/` out of git.

Otherwise leave no spec files behind.

## Mode: Frontend

1. Run unit/component tests and the type check/lint script if present.
2. Write the UI scenario list and show it.
3. Start the dev server in the background; wait for the URL to respond.
4. Drive each scenario with Playwright MCP: `browser_navigate`, `browser_snapshot` (prefer over screenshots for finding elements), interact, then `browser_take_screenshot` of the resulting state.
5. Read `browser_console_messages` for errors and `browser_network_requests` for failed calls.
6. Offer to save passing scenarios as specs.

## Mode: Full-stack

1. Bring up backing services, then the backend, then the frontend, in that order. Verify backend health before starting the UI.
2. Confirm the frontend points at the local backend (env var or proxy), not a remote one.
3. Write the UI scenario list, including the Boundary scenario, and show it.
4. Drive each scenario through the browser (Playwright MCP). The Boundary scenario crosses the stack: UI action → API call → persisted or returned data → UI update.
5. Verify both sides: the network request succeeded (`browser_network_requests`) and the backend log shows the matching request.
6. Run each side's own test suite as well, then offer to save passing scenarios as specs.

## Mode: Custom

1. Ask for, or find in the repo, the exact start command and success signal (log line, port, output file).
2. Run it with the same preflight and cleanup rules.
3. Define one observable pass condition before running, then check it.

## Reporting

End with a short table: what ran, command, result, evidence (status code, test counts, screenshot path). State plainly what was not verified (for example "auth flow untested") and any failure, with its output. Do not claim success without the evidence from this run.

## Cleanup

Stop background servers you started, `docker compose down` only for services you brought up (add `-v` only if asked), close the Playwright browser, and leave generated artifacts (`.playwright-mcp/`, logs) uncommitted. Check `git status` shows no stray files.

## Common mistakes

| Mistake | Fix |
|---|---|
| Declaring success from unit tests alone | Run the app and hit the changed path |
| Testing only the happy path in the UI | Write the scenario list first and cover error, empty and invalid cases |
| Saving specs that were never run or never passed | Run them with the project's runner before reporting |
| Sleeping a fixed time for startup | Poll health with a timeout |
| Frontend silently hitting a remote API | Check the base URL env var and network log |
| Leaving servers or containers running | Run Cleanup every time |
| Printing `.env` contents | Show key names only |
| Swapping package managers | Follow the lockfile and project docs |
