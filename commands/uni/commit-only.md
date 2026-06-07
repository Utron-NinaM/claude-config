# /uni:commit — Commit with Correct Format

## Steps

### 1. Detect VCS and read changes
Read [.claude/rules/vcs-detection.md](../../rules/vcs-detection.md) and detect the VCS now. Then:
- **Git** → read staged changes:
  ```bash
  git diff --cached --stat
  git diff --cached
  git status
  ```
  If nothing is staged, warn and stop: *"Nothing is staged — please `git add` the files you want to commit."*
- **SVN** → read all pending changes:
  ```bash
  svn status
  svn diff
  ```
  If `svn status` shows no modified or added files, warn and stop: *"No changes detected — nothing to commit."*
- **Both / Neither** → ask: *"Which VCS should I use for this commit — git or svn?"* Wait for answer.

**Read every hunk** in the diff — do not draft a message from filenames or conversation context alone.

### 2. Suggest commit message
Format spec: read [.claude/rules/commit-format.md](../../rules/commit-format.md) if not already in context.

Derive the ticket ID from the current branch name:
- **Git**: `git branch --show-current`
- **SVN**: `svn info | grep "^URL:"` → extract the last path segment after `/branches/`

Determine tier (trivial / standard / complex) per the triage table, then draft subject + body following the format.

Present the suggested message and ask: *"Commit message OK, or do you want to adjust it?"*

### 3. Commit
Once confirmed:
- **Git**: `git commit -m "RDNEW-XXXX - Short description"`
- **SVN**: `svn commit -m "RDNEW-XXXX - Short description"`

If the user says "don't commit" or skips the commit — skip steps 3 and 4 only, then continue to step 5.

### 4. Post-commit notice
- **Git**: *"Committed. Please review the diff and push manually — never ask Claude to push."*
- **SVN**: *"Committed. Changes have been sent directly to the SVN server — no push needed."*
