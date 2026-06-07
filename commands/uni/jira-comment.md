# /uni:jira-comment — Add Comment to Jira Ticket

Adds a comment to the Jira ticket without changing its status.

## Steps

### 1. Identify the ticket
Read [.claude/rules/vcs-detection.md](../../rules/vcs-detection.md): detect VCS, then derive the branch name and ticket ID using the "How to derive the current branch name" section.

### 2. Compose the comment

Always use this fixed structure — no variations:

```
Branch: <current-branch-name>
Commit/Revision: <Git: short SHA from git rev-parse --short HEAD | SVN: r<N> from svn info | grep "^Revision:">

<commit subject line — RDNEW-XXXX - type(scope): description>

Summary
<content depends on ticket type — see rules below>

Changes
• <filename> — <what changed>
• <filename> — <what changed>
```

**Summary content rules by type:**

| Type | Summary content |
|------|----------------|
| `bug` | Root cause: \<what caused the bug\> / Fix: \<what was done\> |
| `feature` | \<what was added and why it's needed\> |
| `refactor` | Motivation: \<why the refactor was needed\> / \<what changed structurally\> |
| `chore` / `script` | \<what was done\> |

Derive ticket type from the commit subject line prefix. Derive content from the commit diff and plan file if available.

### 3. Check CLI availability and post
```bash
command -v acli
```

**acli available (preferred path):**

Write the comment body as plain text to a temp file (e.g. `.claude/jira-comment-<ID>.txt`), then post:
```bash
acli jira workitem comment create --key <ID> --body-file <path-to-file>
```
Delete the temp file after a successful post.

**acli not available** → use `addCommentToJiraIssue` MCP tool.
