# Human-in-the-loop reproduction loop.
# Copy this file, edit the steps below, and run it.
# The agent runs the script; the user follows prompts in their terminal.
#
# Usage:
#   .\hitl-loop.template.ps1
#
# Two helpers:
#   Step "<instruction>"    → show instruction, wait for Enter
#   Capture "<question>"    → show question, return response
#
# At the end, captured values are printed as KEY=VALUE for the agent to parse.

function Step {
    param([string]$Instruction)
    Write-Host "`n>>> $Instruction"
    Read-Host "    [Press Enter when done]" | Out-Null
}

function Capture {
    param([string]$Question)
    Write-Host "`n>>> $Question"
    return Read-Host "    >"
}

# --- edit below ---------------------------------------------------------

Step "Open the app at http://localhost:3000 and sign in."

$ERRORED   = Capture "Click the relevant button. Did it throw an error? (y/n)"
$ERROR_MSG = Capture "Paste the error message (or 'none'):"

# --- edit above ---------------------------------------------------------

Write-Host "`n--- Captured ---"
Write-Host "ERRORED=$ERRORED"
Write-Host "ERROR_MSG=$ERROR_MSG"
