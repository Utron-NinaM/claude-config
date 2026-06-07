# VCS Detection

## How to detect the VCS

Check the working directory (and parent directories if needed):

1. `.git` folder or file present → **Git**
2. `.svn` folder present → **SVN**
3. Neither found → run `git rev-parse --is-inside-work-tree 2>$null` — if exit code 0 → **Git**
4. Still nothing → stop and ask the user which VCS is in use

## How to derive the current branch name

**Git:**
```bash
git rev-parse --abbrev-ref HEAD
```
Ticket ID is the branch name itself (e.g. `PROJ-1234-add-feature` → ticket `PROJ-1234`).

**SVN:**
```bash
svn info | grep "^URL:"
```
Parse the branch name from the URL:
- `…/branches/PROJ-1234-description` → branch `PROJ-1234-description`, ticket `PROJ-1234`
- `…/trunk` → branch `trunk`, no ticket

## How to get changed files

**Git** (staged only — for commit context):
```bash
git diff --cached --name-only
```

**Git** (branch vs base — for review/PR context):
```bash
git diff --name-only $(git merge-base HEAD main)
```
> Adjust `main` to match the actual base branch for the repo.

**SVN:**
```bash
svn status | grep "^[ADMRC]" | awk '{print $2}'
```
