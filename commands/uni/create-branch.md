---
description: Create the RDNEW-XXXX feature branch and transition the Jira ticket to IN PROGRESS. Run after uni:fetch-ticket confirms understanding.
---

# /uni:create-branch — Branch Setup + Jira Transition

## Steps

### 0. Detect VCS
Read [.claude/rules/vcs-detection.md](../../rules/vcs-detection.md) and detect the VCS now. Carry the result into all subsequent steps.

### 1-Git. Check current branch (Git)
```bash
git branch --show-current
```
- Already on `RDNEW-XXXX-*` matching the ticket → skip branch creation, confirm to user
- Otherwise:
```bash
git checkout -b RDNEW-XXXX-short-description
```

Rules:
- Base off `main` — run `git branch` to confirm current base before creating
- Naming: lowercase, hyphens, ≤ 5 words after the ticket ID
- Examples: `RDNEW-4809-fix-puzzle-edit-groups`, `RDNEW-5001-add-workspace-user-type`

### 1-SVN. Check current working copy (SVN)
```bash
svn info | grep -E "^URL:|^Repository Root:"
```
- Already on a URL containing the ticket ID → skip creation, confirm to user
- Otherwise:
  - Derive the branch target URL: replace `/trunk` with `/branches/RDNEW-XXXX-short-description` in the current URL.
  - If the URL does not contain `/trunk`, ask (non-blocking): *"What is the branches parent path in this repo? (e.g. `^/branches`)"*
  - Create the branch and switch to it:
```bash
svn copy <trunk-url> <repo-root>/branches/RDNEW-XXXX-short-description \
  -m "RDNEW-XXXX - feat: Create feature branch"
svn switch <repo-root>/branches/RDNEW-XXXX-short-description
```

Rules:
- Naming: lowercase, hyphens, ≤ 5 words after the ticket ID (same convention as Git)
- Examples: `RDNEW-4809-fix-puzzle-edit-groups`, `RDNEW-5001-add-workspace-user-type`

### 2. Transition Jira → IN PROGRESS
Check CLI availability first:
```bash
command -v acli
```
- **CLI available** → `acli jira workitem transition --key <ID> --status "In Progress" --yes`
- **CLI not available** → use `getTransitionsForJiraIssue` to get the IN PROGRESS transition ID, then `transitionJiraIssue` to apply it

Skip silently if the ticket is already IN PROGRESS.
