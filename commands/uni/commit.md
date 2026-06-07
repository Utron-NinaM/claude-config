# /uni:commit — SHIP phase: static-analyze → review → commit → QA list → Jira comment → resolve → cleanup

## Steps

### 0. Run static analysis and review-pr if not already done

**0a — Static analysis**: If `uni:static-analyze` has not been run for the current changes, ask:
> "Static analysis hasn't been run yet — want me to run it now before committing?"

**BLOCKING — stop here and wait for the user's reply. Do not proceed until they answer.**

User confirms → run `uni:static-analyze`. Fix all CRITICAL and HIGH findings before continuing.
User skips → continue.

**0b — Code review**: If `uni:review-pr` has not been run for the current changes, ask:
> "Review-PR hasn't been run yet — want me to run it now before committing?"

**BLOCKING — stop here and wait for the user's reply. Do not proceed to step 1 until they answer.**

User confirms → run `uni:review-pr`, then continue to step 1.
User skips → continue to step 1.

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

### 1.5. Retest prompt (if review or static analysis changed code)

If `uni:review-pr` or `uni:static-analyze` made any code changes during this SHIP phase, ask:
> "The code review / static analysis changed some code — please retest everything you verified earlier before I draft the commit message. Let me know when you're done."

**BLOCKING — stop here and wait for the user's confirmation before continuing.**

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


### 5. Offer QA test list
> "Want me to generate a QA test list to share with QA?"

User confirms → run `uni:qa-list`.
User skips → continue.

### 6. Offer Jira comment
> "Want me to post a summary comment to the Jira ticket?"

User confirms → run `uni:jira-comment`.
User skips → continue.

### 7. Offer resolve
> "Resolve the ticket?"

User confirms → run `uni:jira-resolve`.
User skips → continue.

### 8. Mark plan done (if exists)
Before offering cleanup, check if `.plans/<ticket>.md` exists:
```bash
ls .plans/<ticket>.md 2>/dev/null
```
- **Exists** → update its frontmatter: set `phase: SHIP`, `step: done`, `next: done`. Do this silently — no user prompt needed.
- **Not found** → skip silently (plan was never created or already deleted).

### 8.5 Pitfalls check (judgment call — do not skip mechanically)

Review what was discovered during this ticket. If a genuinely non-obvious runtime constraint, boot-sequence dependency, platform gotcha, or hidden invariant came up — something a fresh engineer would miss by reading the code alone — offer:
> "Worth adding to `docs/pitfalls.md`: \<one-line summary\>. Add it?"

User confirms → append the entry to `docs/pitfalls.md`.
User skips → continue.

**Skip entirely if nothing surprising came up.** No filler entries.

### 9. Offer cleanup
> "Delete local plan and review files?"
- `.plans/<ticket>.md` — always offer
- `.claude/reviews/<branch>.md` — offer only if the file exists
- Delete only what the user confirms; skip silently if files don't exist

### 10. Merge, push, and switch back

Find the base/source branch:
- **Git**: `git log --oneline --decorate -10` — look for the commit where the base branch tip diverges from the feature branch
- **SVN**: `svn log --stop-on-copy --limit 1 --verbose` — look for `A /path/to/feature (from /path/to/source:RXXXX)` in the changed paths

Ask before each sub-step — stop if the user declines any one.

**Step 10a** — *"Switch to `<base-branch>`?"*
- **Git**: `git checkout <base-branch>`
- **SVN**: `svn switch <source-branch-full-url>`

**Step 10b** — *"Merge `<feature-branch>` into `<base-branch>`?"*
- **Git**: `git merge <feature-branch>`
- **SVN**: `svn merge <feature-branch-full-url>`

If conflicts appear, stop and report them — do not auto-resolve.

**Step 10c** — *"Push `<base-branch>`?"*
- **Git**: `git push origin <base-branch>`
- **SVN**: `svn commit -m "RDNEW-XXXX - Merge feature branch into <source-branch-name>"`

Report: *"Merged and pushed. Now on `<base-branch>`."*

**Note: always continue from step 5 onwards**, even if the commit was skipped.
