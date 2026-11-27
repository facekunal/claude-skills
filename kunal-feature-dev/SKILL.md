---
name: kunal-feature-dev
description: Use at the start of any feature development task - building a new feature, finishing a partly built one, or a multi-file change. Sonnet stays the main model and does the steady work; stronger models (Opus, Fable) are consulted at fixed checkpoints, and Haiku subagents do search and gathering. Covers audit, plan, slices, implement, wiring check, and a done check.
---

# Feature development with model routing

The main session model (normally Sonnet) does the steady work. It does not trust its own judgment at the risky points. Stronger models are used at **fixed checkpoints**, and cheap models gather facts.

**Standing authorization:** the user has authorized subagents for the delegation steps in this skill (Haiku gathering, Opus/Fable consults). Use them without asking again. Do not spawn agents for anything else.

## 0. Announce

Start with one line naming the task type and the routing, for example:
`Feature dev: Sonnet does the work, Haiku gathers, Opus/Fable review the plan and the final diff.`
Every later delegation also gets a one-line announcement (`Delegating: <task> -> <model>`), so the user can see that the routing happened.

## 1. Audit: what exists, what is missing

Find the spec (issue, plan doc in `docs/`, PR description, branch commits). Build a table of:
requirement | in code? (`file:line`) | tested? | status (done / partial / missing).

For a big area, send the *looking* to Haiku subagents (`model: haiku`) and keep the *judging* on the main model. Verify any claim a decision depends on by reading the cited lines yourself. Haiku finds and summarizes, it does not decide.

## 2. Find the pattern

Before writing code, find the 2-3 closest existing features. List the conventions to copy: file layout, registration points, naming, error handling, test style. Check the repo's own docs (`CLAUDE.md`, `CONTRIBUTING.md`, `docs/`) for rules that apply to this change. Follow them. If a repo rule needs a design check (for example a main-thread or performance constraint), do that check now.

## 3. Plan and slice

Split the work into the smallest slices that each work end to end. Order them by dependency. For each slice: what changes, which files, how it will be tested.

**CHECKPOINT A - plan review (mandatory).** Before writing code, get the plan reviewed by a stronger model: call `advisor` (it sees this whole conversation). For a standalone design question, use a subagent with `model: opus` or `model: fable` and a complete brief. Apply the feedback or tell the user why you disagree.

## 4. Implement, one slice at a time

- Write the smallest change for the slice, in the repo's style.
- Add or update the test in the same slice. For bug-shaped problems follow kunal-bug-repro.
- Run the repo's checks and read the output. Commit per slice if the user wants commits.
- Before any push follow kunal-push-safety. Before any commit or PR follow kunal-secrets-check.

**CHECKPOINT B - escalate, don't grind (mandatory).** Consult Opus/Fable (advisor or subagent) when any of these is true:
- a design choice between two approaches
- the cause of a bug is still unclear after one attempt
- the slice touches security, concurrency, migrations, auth, money, or data deletion
- the same error appears twice, or the approach is not converging

If the work becomes mostly judgment and little typing, tell the user: "This needs a stronger main model. Consider `/model opus` (or `/model fable`)." The user decides. A skill cannot switch the main model.

## 5. Wiring check

For the feature, search for every place a similar feature is registered: commands, routes, config keys, migrations, docs, index files, tests, barrels. Haiku subagents may do this search. List what is wired and what is missing. Fix the gaps.

## 6. Done check

**CHECKPOINT C - final review (mandatory).** Run tests, typecheck, and lint, and read the real output. Then re-read the original request and check each requirement against the diff. Call `advisor` for a review of the diff before saying the work is done.

Report: requirements met (with evidence), requirements not met, checks run and their results, anything skipped. Never say "done" if a check was not run or failed.

## Writing a subagent brief

Subagents do not see this conversation. Every brief must contain:
- the goal and why it matters, in two sentences
- exact paths, branch name, and base commit SHA when files are involved
- the precise question, and the form of the answer (a table, `file:line` list, a yes/no with reasons)
- limits: read-only unless stated, do not push, do not touch other files
- "report what you could not verify"

A thin brief gives bad work. Check every result before relying on it.

## Model guide

| Work | Model |
|---|---|
| search, list call sites, summarize logs, mechanical find-all-places | Haiku (`model: haiku`) |
| reading code, edits, tests, commits, PR text | main model (Sonnet) |
| plan review, design choices, hard root causes, risky-area review, final diff review | Opus or Fable (`advisor`, or subagent with `model: opus` / `model: fable`) |

Rule behind it: use the weakest model whose mistakes you would notice. A wrong search result is obvious. A subtly wrong design is not.
