# UI scenario list (Frontend and Full-stack modes)

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
