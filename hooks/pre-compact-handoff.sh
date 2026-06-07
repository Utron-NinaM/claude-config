#!/usr/bin/env bash
# Auto-trigger uni:handoff when context is about to compact during an active BUILD.
# Silent no-op if no BUILD plan exists.

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

PLAN=$(grep -l '^phase: BUILD' .plans/*.md 2>/dev/null | head -1)
[ -z "$PLAN" ] && exit 0

TICKET=$(basename "$PLAN" .md)

cat <<EOF
[AUTO-HANDOFF TRIGGER] Context is compacting with an active BUILD plan.
Active plan: $PLAN (ticket $TICKET)

MANDATORY: Your first action after this compaction MUST be invoking the uni:handoff skill to persist the current step state to the plan file. Do not run any other tool or generate any other content before uni:handoff completes. This is non-negotiable — without handoff, mid-step progress is lost.
EOF
