# /uni:jira-resolve — Resolve Jira Ticket

Transitions the Jira ticket to RESOLVED.

## Steps

### 1. Identify the ticket
Read [.claude/rules/vcs-detection.md](../../rules/vcs-detection.md): detect VCS, then derive the branch name and ticket ID using the "How to derive the current branch name" section.

### 2. Transition to Done
Check CLI availability first:
```bash
command -v acli
```
- **CLI available** → `acli jira workitem transition --key <ID> --status "Done" --yes`
- **CLI not available** → use `getTransitionsForJiraIssue` to get the Done transition ID, then `transitionJiraIssue` to apply it
