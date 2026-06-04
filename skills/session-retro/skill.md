---
name: session-retro
description: Post-session retrospective that analyzes the completed conversation to surface improvements for the next session. Examines user prompts for missing context, ambiguity, and incremental scope creep; examines Claude's approach for redundant tool use, unnecessary exploration, verbosity, and wrong-first-try pivots. Outputs actionable "do this differently" recommendations split by USER and CLAUDE, plus a starter-prompt template for the next similar task. Trigger on phrases like "what could be done better", "session retrospective", "retro", "analyze this session", "how to improve next time", "session review", "make the next session faster", "session feedback", "review our session", "post-session analysis".
---

You are a session quality analyst. Analyze the completed conversation to surface concrete improvements for the next similar session. Work through every step in order.

---

## Step 1 — Characterize the session

From the conversation already in context, extract:

- **Main task(s):** What was the user trying to accomplish?
- **Turns:** Approximate count of user/Claude exchanges
- **Outcome:** Completed / partially done / abandoned
- **Rework cycles:** How many times did Claude produce output that had to be redone, corrected, or rolled back?

Output a 3–5 line summary. Example:
> Task: Add puzzle-update endpoint with IoT hub integration. 12 exchanges. Completed. 1 rework cycle (wrong service layer — pivoted after user correction).

---

## Step 2 — USER-side signals

Review every user message. For each pattern found, write one finding using the format below. Skip patterns not present.

**What to look for:**

- **Missing file paths** — Claude had to explore for files the user already knew about.
- **Missing domain context** — Claude asked a clarifying question that a single sentence in the opening prompt would have answered.
- **Ambiguous intent** — Claude guessed what the user meant and guessed wrong. Evidence: user corrections starting with "no", "not that", "I meant", "that's not right".
- **Incremental scope creep** — user added requirements mid-task that were logically part of the original request, causing rework or tack-on steps.
- **Assumed workflow knowledge** — user gave a short command without stating constraints Claude needed (which layer to touch, pattern to follow, what to avoid).
- **Missing reproduction steps** — for bug tasks: symptom described without a reproduction path, forcing Claude to guess the root cause.
- **Missing definition of done** — no clear acceptance criteria, so Claude had to infer when to stop.

**Finding format:**
```
[USER] <short title>
What happened: <one sentence>
What to do instead: <concrete prompt addition or snippet for next time>
Cost: ~N turns | ~N tokens
```

---

## Step 3 — CLAUDE-side signals

Review Claude's messages and tool calls. For each pattern found, write one finding. Skip patterns not present.

**What to look for:**

- **Redundant file reads** — same file read more than once with no intervening change.
- **Over-exploration** — search agent spawned or multiple Glob/Grep calls made when one targeted read would have sufficed.
- **Sequential instead of parallel** — independent tool calls ran one at a time (no data dependency between them).
- **Unnecessary clarification question** — Claude asked something it could have answered by reading the code or by proceeding with a stated assumption.
- **Verbose response** — Claude narrated *what* it just did at length (the diff already shows that).
- **Wrong-first approach** — Claude chose a pattern or layer that turned out to be wrong and had to pivot. What signal was present but missed?
- **Over-engineered solution** — abstractions, error paths, or generics introduced that the task did not require.
- **Magic number / missing constant check** — Claude wrote an inline value without first checking whether a named constant existed.
- **Agent over-delegation** — subagent spawned for a task simple enough to handle inline (one Glob or Grep).
- **Assumption without verification** — Claude stated a file path, API shape, or field name without checking it first.

**Finding format:**
```
[CLAUDE] <short title>
What happened: <one sentence>
Root cause: <why — ambiguous prompt, code not read before acting, wrong heuristic>
Next time: <what Claude or the user should do differently>
Cost: ~N tokens
```

---

## Step 4 — Correctness gaps

Did the final result have quality gaps? Check for:

- **No verification run** — code was written but `dotnet build` / `npm run` was not confirmed
- **Tests skipped** — behavior changed but no tests were run or written
- **Edge cases unaddressed** — a path the task implied was left unhandled
- **"Done" claimed prematurely** — Claude declared completion without an integration check or app run

For each gap: state what verification step should have been added and at which point.

If none: write "No correctness gaps detected."

---

## Step 5 — Output the retrospective report

Use this exact structure:

---

## Session Retrospective

### Session Summary

[3–5 lines from Step 1]

---

### USER Findings

[All [USER] findings from Step 2, sorted by cost descending — highest turns/tokens wasted first]

If none: "No user-side inefficiencies detected."

---

### CLAUDE Findings

[All [CLAUDE] findings from Step 3, sorted by cost descending]

If none: "No Claude-side inefficiencies detected."

---

### Correctness Gaps

[From Step 4]

---

### Next Session — Starter Prompt

Based on the findings, draft an opening prompt the user could use for the *next* similar task. Use `[...]` placeholders for parts the user must fill in. Include only what was *missing* from this session's opening — don't pad it with things that were already provided.

Example shape:
> "I need to [task]. Relevant files: [list]. Constraints: [pattern / what to avoid]. Definition of done: [specific criteria]."

---

### Top 3 Actions

The 3 highest-impact changes, one sentence each:

- [ ] [USER] ...
- [ ] [CLAUDE] ...
- [ ] [USER or CLAUDE] ...

---

## Step 6 — Save to log

Get the current timestamp:
```bash
powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"
```

Compose an entry header:
```
---
## Retro — <YYYY-MM-DD HH:MM> | <short project name>
<task summary — one line>

```

Read **`C:\Users\ninam\.claude\session-retro-log.md`** (treat as empty string if missing). Prepend the new entry + full report from Step 5, then write the file with the Write tool (not Bash).

Confirm: `✓ Saved to ~/.claude/session-retro-log.md`
