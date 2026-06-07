# Claude Workflow — Team Guide

## Overview

| Layer | What it does | Lives in |
|---|---|---|
| **uni: skills** | Quality gates — fetch ticket, plan, static analysis, Jira, commit, handoff, and manual tools | `.claude/commands/uni/` |
| **sc: skills** | Thinking tools — brainstorm, design, troubleshoot, improve, cleanup | `.claude/commands/sc/` |
| **plans guides** | Per-type instructions — which sc: skills to run, then invoke `uni:plan` | `.claude/rules/plans/` |
| **security-guidance plugin** | Always-on security review — regex on every edit, LLM at end-of-turn | `.claude/security-patterns.yaml` |
| **CLAUDE.md** | Coding rules, restrictions, doc loading | `CLAUDE.md` |

**No per-developer setup required.** Everything is committed to the repo and loads automatically.

---

## Quick Start

### Start a new ticket
Mention the ticket number:
> "RDNEW-1234"

Claude will:
1. Run `uni:fetch-ticket` — fetch and summarize the ticket from Jira
2. Identify the plan type (`bug`, `feature`, `refactor`, `investigation`, `script`)
3. Load the matching type guide and run SC analysis (or skip if you say "write directly")
4. Run `uni:plan` — asks for any spec additions, then writes `.plans/RDNEW-1234.md` with Spec, Constraints, Tests, Steps, and After Implementation sections
5. Show the gate summary and wait — **say "proceed"**: `uni:plan` creates the branch automatically, then BUILD begins

### Resume an existing session
Any of these resumes where you left off:
- `"status"` / `"continue"` / `"where were we"`
- Mentioning any `RDNEW-XXXX` ticket number

Claude reads `.plans/<ticket>.md` frontmatter (`phase`, `step`, `next`) and jumps straight to the right point.

### Run uni:plan standalone
`uni:plan` works without a Jira ticket — pass a ticket ID, paste requirements, or describe the task in free-form. Useful for ad-hoc tasks or when Jira is unavailable.

---

## Phase Map

| Phase | What happens | Gate |
|---|---|---|
| **PLAN** | `uni:fetch-ticket` → type guide → SC analysis → `uni:plan` → `uni:create-branch` (auto on approval) | BLOCKING — say "proceed" |
| **BUILD** | implement plan steps | BLOCKING — per-step checkpoint |
| **SHIP** | `uni:commit` → each step is an offer: review-pr → commit → QA list → Jira comment → resolve → pitfalls check → cleanup | — |

**Exception — `investigation` type**: no branch, no SHIP phase. Findings go in the plan file itself.

**VCS support**: Git and SVN are both supported. Claude auto-detects which is in use; if ambiguous (both detected or neither), it asks before creating a branch or committing.

---

## PLAN Phase — Thinking by Type

Claude reads `.claude/rules/plans/<type>.md` and runs the appropriate SC analysis:

| Type | SC skill invoked |
|---|---|
| `bug` | `sc:troubleshoot --type bug --think` (or `--ultrathink` for multi-component) |
| `feature` (unclear approach) | `sc:brainstorm` → offers design or plan |
| `feature` (architecture needed) | `sc:design --type architecture --think-hard` |
| `feature` (1–2 files, clear scope) | skips SC, goes straight to `uni:plan` |
| `refactor` | `sc:improve` → `sc:cleanup` |
| `investigation` | `file-explorer` agent + `sc:troubleshoot` |
| `script` | skips SC, goes straight to `uni:plan` |

Every type guide ends with `uni:plan`, which writes the enriched plan file and shows the gate.

### What the plan file contains

`.plans/<ticket>.md` has these sections:

| Section | Contents |
|---|---|
| `## Spec` | Problem Statement, Requirements (FR1, FR2…), Acceptance Criteria |
| `## Constraints` | Non-obvious constraints affecting implementation |
| `## Tests` | <!-- TODO: define test guidance once a test framework is adopted --> |
| `## Steps` | Implementation steps tracked with ✓ / ← current; each step has the fields below |
| `## After Implementation` | Post-build verification items specific to this plan (empty if none apply) |
| `## Deviation Register` | Approved deviations that affect upcoming steps |

`investigation` and `script` types omit `## Tests` and `## After Implementation`.

Acceptance Criteria not present in Jira are derived from requirements and marked `[derived]` — review them before approving.

### Step format

Each step has these fields:

| Field | Required | What it's for |
|---|---|---|
| **Why** | Optional | Only present when the approach is non-obvious or a design choice was made over alternatives |
| **What** | Always | The atomic action to perform |
| **Touches** | Always | Files that will be modified |
| **Verification stubs** | Always | Plain-English tests tagged `(integration)` — ask user to run the app and verify behavior |
| **Risk** | Always | One line or "None" |
| **Mitigation** | If Risk ≠ None | What to do if the risk fires |
| **Deviations** | Filled at checkpoint | Written by Claude when the step is done |

---

## BUILD Phase

