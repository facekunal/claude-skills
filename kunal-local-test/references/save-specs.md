# Saving scenarios as specs (optional)

Only when the user asks, or the repo already has Playwright specs (`playwright.config.*`, `tests/`, `e2e/`):

1. Convert only scenarios that passed into spec files, following the existing spec style, locators and folder. If none exist, ask before adding `@playwright/test` as a dependency.
2. Use role and label locators, not CSS selectors from the snapshot refs. Stub APIs with `page.route`. Do not hardcode secrets or real credentials.
3. Run the new specs with the project's runner (`npx playwright test <file>`) and confirm they pass before reporting them.
4. Keep `.playwright-mcp/`, `test-results/`, and `playwright-report/` out of git.

Otherwise leave no spec files behind.
