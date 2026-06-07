# Workflow

## Session Resume

When ticket mentioned or user says "continue" / "status" / "where were we":
- Ticket mentioned → check if `.plans/<ticket>.md` exists → found: read the **full** `.plans/<ticket>.md` — frontmatter (`phase`, `step`, `next`) + all step content + `✓`/`← current` markers + `## Deviation Register` + `## Handoff` section if present. Resume at the step marked `← current` (or `step N` from frontmatter if no `← current` marker is present). → not found: user can choose to start the workflow or skip it
- No ticket mentioned → scan `.plans/` directory for existing plan files → found: list them and ask which to resume → none found: skip workflow entirely, just answer

When resuming a BUILD-phase plan, check `## Deviation Register` — if it has **unresolved** entries (not marked ✓), output a one-line digest before the first step (non-blocking, no re-approval needed):
> "Carrying forward N approved deviation(s): [list unresolved entries]"

## General Rules

**Blocking questions** — when any step ends with a question to the user, stop completely. Do not run tools, suggest next steps, or generate content until the user replies.

---

## Phase Map

| Phase | Skills | Gate |
|---|---|---|
| PLAN | `uni:fetch-ticket` → file scope → type guide (`plans/*.md`) → `uni:plan` | BLOCKING — wait for "proceed" |
| BUILD | plan steps + After Implementation | BLOCKING — per-step checkpoint |
| SHIP | `uni:commit` (includes review-pr, Jira comment, resolve, cleanup) | — |

**Exception — `investigation` type**: no `uni:create-branch`, no SHIP phase. Plan only; findings go in the plan file itself.

---

## Plan File Format

Every ticket gets `.plans/<ticket>.md`. Format is defined in `uni:plan` — see `.claude/commands/uni/plan.md`.

Handoff: run `uni:handoff` to write the `## Handoff` section, then stop.
Resume: read `phase`, `step`, `next` from frontmatter and paste the Handoff block into a new conversation.

---

## PLAN Phase

Sequence:
1. Run `uni:fetch-ticket` — it handles type detection, reads and displays the type guide, and asks the user to choose (follow guide / write directly / skip)
2. **File scope** — ask the user (non-blocking, one question):
   > "Do you know which files or folders are relevant? If so, list them — otherwise I'll explore."
   - **User provides paths** → read those files, then assess whether they are sufficient to fully understand the change (all touch-points covered, no missing callers/dependents). If sufficient: use them as the file scope. If gaps remain: spawn a `file-explorer` agent (search breadth: medium) to find the missing pieces, then merge with the user's list.
   - **User says "explore" / doesn't know** → spawn a `file-explorer` agent (search breadth: medium): *"Find files relevant to [ticket summary + key terms from description]. Return a compact list of file paths (max 150 words)."* Use its output as the file scope.
   - Either way, carry the resolved file list into `uni:plan` as context.
3. If following the guide: execute SC commands per the guide, then invoke `uni:plan`; if writing directly: invoke `uni:plan` immediately
4. **Context check** — after SC commands complete (or after step 2 if writing directly), if the conversation appears ~60% full, pause and offer once (non-blocking): *"Context is getting full — want me to run `uni:handoff` to save these findings before writing the plan?"* If yes: run `uni:handoff` then stop. If no: continue.
5. `uni:plan` writes the enriched file and holds the BLOCKING gate — wait for "proceed" / "yes" / "go" / "ok" / "1"

`uni:plan` can also be invoked standalone (no prior `uni:fetch-ticket` or type guide needed) — it accepts ticket ID, pasted text, or a free-form prompt as its context source.

## BUILD Phase

The branch was created by `uni:plan` at the end of the PLAN phase. Follow plan steps in order, one at a time.

**Before starting each step**: read `## Deviation Register` and apply any unresolved entries (not marked ✓) targeting this step — the entry's `→ Step M:` clause says exactly what to do differently. If the step has a `**Pre-step**` field that is not yet marked ✓, execute it now before touching any implementation file.

After EVERY completed step — before doing anything else:
1. Walk through each verification stub in the completed step and confirm the implementation satisfies it — fix code if any stub fails. For `(integration)` stubs: ask the user to run the app and verify behavior.
2. Compare what was actually implemented against the plan step's **What** and **Touches** fields — identify any deviations
3. **If any deviation occurred** — BLOCKING: state what deviated and why, ask for user approval, wait for it before continuing
4. Write approved deviations into the **Deviations** field of the completed step ("None" if none); if a deviation affects an upcoming step, also add it to `## Deviation Register` in the plan file (format: `[Step N → affects Step M] <what changed and why> → Step M: <what to do differently>`)
5. Mark Step N as `✓` in the plan body. Also mark any `## Deviation Register` entries whose target is Step N as resolved: append ` ✓` to the entry (e.g., `[Step K → affects Step N ✓]`)
6. Mark Step N+1 as `← current` in the plan body
7. Update `phase=BUILD`, `step=N+1`, `next=<Step N+1 title>`, `updated=<current YYYY-MM-DD HH:MM>` in `.plans/<ticket>.md` frontmatter
8. Output the Step Checkpoint — BLOCKING
9. Do not proceed until the user gives an approval signal

**Step Checkpoint format:**
> Step N done: \<step title\>
> Plan updated: phase=BUILD, step=N+1, next=\<Step N+1 title\>
> Tests: \<per stub — "(integration) GREEN" — or "TODO: test framework not yet in place"; if a stub was RED and fixed before this checkpoint, note: "(integration) RED → fixed → GREEN"\>
> Deviations: \<list each deviation and why — or "None"\>
> Register: \<entry added: "[Step N → affects Step M] ..." — or "None"\>
> Proceed to Step N+1? (ok / pause)

**Tests line rules**: All stubs must be GREEN before the checkpoint is output. Claude first reviews the implementation against each stub description and confirms the logic is correct — fix code if not. Then:
- `(integration)` — ask user to run the app and observe behavior / logs — wait for their GREEN or RED. If RED: fix code, re-ask.
<!-- TODO: add test stub types once a test framework is adopted -->
A fix that was not in **What** or **Touches** is a deviation — follow the deviation gate.

A deviation is any of: touching a file not listed in **Touches**, skipping part of **What**, doing something not described in **What**, or changing approach mid-step. Always state the reason (discovered dependency, bug found, plan was wrong, etc.).

Approval signals: `ok` / `next` / `go` / `1`
Pause signal: `pause` → run `uni:handoff` then halt

After all steps complete, check `## After Implementation` in the plan — if it contains items, offer each in order and wait for the user's decision before proceeding to the next. If the section is empty (`None.`), skip it. Then stop — the user initiates the commit when ready.

## SHIP Phase

Run `uni:commit` when the user asks to commit. Each step is an **offer** — nothing is forced: review-pr → commit → QA list → Jira comment → resolve → cleanup.

---

## SuperClaude

Follow `plans/*.md` instructions exactly, including user override paths. Invoke `/sc:` commands via Skill tool only.
