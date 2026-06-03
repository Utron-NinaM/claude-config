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

## Agents

Use `file-explorer` (not `Explore`) for all codebase search and exploration tasks. `Explore` is disabled globally.

| Task | Agent |
|---|---|
| Find files by pattern | `file-explorer` (quick) |
| Find where a symbol/route is defined | `file-explorer` (quick) |
| Explore an unfamiliar part of the codebase | `file-explorer` (medium or very thorough) |

`file-explorer` uses only `Read`, `Glob`, and `Grep` — no Bash, no permission prompts.

---

## No Magic Numbers or Hardcoded Constants

Do not write numeric values, status codes, string keys, or other domain constants inline in code. Before writing any such value:
1. Check whether a named constant already exists for it.
2. If one exists — use it by name.
3. If none exists — create one first, then use it.

If the right file or scope for the new constant is not obvious, ask before placing it. Never use the raw value as a placeholder with intent to "name it later."