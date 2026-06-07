# PRD Creation Workflow — Team Guide

This guide explains how to use the Claude Code skills in `.claude/skills/` to go from a raw idea to a developer-ready ticket with full acceptance criteria.

---

## What Are Skills?

In Claude Code, **Skills** are structured markdown playbooks (`SKILL.md`) that lock Claude into a disciplined workflow. Instead of free-form prompting, each skill enforces defined phases, gates, and output formats. This shifts Claude from a passive text generator into an active, opinionated collaborator.

---

## The Workflow at a Glance

```
Raw idea / rough notes
        │
        ▼
  1. /grill-me          ← Discovery: stress-test the idea, one Q at a time
     /grill-with-docs   ← (variant: same interview + updates CONTEXT.md / ADRs inline)
        │
        ▼
  2. /to-prd            ← Documentation: synthesize → publish PRD (parent ticket)
        │
        ▼
  3. /to-issues         ← Execution planning: break PRD into vertical-slice child tickets
        │
        ▼
  4. /close-the-gaps    ← Refinement: hunt gaps → Gherkin ACs → refined ticket
     (run on each          (repeat per child ticket)
      child ticket)
        │
        ▼
  Child tickets are dev-ready ───────────────────────────────────────────────────┐
                                                                                 │
  Optional quality gates (run before handing to dev):                            │
  /zoom-out                  ← anytime you need to orient in unfamiliar code     │
  /improve-codebase-         ← before large features; find shallow modules       │
  architecture                                                                   │
                                                                                 │
  ── Handoff to developer workflow ───────────────────────────────────────────►  │
  uni:fetch-ticket → uni:plan → BUILD phase                                      ┘
```

---

## Skill Reference

### 1. `/grill-me` — Discovery

**What it does:**
Flips the dynamic. Claude becomes the interviewer. It walks every branch of the decision tree, asking one question at a time and always providing its own recommended answer. If a question can be answered by reading the codebase, it reads the codebase instead of asking you.

**Why it's valuable:**
Prevents vague planning. You can't fake your way through it — edge cases, trade-offs, and dependencies all surface before a single word of PRD is written. The one-question-at-a-time discipline prevents overload and keeps decisions explicit.

| | |
|---|---|
| **Input** | Raw idea or rough design (typed or pasted in chat) |
| **Output** | Shared understanding recorded in conversation context |
| **Invoke** | `/grill-me` |

---

### 1b. `/grill-with-docs` — Discovery with Docs

**What it does:**
Same relentless one-question-at-a-time interview as `/grill-me`, but with two extra responsibilities: it challenges your language against an existing `CONTEXT.md` glossary (if one exists), and it updates that glossary — and creates ADRs — inline as decisions crystallise. If no `CONTEXT.md` exists yet, it creates one lazily when the first term is resolved.

**Why it's valuable:**
Prevents terminology drift across the codebase. When you describe a plan using a word that conflicts with the established glossary, it catches the conflict immediately. The session leaves a durable documentation trail rather than just shared understanding in conversation context.

**ADR (Architecture Decision Record):** A short document that captures a single architectural decision — what was decided, why, and what alternatives were rejected. Stored in `docs/adr/`.

**ADR creation rule:** An ADR is only written when all three are true: the decision is hard to reverse, surprising without context, and the result of a real trade-off. If any condition is missing, no ADR is created.

| | |
|---|---|
| **Input** | Raw idea or rough design (typed or pasted in chat) |
| **Output** | Shared understanding + updated `CONTEXT.md` + ADRs (as needed) |
| **Invoke** | `/grill-with-docs` |

---

### 2. `/to-prd` — Documentation

**What it does:**
Takes the current conversation (typically the output of `/grill-me`) and synthesizes it into a structured PRD. It does **not** re-interview you. Before writing, it explores the codebase to ground the PRD in real module names, existing patterns, and domain vocabulary. It sketches the modules to build/modify, checks with you, then writes and publishes the PRD to Jira with a `ready-for-agent` label.

**Why it's valuable:**
Consistency. Every PRD produced by this skill has the same sections — nothing is ever forgotten. The module-sketch step also surfaces "we need to build X from scratch" surprises before the PRD is finalized.

**PRD sections produced:**
- Problem Statement
- Solution
- User Stories *(exhaustive, numbered list)*
- Implementation Decisions *(decisions only — no file paths)*
- Testing Decisions *(what to test and where prior art lives)*
- Out of Scope
- Further Notes

