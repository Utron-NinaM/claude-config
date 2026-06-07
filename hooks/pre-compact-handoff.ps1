# Auto-trigger uni:handoff when context is about to compact during an active BUILD.
# Silent no-op if no BUILD plan exists.

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { '.' }
Set-Location $projectDir -ErrorAction SilentlyContinue

$plan = Get-ChildItem '.plans/*.md' -ErrorAction SilentlyContinue |
    Where-Object { (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match '(?m)^phase:\s*BUILD' } |
    Select-Object -First 1

if (-not $plan) { exit 0 }

$ticket = [System.IO.Path]::GetFileNameWithoutExtension($plan.Name)

Write-Output "[AUTO-HANDOFF TRIGGER] Context is compacting with an active BUILD plan."
Write-Output "Active plan: $($plan.FullName) (ticket $ticket)"
Write-Output ""
Write-Output "MANDATORY: Your first action after this compaction MUST be invoking the uni:handoff skill to persist the current step state to the plan file. Do not run any other tool or generate any other content before uni:handoff completes. This is non-negotiable -- without handoff, mid-step progress is lost."