Claude implements plan steps one at a time. **Before starting each step**, Claude reads `## Deviation Register` and applies any unresolved entries targeting it. After every step:
- Verifies each stub: for `(integration)` stubs — asks user to run the app and observe behavior
- If any deviation occurred — **BLOCKING**: Claude states what deviated and why, asks for approval, waits before continuing
- Once approved, writes the deviation to the **Deviations** field; if it affects an upcoming step, also adds to `## Deviation Register`
- Marks Step N as `✓` in the plan body; marks any `## Deviation Register` entries targeting Step N as ✓ (resolved)
- Marks Step N+1 as `← current` in the plan body
- Updates frontmatter (`step=N+1`, `next=<title>`, `updated=<YYYY-MM-DD HH:MM>`)
- Outputs a checkpoint — **BLOCKING**:
```
Step N done: <title>
Plan updated: phase=BUILD, step=N+1, next=<title>
Tests: (integration) GREEN / TODO
Deviations: <None or description + reason>
Register: <entry added or "None">
Proceed to Step N+1? (ok / pause)
```
- `ok` → continue to next step
- `pause` → run `uni:handoff` then stop

After all steps, Claude works through `## After Implementation` items in order, then stops — you initiate the commit when ready.

### Always-on security plugin

Enabled via `.claude/settings.json` (`security-guidance@claude-plugins-official`), runs automatically:

| Layer | When | Catches |
|---|---|---|
| Regex patterns | Every file edit | Rules in `.claude/security-patterns.yaml` — hardcoded credentials, password-in-log |
| LLM reviewer | End of every coding turn | Web security patterns: XSS, injection, auth issues |
| Agentic reviewer | `git commit` | Cross-file vulnerabilities |

### uni:static-analyze

<!-- TODO: populate with ESLint (React/JS) analysis instructions -->

---

## SHIP Phase

When you're ready, say "commit" — `uni:commit` handles everything in order:

1. "Review-PR hasn't been run yet — want me to run it now?" → `uni:review-pr`
2. Reads every hunk of the staged diff, then suggests a tiered message per `.claude/rules/commit-format.md`. Commits and **reminds you to push manually.**
3. "Want me to generate a QA test list?" → `uni:qa-list`
4. "Want me to post a summary comment to the Jira ticket?" → `uni:jira-comment`
5. "Resolve the ticket?" → `uni:jira-resolve`
6. Marks the plan `phase: SHIP, step: done` silently (if a plan file exists)
7. Pitfalls check — if a genuinely non-obvious runtime constraint came up, offers to append one line to `docs/pitfalls.md`. Skipped if nothing surprising.
8. "Delete local plan and review files?" → cleanup

Every step is an offer — nothing is forced.

### uni:review-pr — How it works

`uni:review-pr` writes a structured review to `.claude/reviews/<branch>.md` and returns a one-line verdict.

**Confidence anchors** — every finding is marked:
- `·C` — clear evidence in the diff
- `·U` — plausible but uncertain

`LOW·U` and `INFO·U` findings are suppressed — they're noise.

**Priority tiers:**

| Tier | Meaning | Action |
|---|---|---|
| P0 | Security vulnerability, data loss, crash risk | Fix before merge |
| P1 | Build break, wrong runtime behavior, architecture violation | Should fix |
| P2 | Subtle bug risk, pattern violation | Consider fixing |
| P3 | Minor convention, readability | Notes only |

**Verdict scale:**

| Verdict | Condition |
|---------|-----------|
| `BLOCKED` | Any P0 finding |
| `NEEDS CHANGES` | Any P1 finding, no P0 |
| `MINOR TWEAKS` | Only P2/P3 findings |
| `READY TO MERGE` | Zero findings |

### uni:qa-list

Generates a QA handoff from the plan's `## Tests` section (if it exists) and changed files. Output is a plain test checklist with no internal technical details.

---

## Session Handoff

### Auto-resume without handoff

After every Step Checkpoint, the plan frontmatter is already updated. If you clear the conversation at a clean step boundary, just mention the ticket in a new session — Claude reads the frontmatter and resumes automatically.

When resuming a BUILD-phase plan, Claude checks `## Deviation Register` and shows a one-line digest of unresolved approved deviations (entries not yet marked ✓) before the first step (non-blocking — no re-approval needed):
> "Carrying forward N approved deviation(s): [list]"

### When handoff adds value

| Scenario | Frontmatter enough? | Need handoff? |
|---|---|---|
| Clean step boundary (checkpoint just ran) | ✅ Yes | Not really |
| Mid-step (stopped before checkpoint) | ❌ No | Yes |
| Forward-looking deviations exist | ✅ Yes — written to `## Deviation Register` | Not really |
| Long BUILD with many files touched | ❌ No | Yes |

### Triggers

| How | When |
|---|---|
| `pause` at a Step Checkpoint | Stops after the step, runs handoff |
| `"handoff"` / `"save progress"` / `"pause"` anywhere | Runs immediately |
| ~60–80% context reached | Claude offers once (non-blocking) |
| **Context compaction during BUILD** | PreCompact hook auto-injects an AUTO-HANDOFF TRIGGER |

`uni:handoff` writes a `## Handoff` section into `.plans/<ticket>.md` with files modified, deviations, and a ready-to-paste resume prompt. The resume prompt includes the full `## Deviation Register` so a new conversation has complete context. Copy it into a new conversation to pick up with full context.

---

## Full Skill Reference

| Phase | Skills |
|---|---|
| PLAN | `uni:fetch-ticket`, `uni:plan` (creates branch on approval), `sc:brainstorm`, `sc:design`, `sc:troubleshoot`, `sc:improve`, `sc:cleanup` |
| BUILD | — |
| SHIP | `uni:commit`, `uni:qa-list`, `uni:jira-comment`, `uni:jira-resolve` |
| Manual / Anytime | `uni:handoff`, `uni:review-pr`, `uni:security-review`, `uni:static-analyze`, `uni:log`, `uni:test-plan`, `uni:commit-only` |
