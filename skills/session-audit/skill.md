---
name: session-audit
description: Audit the current Claude session for context and token efficiency. Reads all loaded config files (global CLAUDE.md, project CLAUDE.md, rules, memory), measures their token cost, scans the current conversation for waste patterns, and outputs a prioritized improvement report split by owner: USER (prompt habits), SKILL/CONFIG (files to edit), MEMORY (entries to fix/remove), APP (Claude behavior observations). Trigger on phrases like "audit my session", "session health check", "review context usage", "optimize tokens", "what's wasting tokens", "how to save tokens", "improve my prompts", "token efficiency", "context audit", "session review", "analyze my context", "token usage report".
---

You are a Claude session efficiency auditor. Execute all four steps in order. Never skip a step.

Token estimate formula used throughout: **ceil(char_count / 4)**.

---

## Step 1 — Measure loaded context sources

Read every file below. Record its character count and estimated tokens. If a file does not exist, mark tokens as 0.

**Always-loaded (every turn of every session):**

1. Global CLAUDE.md — `C:\Users\ninam\.claude\CLAUDE.md`
2. Memory index — find the project memory directory under `C:\Users\ninam\.claude\projects\` whose name matches the current working directory path, then read `memory\MEMORY.md`. Also read every `.md` file linked from that index (each linked file is a separate row).
3. Project CLAUDE.md — `<cwd>\CLAUDE.md`
4. All rules files — every `.md` under `<cwd>\.claude\rules\` (recurse subdirectories, one row per file)

**Loaded on skill trigger only (measure anyway, mark column as "on trigger"):**

5. Every `skill.md` under `C:\Users\ninam\.claude\skills\` (one row per file)

Output a table:

| Source | Shortened path | Est. tokens | When loaded |
|--------|---------------|-------------|-------------|
| Global CLAUDE.md | ~/.claude/CLAUDE.md | N | Always |
| Memory index | memory/MEMORY.md | N | Always |
| Memory: \<name\> | memory/\<file\>.md | N | Always |
| Project CLAUDE.md | CLAUDE.md | N | Always |
| Rule: \<name\> | .claude/rules/\<name\>.md | N | Always |
| Skill: \<name\> | ~/.claude/skills/.../skill.md | N | On trigger |
| **Baseline total** | *(always-loaded only)* | **N** | |
| **Worst-case total** | *(all skills triggered once)* | **N** | |

Also note: system overhead (deferred tools list, session environment, built-in instructions) adds roughly **3,000–5,000 tokens per turn** and is not reducible by the user.

---

## Step 2 — Scan this session's conversation for waste signals

Review the conversation history already in your context window. For each pattern found, write one line describing it with a brief quote or turn reference to anchor it:

- **Clarification round-trip** — Claude asked a follow-up that a more specific initial prompt could have prevented.
- **Repeated file read** — the same file was read more than once with no intervening changes.
- **Explore agent that could have been skipped** — an Explore subagent was spawned but the user could have named the relevant files directly.
- **Large tool output, partially used** — a tool returned hundreds of lines but only a few were relevant to the answer.
- **Scope correction / rework** — a task was substantially redone after Claude misunderstood the request.
- **Parallel search duplication** — Claude and a subagent both searched for the same symbol or file.
- **Skill over-trigger** — a skill was activated when it was not appropriate, consuming its full token load.

If none found, write: "No waste patterns detected in this session."

---

## Step 3 — Analyze each file for improvement opportunities

For each file measured in Step 1, examine its content and flag issues in these categories:

**Rules and CLAUDE.md files:**
- Content that duplicates Claude's training knowledge (general best practices, standard patterns Claude already knows without being told). Flag the specific section.
- Content that belongs in project scope but lives in the global file, or vice versa.
- Stale or outdated content (references removed features, old file paths, superseded decisions).
- Sections that are always loaded but only relevant to one rare workflow.

**Skill files:**
- Trigger `description` so broad it may activate unintentionally (vague phrases that match many tasks).
- Body length out of proportion with task complexity.
- Instructions duplicated across multiple skill files (DRY violation).
- Steps that ask Claude to do something it could infer without being told.

**Memory files:**
- Entries that describe something directly readable from code (file paths, function signatures, class names, patterns). These violate the memory policy and should be removed.
- Entries that are ephemeral state (now-completed tasks, in-progress work, current PR).
- Duplicate or near-duplicate entries.
- Entries with no `Why:` / `How to apply:` line for feedback/project types (degrades usefulness).

---

## Step 4 — Output the full report

Use this exact structure:

---

## Session Audit Report

### Token Budget

[paste the table from Step 1]

**Baseline (every turn):** N tokens  
**Worst-case (all skills triggered):** N tokens  
**System overhead (not reducible):** ~3,000–5,000 tokens

---

### This Session — Efficiency Signals

[list from Step 2, or "No waste patterns detected."]

---

### Findings

Sort findings by estimated impact — highest token savings or most clarification turns saved first.

For each finding, use this format:

#### [LABEL] Short title

Labels: `[USER]` = how you prompt | `[SKILL]` = edit a skill file | `[CONFIG]` = edit a CLAUDE.md or rules file | `[MEMORY]` = fix or remove a memory entry | `[APP]` = Claude/agent behavior observation (meta-feedback, not directly actionable)

> **Impact:** ~N tokens per session | saves N clarification turns  
> **Problem:** What is wrong. Quote the specific excerpt if applicable.  
> **Fix:** Concrete action. For `[SKILL]` and `[CONFIG]` fixes, show a brief before/after snippet if the change is non-obvious.

---

### Quick Wins

The 3 highest-impact, lowest-effort fixes as a checklist. Each should take under 5 minutes.

- [ ] Fix 1
- [ ] Fix 2
- [ ] Fix 3

---

### APP Observations

List any `[APP]` findings here separately. These are meta-observations about Claude's behavior in this session — patterns worth noting but not directly fixable by the user through config changes. Each observation should be specific (not "Claude was slow") with a concrete example from the session.

If none, write: "None observed."

---

## Step 5 — Append report to the audit log

The audit log lives at: **`C:\Users\ninam\.claude\session-audit-log.md`**

All sessions share this single file. Newest entries go at the top.

**5a.** Run this command to get the current timestamp:
```bash
powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"
```

**5b.** Get the current working directory (already known from session context; use `pwd` via Bash if needed to confirm).

**5c.** Compose the entry header:
```
---
## Audit — <YYYY-MM-DD HH:MM> | <cwd>

```
Then append the full report from Step 4 (everything from "### Token Budget" through the end of "### APP Observations").

**5d.** Read the existing log file. If it does not exist, treat its current content as an empty string.

**5e.** Write the log file with the new entry prepended before the existing content:
```
<new entry header + report>

<existing file content>
```

Use the **Write** tool (not Bash echo/redirect) so the full content is written atomically.

**5f.** Confirm to the user: `✓ Report appended to ~/.claude/session-audit-log.md`
