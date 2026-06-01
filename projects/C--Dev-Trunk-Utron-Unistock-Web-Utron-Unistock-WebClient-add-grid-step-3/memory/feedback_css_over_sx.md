---
name: CSS module over sx for modal styling
description: Prefer CSS modules over MUI sx props for modal (and general component) styling
type: feedback
originSessionId: 5d32742b-ac7f-457b-a8f2-5ecd0231365b
---
Use CSS module files for all static design styles instead of `const sx = { ... }` blocks or inline `sx={{ ... }}` props.

**Why:** User explicitly corrected the refactor-modal-to-dialog approach that used a large `const sx` block. CSS modules keep styles out of JS, are easier to scan, and match the project's existing patterns.

**How to apply:**
- Write styles in `.module.css` and apply via `className`
- Use CSS variables for colors: `var(--utronMainColor)`, `var(--white)`, etc. (defined in `src/index.css`) — never import `Colors` just for CSS-level styling
- Only use inline `style` attribute for truly dynamic runtime values (e.g. `direction: isRtl ? 'rtl' : 'ltr'`)
- Use `!important` in CSS module classes when overriding MUI default styles
- Use `:global(.MuiClassName)` in CSS modules for MUI component overrides
- This applies to modals and any component styling work, not just the modal refactor skill
