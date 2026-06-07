# /uni:test-plan — Browser Test Plan

Generates a specific manual test checklist for execution in the browser.

---

## Instructions

Read [.claude/rules/vcs-detection.md](../../rules/vcs-detection.md) to detect the VCS, then get the changed files:
- **Git**: `git show --name-only --format="" HEAD`
- **SVN**: `svn log -l 1 --verbose` — extract the file list from the "Changed paths" block

Based on the diff, generate a **specific** checklist — not generic steps. Derive each item from what actually changed.

| Component changed | What to test |
|------------------|-------------|
| React screen / UI | Navigate to the screen, test each interactive control, verify display values update correctly |
| Service / ActionsService | Trigger the relevant operation, observe the result, check browser Network tab for the API call |
| Redux state | Verify the correct value appears in the UI after the action; check Redux DevTools if available |
| Form / wizard step | Submit with valid data, with missing required fields, and with boundary values |
| API request / response | Check Network tab for correct payload and response shape; verify error state renders correctly |
| Routing / auth change | Navigate to the route as each affected role; verify redirect behavior for unauthorized roles |

## Output format

```
Browser Test Plan — RDNEW-XXXX
================================
[ ] <specific action>: <expected result>
[ ] <specific action>: <expected result>
[ ] Check browser console for errors after each action
[ ] Test with roles: <list relevant roles if change is role-gated>
```

Present the checklist and say: *"Please run this in the browser and confirm when done."*
