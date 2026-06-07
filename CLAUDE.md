# Global Claude Code Instructions

## Plan Display Behavior

When a new plan is created or updated within an existing session, display only the latest plan details. Do not show all previous plans combined — replace the prior plan view with the current one only.

## Code Quality: Best Practices Over Patches

Always prefer architecturally correct solutions over defensive workarounds. Before proposing a fix, identify the true root cause and fix it there — not downstream in its victims.

A patch is any fix that:
- Makes one component defensively handle a side-effect caused by a different component
- Adds conditional logic to work around caller behavior that the callee shouldn't need to know about
- Silently skips part of its normal behavior in certain states
- Leaves the original broken code path intact alongside the workaround

When a patch is what you've written, say so explicitly and explain what the proper fix would be instead. Only recommend a patch if the proper fix is genuinely not feasible (e.g., third-party code, migration risk, time constraint the user has stated). In that case, label it clearly as a temporary workaround and note what the long-term fix should be.

## No Assumption

Do not assume file paths, API shapes, data structures, user intent, or any value that can be verified or asked about. Before acting on something unknown:
- If it can be checked (file exists, symbol is defined, value is in the code) — check it with a tool first.
- If it cannot be checked — stop and ask the user. Do not guess and proceed.

What counts as an assumption that requires a check or question:
- A file path or import location that wasn't explicitly stated
- The shape or fields of an API response or Redux state
- Which enum value, constant, or config key applies to a given case
- User intent when the request is ambiguous (e.g., "fix this" without specifying what is wrong)

## Eliminate Duplicate Assignments Across Branches

When two branches of an if/else set the same fields on an object, extract those assignments outside the branch. Use null-coalescing to initialize a default, set shared fields once, then branch only on the action that differs.

**C# pattern:**
```csharp
var record = _repo.GetFirstOrDefault(x => x.Key == key)
    ?? new RecordDto { Key = key, CreatedDate = DateTime.UtcNow };
record.Field1 = value1;
record.Field2 = value2;
if (record.Id == 0) _repo.Add(record); else _repo.MergeAndSave(record);
```

**JS/React pattern:**
```js
const record = { ...(existing ?? { key, createdAt: new Date() }), field1: value1, field2: value2 };
existing ? update(record) : add(record);
```

Apply this to all languages and projects. Never duplicate field assignments across if/else branches when the fields are identical in both branches.

## Code Style: Braces

Always write `if`, `else`, `for`, `while`, and similar control-flow statements with curly braces, even when the body is a single line. No braceless one-liners.

```js
// ✅
if (isValid) {
    submit();
}

// ❌
if (isValid) submit();
```

This applies to all languages and projects.

## Agents

Use `file-explorer` (not `Explore`) for all codebase search and exploration tasks. `Explore` is disabled globally.

| Task | Agent |
|---|---|
| Find files by pattern | `file-explorer` (quick) |
| Find where a symbol/route is defined | `file-explorer` (quick) |
| Explore an unfamiliar part of the codebase | `file-explorer` (medium or very thorough) |

`file-explorer` uses only `Read`, `Glob`, and `Grep` — no Bash, no permission prompts.

When `file-explorer` (or any subagent) reads and fully reports on a file, do not re-read that file to verify. Treat the agent's output as authoritative and proceed directly to planning. Only do a targeted re-read if the report is ambiguous or contradicts itself on a specific detail.

### Skills & Task Routing

| Task | Use |
|------|-----|
| Verify a change works in the running app | `/verify` |
| Review a PR or diff for bugs | `/code-review` |
| Explore an unfamiliar part of the codebase | `file-explorer` (medium or very thorough) |
| Plan a multi-file feature before coding | `Plan` agent |
| Research a library or external API | `deep-research` agent |
| Find where a symbol/route/endpoint is defined | `file-explorer` (quick) |

---

## Skip Skills for Trivial Edits

Do not invoke a skill when the task is a mechanical file edit with no ambiguity. Use Read + Edit directly when the target file, the change, and the merge are all clear before the first tool call. Reserve skills for cases with genuine ambiguity (which file to target, complex merging logic, unfamiliar settings).

**This rule does NOT apply to workflow orchestration skills.** The following skills are process orchestrators — they must always be invoked via the Skill tool when their trigger condition is met, regardless of how simple the underlying action seems:

| Skill | Trigger |
|---|---|
| `uni:commit` | User says "commit" |
| `uni:create-branch` | End of PLAN phase approval |
| `uni:fetch-ticket` | Ticket ID mentioned at the start of a task |
| `uni:review-pr` | User asks to review changes / "it works" / "approved" |
| `uni:static-analyze` | User asks for static analysis |
| `uni:jira-comment` | User asks to add a Jira comment |
| `uni:jira-resolve` | User asks to resolve the ticket |

Never replace these with raw git commands, acli calls, or direct tool use — doing so silently skips the review, Jira, and cleanup steps they orchestrate.

---

## Dependency Injection: Circular Dependency Check

Before injecting service A into service B, check A's constructor for any dependency that leads back to B (directly or transitively). A single Grep of A's constructor is enough. Never recommend the injection without doing this check first.

## No Magic Numbers or Hardcoded Constants

Do not write numeric values, status codes, string keys, or other domain constants inline in code. Before writing any such value:
1. Check whether a named constant already exists for it.
2. If one exists — use it by name.
3. If none exists — create one first, then use it.

If the right file or scope for the new constant is not obvious, ask before placing it. Never use the raw value as a placeholder with intent to "name it later."

## Windows: No-BOM JSON and PowerShell from Bash

When writing JSON files on Windows for `acli` or similar CLI tools, use:
```powershell
[System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
```
The `$false` disables the BOM. Never use `Out-File -Encoding utf8` — it silently adds a BOM that causes `acli` to reject the file with "json: invalid format".

When running PowerShell commands from the Bash tool, always wrap with `powershell.exe -Command "..."`. Never use PowerShell variable syntax (`$env:TEMP`) directly in a Bash invocation — it fails silently with a syntax error.