| | |
|---|---|
| **Input** | Active conversation context (post-`/grill-me`, or your own notes) |
| **Output** | Published Jira ticket with PRD content and `ready-for-agent` label |
| **Invoke** | `/to-prd` |

---

### 3. `/to-issues` — Execution Planning

**What it does:**
Takes the PRD (or any spec, plan, or existing issue) and breaks it into independently-grabbable child tickets using **vertical slices** (tracer bullets). Each slice cuts end-to-end through all integration layers — schema, API, UI, and tests together — so every ticket is demoable or verifiable on its own. It quizzes you on the proposed breakdown (granularity, dependencies, HITL vs AFK classification) before publishing anything.

**Why it's valuable:**
PRDs describe what to build; `/to-issues` decides how to sequence the work. A vertical slice is always preferable to a horizontal one (e.g., "add DB column + API endpoint + UI field + test" in one ticket beats three separate layer-tickets). This means each issue can be picked up, built, and merged independently — no "backend done, waiting for frontend" blockers.

**HITL vs AFK:**
- **AFK** (Away From Keyboard) — the slice can be implemented and merged by an agent without human interaction. Preferred.
- **HITL** (Human In The Loop) — requires a decision, design review, or approval step before it can be closed.

**Issue template produced:**
- Parent reference
- What to build *(end-to-end behavior, no file paths)*
- Acceptance criteria *(checkbox list)*
- Blocked by *(dependency on other slices)*

| | |
|---|---|
| **Input** | Active conversation context, or a PRD issue number/URL passed as argument |
| **Output** | Child tickets published to Jira in dependency order, each with `ready-for-agent` label |
| **Invoke** | `/to-issues` or `/to-issues RDNEW-1234` |

---

### 4. `/close-the-gaps [TICKET-ID]` — Refinement

**What it does:**
A Product Analyst session. Give it a Jira ticket ID or paste ticket content. It fetches the ticket, loads relevant domain skills, explores the codebase areas the ticket touches, then silently identifies gaps across 10 categories. It interviews you one multiple-choice question at a time (with a recommended answer for each), then writes a refined ticket file with added Gherkin acceptance criteria.

**Why it's valuable:**
Catches "hallucinations of readiness" — the feeling that a ticket is complete when it's full of ambiguity that will block the developer mid-sprint. The Gherkin output gives developers unambiguous, testable criteria.

**Gap types it hunts:**
Unclear language · Missing definitions · Unstated assumptions · Conflicting requirements · Skill conflicts · Code conflicts · Missing edge cases · Missing acceptance criteria · Scope ambiguity · Missing actor/trigger

| | |
|---|---|
| **Input** | Jira ticket ID (e.g., `RDNEW-1234`) or pasted ticket text |
| **Output** | `[TICKET-ID]-refined.md` — original ticket + Gherkin scenarios + TBD list |
| **Invoke** | `/close-the-gaps RDNEW-1234` |

---

### 5. `/improve-codebase-architecture` — Architecture Quality Gate

**What it does:**
Explores the codebase for shallow modules — code where the interface is nearly as complex as the implementation, providing no leverage. Surfaces a numbered list of deepening opportunities, then drops into a grilling conversation for whichever candidate you pick.

**Why it's valuable:**
Use before writing implementation decisions in your PRD, or before a large feature build. It prevents the codebase from accumulating structural debt as features are added quickly.

**Key concepts:**
- **Deep module** — high leverage: lots of behavior behind a small interface
- **Shallow module** — interface nearly as complex as the implementation
- **Deletion test** — would deleting this module concentrate complexity, or just spread it across callers?

| | |
|---|---|
| **Input** | Active conversation + codebase (spawns an Explore agent internally) |
| **Output** | Numbered list of deepening candidates → grilling conversation → optional ADR |
| **Invoke** | `/improve-codebase-architecture` |

---

### 6. `/zoom-out` — Navigation Aid

**What it does:**
A one-shot context expander. Tells Claude: go up a layer of abstraction, map all relevant modules and callers, use the project's domain vocabulary. Fires once and returns a module map — it does not start an extended conversation.

**Why it's valuable:**
Use this as a support tool at any point when you or Claude are lost. Especially useful before `/close-the-gaps` (understand what the ticket touches) or before `/improve-codebase-architecture` (understand the existing shape before improving it).

| | |
|---|---|
| **Input** | Current conversation context (assumes you've mentioned the area you're in) |
| **Output** | Map of relevant modules, callers, and relationships in domain vocabulary |
| **Invoke** | `/zoom-out` |

