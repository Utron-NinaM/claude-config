# /uni:qa-list — QA Black-Box Test List

Generates a user-facing test list for QA based on what changed. No internal details — written for someone testing the feature without knowing the code. Output is Jira wiki markup for direct paste.

---

## Instructions

### Step 1 — Get changed files

Read [.claude/rules/vcs-detection.md](../../rules/vcs-detection.md) to detect the VCS, then use the appropriate commands below.

**Default — full branch / all working copy changes:**

- Git: `git diff $(git merge-base HEAD main)...HEAD --name-only`
  (diffs everything since the fork point from `main` — captures all commits for the ticket)
- SVN: `svn status -q | awk '{print $2}'`
  (all locally modified, added, or deleted files in the working copy)

**If the user says "QA list for this commit only" / "just the last commit":**

- Git: `git show --name-only --format="" HEAD`
- SVN: `svn log -l 1 --verbose | grep "^   [AMD]" | awk '{print $2}'`

Use the per-commit mode when multiple tasks land on the same branch/working copy and the user wants a list scoped to the latest commit only.

### Step 2 — Check for a plan file

Look for `.plans/<ticket>.md` where the ticket matches the current branch name or a `RDNEW-XXXX` reference in the recent commit message.

**If plan found**: Read the `### Device / Black-Box` section under `## Tests`. Use those scenarios as the base list — they are spec-derived and already written for QA. Then enrich with any observable behaviors visible from changed files that are not already covered.

**If no plan found**: Infer the user-visible feature or behavior from changed files alone and generate the full list from scratch.

### Step 3 — Generate the list

Rules:
- No internal file paths, no Redux slice names, no component names, no technical implementation details
- Every item must be an observable action with a visible expected result
- Include happy path, edge cases, and error conditions
- Group by feature area or screen when multiple areas are affected
- Write as if the tester has never seen the code

## Output format

Plain text — paste directly into any Jira field:

```
QA Test List — RDNEW-XXXX: <title>

<Feature area / screen name>
* <user action> → <expected visible result>
* <user action> → <expected visible result>

Edge Cases
* <user action with boundary value or error condition> → <expected visible result>
* <user action> → <expected error message or fallback behavior>
```

Present the list and say: *"Paste this directly into the Jira ticket for QA."*
