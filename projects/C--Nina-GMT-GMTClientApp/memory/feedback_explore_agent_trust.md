---
name: explore-agent-trust
description: "Don't re-read files the Explore agent already fully reported on; trust the agent's output and avoid unnecessary verification reads"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5de94233-eb06-4bd9-b2fd-71b5d0696c3f
---

After an Explore agent reads and reports on a file, do NOT read that same file again to verify. Trust the agent's output. Re-reading doubles context cost for no benefit.

**Why:** In a WorkspaceWizard bug-fix session, the Explore agent read ~15 files and reported fully. Then the main context re-read most of them anyway to verify, consuming ~83k tokens in Messages alone and triggering autocompact.

**How to apply:**
- After an Explore agent reports on a file, treat that as authoritative — proceed to planning directly
- Only do a targeted re-read if the agent's report is ambiguous or contradicts itself on a specific line
- Also avoid reading files speculatively (e.g. WorkspaceActionsService, WorkspaceInfo) unless the agent flagged them as relevant to the specific bug
- When verifying edits after writing, read only the changed lines/region, not the whole file
