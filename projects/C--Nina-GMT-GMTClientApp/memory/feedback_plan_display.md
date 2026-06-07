---
name: feedback-plan-display
description: "After writing a plan file, display its full contents and output the path as a clickable markdown link before the approval gate"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f74ccf61-ff68-4e0c-a5f7-7a97dfb08215
---

After `uni:plan` writes the `.plans/<ticket>.md` file, display the full plan contents inline so the user can review it before approving. Output the file reference as a markdown link (e.g. `[.plans/RDNEW-XXXX.md](.plans/RDNEW-XXXX.md)`), not a plain path.

**Why:** Users couldn't see the plan they were being asked to approve — the skill only output a plain file path with no content and no clickable link.

**How to apply:** Always in `uni:plan` step 9, before the approval gate.
