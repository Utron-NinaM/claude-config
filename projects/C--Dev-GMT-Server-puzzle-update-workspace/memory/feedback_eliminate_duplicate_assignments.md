---
name: feedback-eliminate-duplicate-assignments
description: Prefer null-coalescing + shared field assignment over if/else branches that duplicate the same field assignments
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0451e7fa-1b89-48e8-aace-94d808c7fbec
---

Use null-coalescing to initialize a default, set shared fields once, then branch only on the differing action. Never duplicate field assignments across if/else branches.

**Why:** First implementation of UpdateDistributerAndSites had the same three field assignments duplicated in both the "update existing" and "create new" branches. User asked to simplify — the fix was to extract shared assignments outside the branch.

**How to apply:** Any time an if/else (or ternary) sets the same fields in both branches, refactor to: initialize with `??`, assign shared fields once, then dispatch on the action difference (`Id == 0 ? Add : MergeAndSave` in C#; spread + ternary in JS/React). Applies to all languages and projects.
