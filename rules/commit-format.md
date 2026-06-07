# Commit Format

Shared format spec for `uni:commit` and `uni:commit-only`. Both skills reference this — never duplicate.

## Before drafting

**Read every hunk of the diff** (already in context from the commit skill) before writing the message. Do not draft from filenames or conversation context alone.

## Subject line

```
<TICKET-ID> - <type>(<scope>): <imperative description>
```

- Target **≤ 50 chars**, hard cap **72 chars**
- Ticket ID always first, em-dash separator
- Imperative mood: **Add** / **Fix** / **Remove** — not "Added", "Fixes"
- **No `Co-Authored-By` lines**
- Omit scope when change is repo-wide or cross-cutting
- Multi-component commits: <!-- TODO: -->

### Types

| Type | When |
|------|------|
| `feat` | new capability or behaviour |
| `fix` | bug fix |
| `refactor` | restructure without behaviour change |
| `chore` | tooling, config, scripts, CI |
| `docs` | documentation only |
| `perf` | performance improvement |
| `test` | tests only |

### Scope

Component or domain name — not a file path.
Examples: `WorkspaceWizard`, `BillingActionsService`, `sc-commands`, `uni:commit`.
Use a filename only when a single config file is the entire change (e.g., `CSMUDS.xml`).

## Atomicity

One logical change per commit. If the staged diff spans unrelated concerns (different ticket, different component, separable revert), stop and ask the user to split before committing.

## Body — four tiers

### Trivial — subject only

1-line change, no behavior shift (typo, rename, dep bump, comment fix).

```
PROJ-1234 - chore(deps): bump boost to 1.81
```

### Standard — subject + plain prose paragraph

Most fixes and small features. 2–4 lines, wrap at 72. Explain why *and* what in natural prose — no section headers.

```
PROJ-1234 - fix(WorkspaceActionsService): clear form state on modal close

Form retained previous values when re-opened after a failed submit,
causing stale data to be re-sent. Reset state on modal close instead.
```

### Complex single-component — `## Why` + `## What`

One component, but behavior change is non-trivial enough to warrant separation.

```
PROJ-1234 - feat(WorkspaceWizard): add puzzle site selection step

## Why
Puzzle-type workspaces had no dedicated step for selecting which
site to assign, forcing users to skip back after completing setup.

## What
Adds WorkspacePuzzleSiteStep between group details and tech steps,
gating on workspace type so non-puzzle flows are unaffected.
```

### Complex multi-component — `## Why` + named component sections

Multiple components, each with its own behavioral change. Replace `## What`
with a section per component — named after the component, behavioral prose
inside. No file lists.

```
PROJ-1234 - feat(workspace): add operator approval with group details

## Why
Removing an operator required a separate confirmation flow, leaving
the UI inconsistent with the add-operator path.

## WorkspaceApproveRemoveOperatorStep
Adds a confirmation step that displays the operator's details and
requires explicit approval before the removal is submitted.

## workspaceWizardTransitions
Updates step navigation to route through the approval step when the
remove-operator action is selected.
```

## Tier triage

| Tier | When |
|------|------|
| Trivial | 1 file, no behavior change |
| Standard | Most fixes and small features — single component |
| Complex single | One component, behavior change warrants Why/What separation |
| Complex multi | Two or more components with distinct behavioral changes |

When ambiguous → **Standard**.

## Optional sections

Add after the last component section (or after `## What` for single-component), before trailers. Include only when there's concrete signal:

- **`## Tested`** — concrete validation evidence (confirmed in the running app, bug reproduction confirmed fixed). Omit when "tested" would be filler.
- **`## Risk`** — non-obvious failure modes
- **`## Breaking`** — what breaks and how to migrate

## Trailers

Last block of the body, after a blank line. Use git-trailer convention — `Key: value`, one per line, no blank lines between trailers.

```
Refs: PROJ-5347
Resolves: PROJ-1234
BREAKING CHANGE: <what breaks and how to migrate>
```

- `Refs:` — related ticket (no auto-close)
- `Resolves:` — closes this ticket
- `BREAKING CHANGE:` — required for any breaking API/protocol change
