---
name: kunal-bug-repro
description: Use when fixing a bug, a failing test, a failing behavior, or a regression, or when the user says something is broken, before changing any code.
---

# Reproduce before you fix

A fix without a repro is a guess. Make the bug fail on purpose first, so the fix has something to prove.

## Relationship to other skills

If `superpowers:systematic-debugging` or `superpowers:test-driven-development` are available, use them for the investigation and test-writing craft. This skill sets the order and the report on top of them: repro first, watch it fail, fix, watch it pass, keep the test. If they disagree, this skill's order wins.

## Steps

1. **State the bug in one line.** Expected behavior, actual behavior, and where it was observed.
2. **Find the smallest trigger.** Strip the input, config, and steps down until the bug still happens. Read logs and the relevant code. Do not guess.
3. **Write the repro.** In order of preference:
   - A failing automated test in the project's own test setup, next to similar tests.
   - A one-command script or CLI call that prints the wrong result.
   - Exact manual steps, only if neither of the above is possible. Say so.
4. **Run it and watch it fail.** Show the real failing output. Check that it fails for the reason you think. If it passes or fails differently, the repro is wrong, so go back to step 2.
5. **Find the root cause.** Explain it in plain words. Do not fix the symptom (for example a try/catch that hides it).
6. **Make the smallest fix** that addresses that cause.
7. **Run the repro again** and show that it now passes. Then run the surrounding test suite to check nothing else broke.
8. **Keep the test.** A regression test stays in the repo. A throwaway script does not.

## Report

Give four things: the repro, the failing output, the root cause, the passing output. If you could not reproduce the bug, say so. Do not claim a fix.

## Never

- Claim a bug is fixed without running the repro after the change.
- Weaken or delete a test to make it pass.
- Fix several unrelated things in the same change.
