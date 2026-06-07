# /uni:plan — Write Enriched Plan

Writes the enriched `.plans/<ticket>.md` file. Called after SC analysis is complete (per the type guide), or standalone when the user invokes it directly.

---

## Triggers
- End of a type guide flow (bug.md, feature.md, etc.) — type guide calls this
- User invokes `/uni:plan` directly with a ticket ID, pasted requirements, or free-form prompt
- Called from workflow after `uni:fetch-ticket` when the user wants to skip SC analysis

---

## Instructions

### 1. Gather context

Priority order:
1. SC analysis output already in session + Jira data from `uni:fetch-ticket` → proceed
2. Ticket ID provided but not yet fetched → invoke `uni:fetch-ticket` now
3. Pasted text or free-form prompt → use as Problem Statement; set `ticket:` frontmatter to `adhoc-<slug>`

Determine plan type from context (needed for section gating below).

### 2. Ask for spec additions — BLOCKING

Ask once:
> "Anything to add to the spec — extra requirements, constraints, or context Jira doesn't capture?"

Wait for the user's response (or "no" / "nothing") before continuing.

### 3. Build the `## Spec` section

- **Problem Statement**: Jira description or user prompt
- **Requirements**: functional requirements extracted or inferred, numbered FR1, FR2…
- **Acceptance Criteria**: copy from Jira context if present; otherwise derive from requirements and mark each `[derived]`

### 4. Build the `## Constraints` section

List any non-obvious constraints that affect implementation choices:
- React: browser compatibility requirements, Redux state shape constraints, MUI version limits
- Any non-obvious technical constraint affecting implementation choices

If none apply, write: `None identified.`

### 5. Build the `## Tests` section

Skip entirely for `investigation` and `script` types.

**Device / Black-Box only** — one observable scenario per item.  
Unit/Integration stubs live inside each Step (see Step format below).

### 6. Build the `## Steps` section

Each step must be:
- **Atomic** — one logical change per step
- **Reversible** — can be undone without affecting other steps
- **Independently testable** — has its own verification stubs

Use the Step format defined in the template in step 8. Never merge steps. Never omit a required field.

Field guidance:
- **Why** — omit unless the approach is non-obvious or a specific design decision was made over alternatives. Do not add for routine steps.
- **verification stubs** — each stub must end with a type tag:
  - `(integration)` — verify by running the app and observing behavior / API responses / logs; manual verification
  <!-- TODO: add test stub types once a test framework is adopted -->
- **Risk** — one line describing what could go wrong, or "None".
- **Mitigation** — omit entirely if Risk is "None". Otherwise describe what to do if the risk fires.

### 7. Build the `## After Implementation` section

Skip entirely for `investigation` and `script` types.

Only add items that are genuinely needed for this specific plan — things that must be verified or run after all steps are done but before committing. Leave the section empty (`None.`) if nothing applies.

Examples of valid items: run `uni:static-analyze` if compiled files changed and there is a real risk of regression; device smoke-test if the change affects hardware-facing behavior; verify a config file deploys correctly; confirm a migration ran cleanly.

Do **not** add items as boilerplate. If in doubt, leave it empty.

### 8. Write the plan file

File: `.plans/<ticket>.md` (or `.plans/adhoc-<slug>.md`). Set `updated` to the current date and time when writing.

The **first line of the file body** (after frontmatter) MUST be exactly:
```
# Plan: <ticket> — <title>
```

Use this exact template:

```markdown
---
ticket: RDNEW-XXXX
title: <title>
type: <bug|feature|refactor|investigation|script>
component: <component>
phase: <PLAN|BUILD|SHIP>
step: <number>
next: <skill or action>
updated: <YYYY-MM-DD HH:MM>
---

# Plan: RDNEW-XXXX — <title>

## Spec
### Problem Statement
<from Jira or user input>

### Requirements
- FR1: ...
- FR2: ...

### Acceptance Criteria
- AC1: Given / When / Then
<!-- Mark [derived] if inferred from requirements, not from Jira -->

## Constraints
- <C++11 / platform / protocol constraint>
<!-- or: None identified. -->

## Tests  <!-- OMIT entire section if type is investigation or script -->
### Device / Black-Box
- [ ] <observable action> → <expected visible result>  <!-- AC1 -->

## Steps
> BUILD: one step per turn. **Before starting each step**: read `## Deviation Register` and apply any unresolved entries (not marked ✓) targeting this step — the entry's `→ Step M:` clause says exactly what to do differently. **At checkpoint**: (1) if any deviation occurred — state what deviated and why, ask for user approval, and wait for it before continuing; (2) verify all stubs — first review implementation against each stub description and fix any logic errors; then for `(integration)` stubs, ask user to run the app and verify behavior — all stubs must be GREEN before outputting the checkpoint; (3) write approved deviations into **Deviations** field — if the deviation affects an upcoming step, also add it to `## Deviation Register` (entry format: `[Step N → affects Step M] <what changed and why> → Step M: <what to do differently>`); (4) mark any register entries targeting this step as ✓; (5) wait for ok/next before proceeding.
### Step 1: <imperative name>
**Why**: <omit unless approach is non-obvious or a design choice was made over alternatives>
**What**: <atomic action>
**Touches**: `path/to/file`
**verification stubs** *(verify each before marking step ✓)*:
- [ ] <plain-English test>  (integration)
**Risk**: <one line or "None">
**Mitigation**: <what to do if risk fires — omit if Risk is "None">
**Deviations**: <filled in at checkpoint — "None" or description + reason. If the deviation affects an upcoming step, also add it to `## Deviation Register`>

### Step N: <imperative name>
*(repeat Step 1 format for every subsequent step)*

## After Implementation  <!-- OMIT entire section if type is investigation or script -->
None.

## Deviation Register
<!-- Entries added at checkpoints. Format: [Step N → affects Step M] <what changed and why> → Step M: <what to do differently>. Append ✓ to entry when Step M completes. Approved deviations only. -->

## Handoff
<!-- Run `uni:handoff` to fill this section. Paste the block below into a new conversation to resume. -->
```


### 9. Gate — BLOCKING

Read `.claude/rules/workflow.md` if not already loaded (needed for BUILD phase per-step checkpoint rules).

Display the full contents of the written plan file so the user can review it inline.

Then output exactly:
```
Ticket: <ticket> — <title> | Type: <type> | Component: <component>
Plan: [.plans/<ticket>.md](.plans/<ticket>.md)
```

Stop. Do not modify any source file, call `Edit`, `Write`, or run any build command until the user gives an approval signal: `proceed` / `approved` / `yes` / `go` / `ok` / `1`.

### 10. Create branch — MANDATORY (runs immediately after approval)

As soon as the approval signal is received, invoke `uni:create-branch` before doing anything else.
Skip only if type is `investigation` (no commit required for investigations).

After `uni:create-branch` succeeds:
1. Mark Step 1 as `← current` in the plan body.
2. Update frontmatter: `phase=BUILD`, `step=1`, `next=<Step 1 title>`, `updated=<current YYYY-MM-DD HH:MM>`.
3. Load `code-style.md`, and `claude-security-guidance.md`  if not already in context.