---

### 7. `/diagnose` — Bug & Regression Investigation

**What it does:**
A disciplined six-phase debugging loop: **Build a feedback loop → Reproduce → Hypothesise → Instrument → Fix → Cleanup**. The core insight is that the entire skill lives in Phase 1 — if you have a fast, deterministic, agent-runnable pass/fail signal for the bug, you will find the cause. Everything else is mechanical.

**Phases in brief:**
1. **Feedback loop** — build the fastest possible reproducible signal (failing test, curl script, CLI fixture, replay trace, throwaway harness, property loop, bisection harness, or HITL script)
2. **Reproduce** — confirm the loop produces exactly the failure the user described
3. **Hypothesise** — generate 3–5 ranked, falsifiable hypotheses before testing any of them; show the ranked list to the user
4. **Instrument** — one variable at a time; prefer debugger over logs; tag all debug logs with a unique prefix for easy cleanup
5. **Fix + regression test** — write the test before the fix at the correct seam; watch it fail, apply the fix, watch it pass
6. **Cleanup** — remove all instrumentation, confirm original repro no longer reproduces, state the winning hypothesis in the commit message

**Why it's valuable:**
Prevents the common failure mode of staring at code without a reproducible signal. The hypothesis ranking step surfaces domain knowledge early. The feedback-loop-first discipline works for both deterministic and flaky bugs (raise the flake rate until it's debuggable).

| | |
|---|---|
| **Input** | Bug report, error description, or performance regression |
| **Output** | Root cause identified, fix applied, regression test in place |
| **Invoke** | `/diagnose` |

---

### 8. `/handoff` — Session Handoff

**What it does:**
Compacts the current conversation into a handoff document for a fresh agent to pick up. Saves to the OS temp directory (not the workspace). Avoids duplicating content already captured in PRDs, plans, ADRs, or commits — references those by path/URL instead. Includes a "suggested skills" section so the next agent knows where to start. Redacts sensitive information. Accepts an optional argument describing what the next session will focus on.

**Why it's valuable:**
Context windows are finite. When a conversation grows long mid-feature, `/handoff` preserves exactly what the next agent needs without polluting the workspace with planning artifacts.

| | |
|---|---|
| **Input** | Current conversation context; optional argument describing the next session's focus |
| **Output** | Handoff document saved to OS temp dir |
| **Invoke** | `/handoff` or `/handoff "focus of next session"` |

---

### 9. `/write-a-skill` — Skill Authoring

**What it does:**
Guides you through creating a new Claude Code skill with the correct structure and progressive disclosure. Gathers requirements (domain, use cases, need for scripts/reference files), drafts the skill, reviews it with you, then writes the final files.

**Skill structure it produces:**
```
skill-name/
├── SKILL.md           # Main instructions (required, target < 100 lines)
├── REFERENCE.md       # Detailed docs split out when SKILL.md grows too large
├── EXAMPLES.md        # Usage examples (optional)
└── scripts/           # Utility scripts for deterministic operations (optional)
```

**Key rules it enforces:**
- The `description:` field in frontmatter is the only thing the agent sees when choosing a skill — it must include "Use when [specific triggers]"
- Split into separate files when `SKILL.md` exceeds 100 lines or content has distinct domains
- Add scripts only for deterministic operations that would otherwise be regenerated repeatedly

| | |
|---|---|
| **Input** | Description of the task/domain the new skill should cover |
| **Output** | New skill directory with `SKILL.md` (and supporting files if needed) |
| **Invoke** | `/write-a-skill` |

---

## Key Differences

### `/grill-me` vs `/grill-with-docs`

Both interview you one question at a time and explore the codebase when needed:

| | `/grill-me` | `/grill-with-docs` |
|---|---|---|
| Interview loop | ✅ | ✅ |
| Explores codebase | ✅ | ✅ |
| Challenges against existing glossary | ❌ | ✅ |
| Updates `CONTEXT.md` inline | ❌ | ✅ |
| Creates ADRs for hard decisions | ❌ | ✅ |
| Output | Shared understanding in context | Shared understanding + updated docs |

Use `/grill-me` for a quick design stress-test with no doc side-effects. Use `/grill-with-docs` when the session should also maintain and sharpen the project's domain language.

---

### `/grill-me` vs `/close-the-gaps`

Both ask you questions one at a time, but they work in opposite directions:

| | `/grill-me` | `/close-the-gaps` |
|---|---|---|
| Starting point | Raw idea, no ticket | Existing ticket |
| Questions about | Design decisions, trade-offs, "why" | Requirement gaps, ambiguity, edge cases |
| Output | Shared understanding in context | Gherkin-format refined ticket file |
| Use when | Before the PRD exists | After the PRD/ticket exists |

### `/to-prd` vs `/to-issues` vs `/close-the-gaps`

These three are the core creation chain — each operates at a different level of granularity:

| | `/to-prd` | `/to-issues` | `/close-the-gaps` |
|---|---|---|---|
| Level | Feature (parent) | Slice (child) | Individual ticket |
| Creates or refines? | Creates PRD from scratch | Breaks PRD into child tickets | Refines one existing ticket |
| Asks questions? | No — synthesizes from context | Yes — breakdown review | Yes — gap-by-gap Q&A |
| Output | Published parent Jira issue | Multiple child Jira issues | `[ID]-refined.md` with Gherkin ACs |
| Explores codebase? | Yes — to ground the PRD | Optional — for domain vocab | Yes — to find code conflicts |
| Use when | You have a validated idea | You have a PRD and need to plan work | You have a ticket and need to harden it |

### `/improve-codebase-architecture` vs all others

The only skill focused on the **codebase structure**, not the **requirement**. The first four skills define what to build and how to sequence it. This skill makes the place where you'll build it structurally sound before you start.

---

## Tips

**Don't skip `/grill-me`.**
Going straight to `/to-prd` produces generic PRDs. The grilling session gives Claude the specificity needed to write user stories and implementation decisions that actually match your system.

**Let `/grill-me` read the codebase.**
If Claude asks a question and you don't know the answer, say *"check the codebase for the current behavior."* The skill explicitly supports this.

**Use `/to-issues` to find hidden dependencies.**
When the quiz step asks "are the dependency relationships correct?", take it seriously. Cycles (A blocks B blocks A) usually mean a slice is too fat and needs splitting. The dependency order is also the publishing order — blockers go first so child tickets reference real issue IDs.

**`/close-the-gaps` is a quality gate, not a rubber stamp.**
Run it on each child ticket produced by `/to-issues`, not just the parent PRD. Each slice has its own edge cases that the parent PRD never covered at that level of detail.

**Run `/improve-codebase-architecture` before sprint planning, not after.**
Architectural improvements found during a sprint cause mid-sprint scope churn. Treat it as part of refinement.

**Use `/zoom-out` anytime you're disoriented.**
It costs nothing and reorients both you and Claude in under a minute.

---

## Connection to the Developer Workflow

The full chain from raw idea to developer plan looks like this:

```
/grill-me  →  shared understanding in context
                    │
                    ▼
/to-prd    →  parent Jira ticket (PRD)
                    │
                    ▼
/to-issues →  child Jira tickets (vertical slices, in dependency order)
                    │
              ┌─────┴──────┐
              │  per child │  (run /close-the-gaps on each one)
              ▼            ▼
/close-the-gaps  →  [CHILD-ID]-refined.md
                         │
                         │  (Gherkin ACs become Acceptance Criteria)
                         ▼
             uni:fetch-ticket  ←  reads the child ticket from Jira,
                                   including refinements
                         │
                         ▼
             uni:plan  ←  writes .plans/RDNEW-XXXX.md with:
                           • Spec (Problem Statement + Requirements)
                           • Acceptance Criteria (from Gherkin, or derived)
                           • Constraints (C++11, platform, protocol)
                           • Device / Black-Box test scenarios
                           • Atomic Steps with TDD stubs
                         │
              BLOCKING GATE — user approves plan
                         │
                         ▼
             uni:create-branch  →  BUILD phase (one step at a time)
```

**Why this chain matters:**

Each step amplifies the next. The Gherkin acceptance criteria from `/close-the-gaps` flow directly into the `## Spec / Acceptance Criteria` section of the `uni:plan` file, which then drives two concrete outputs:

1. **Device / Black-Box tests** in `## Tests` — one observable scenario per acceptance criterion
2. **TDD stubs** inside each `## Steps` entry — unit-level verification that the criterion is satisfied

Skipping `/grill-me` produces a vague PRD. Skipping `/to-issues` means the developer gets a monolithic ticket and has to decompose it themselves. Skipping `/close-the-gaps` means `uni:plan` falls back to "derived" acceptance criteria instead of explicit Gherkin — which produces weaker stubs and slower, more ambiguous BUILD phases.

The stronger the upstream work, the less interpretation the developer (or agent) has to do downstream.
