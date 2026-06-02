---
name: feedback_skip_skill_for_trivial_edits
description: "Don't invoke update-config (or any skill) when the edit is already fully understood — use Read + Edit directly"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9a0f0e12-3cbe-42bc-bbb7-ca39d7fe51e7
---

Don't invoke `update-config` (or any other skill) when the task is a mechanical file edit with no ambiguity. Use Read + Edit directly instead.

**Why:** The `update-config` skill dumps its full instruction document and the entire settings JSON schema into the conversation, burning ~10–20k tokens for a task that takes two tool calls. User noticed this inflated the context window significantly for a trivial 2-line change.

**How to apply:** Reserve `update-config` for cases where there is genuine ambiguity — which file to target, whether to use hooks vs permissions, complex merging logic, or unfamiliar settings. If the target file, the change, and the merge are all clear before the first tool call, skip the skill and go straight to Read + Edit.
