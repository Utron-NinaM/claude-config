---
description: Fetch and summarize a Jira ticket. Activated when the user mentions RDNEW-XXXX at the start of a task.
---

# /uni:fetch-ticket — Jira Ticket Intake

## Steps

### 1. Extract ticket ID
Parse `RDNEW-XXXX` from `$ARGUMENTS` or the current conversation.

### 2. Fetch Jira ticket

Check CLI availability first:
```bash
command -v acli
```
- **CLI available** → Run both commands below in sequence.
  The first renders a readable ticket display in the terminal.
  The second fetches all fields as JSON and extracts Environment, custom bug fields, assignee status, comments, and attachments via PowerShell.
```bash
acli jira workitem view <ID>
```
```powershell
powershell.exe -Command "
\$fields = (acli jira workitem view <ID> --fields '*all' --json | ConvertFrom-Json).fields

function ExtractText(\$val) {
    if (\$null -eq \$val) { return '' }
    if (\$val -is [string]) { return \$val.Trim() }
    if (\$val -is [System.Management.Automation.PSCustomObject]) {
        if (\$val.type -eq 'text') { return \$val.text }
        if (\$val.content) { return (\$val.content | ForEach-Object { ExtractText \$_ }) -join '' }
    }
    if (\$val -is [array]) { return (\$val | ForEach-Object { ExtractText \$_ }) -join '' }
    return ''
}

function IsMeaningful(\$text) {
    return \$text -and \$text.Trim() -notin @('none', 'n/a', '-', '')
}

\$envField = \$fields.environment
if (\$envField) {
    \$text = ExtractText \$envField
    if (IsMeaningful \$text) { Write-Output \"Environment: \$text\" }
}

\$bugFields = @{ 'customfield_10039' = 'Steps to Recreate'; 'customfield_10040' = 'Expected Result'; 'customfield_10043' = 'Actual Result' }
foreach (\$key in \$bugFields.Keys) {
    \$val = \$fields.\$key
    if (\$null -ne \$val) {
        \$text = (ExtractText \$val).Trim()
        if (IsMeaningful \$text) { Write-Output \"\$(\$bugFields[\$key]): \$text\" }
    }
}

\$assignee = \$fields.assignee
if (\$null -eq \$assignee) { Write-Output 'ASSIGNEE_STATUS: unassigned' }
else { Write-Output \"ASSIGNEE_STATUS: assigned:\$(\$assignee.displayName)\" }

\$comments = \$fields.comment.comments
if (\$comments -and \$comments.Count -gt 0) {
    Write-Output \"--- Comments (\$(\$comments.Count)) ---\"
    foreach (\$c in \$comments) {
        \$body = ExtractText \$c.body
        if (\$body.Length -gt 200) { \$body = \$body.Substring(0, 200) }
        Write-Output \"[\$(\$c.created.Substring(0,10))] \$(\$c.author.displayName): \$body\"
    }
}

\$attachments = \$fields.attachment
if (\$attachments -and \$attachments.Count -gt 0) {
    Write-Output \"--- Attachments (\$(\$attachments.Count)) ---\"
    foreach (\$a in \$attachments) { Write-Output \"ATTACH|\$(\$a.id)|\$(\$a.filename)|\$(\$a.mimeType)|\$([math]::Round(\$a.size/1024,1))KB\" }
}
"
```
- **CLI not available** → use `getJiraIssue` MCP tool

Summarize inline — always, regardless of description length:
- **Summary**: ticket title
- **Status**: current status — flag if already IN PROGRESS or DONE
- **Type**: Bug / Story / Task
- **Description**: key requirements (condensed)
- **Script-printed fields** (Environment, Steps to Recreate, Expected Result, Actual Result, and any others the extractor prints): include every field the script outputs, copying its value verbatim — do NOT summarize, condense, or truncate any field value
- **Acceptance Criteria**: if present, list all items in full
- **Sub-tasks / linked issues**: list any blockers

When these bug fields are present, carry them forward into the plan file (`## Context` section) so they inform root-cause analysis and test stubs.

### 2a. Auto-assign if unassigned

Run this step only if the Python extractor printed `ASSIGNEE_STATUS: unassigned`.

Read the `account_id` from the acli config (no user prompt — no credential reading needed):
```powershell
powershell.exe -Command "
\$cfg = Get-Content \"\$env:USERPROFILE\.config\acli\jira_config.yaml\" -Raw
(\$cfg | Select-String 'account_id:\s+(.+)').Matches[0].Groups[1].Value.Trim()
"
```

Then assign the ticket to the current user:
```bash
acli jira workitem update <ID> --assignee <accountId>
```

On success: note `(auto-assigned to you)` in the summary's **Assignee** line.
On failure: include `(auto-assign failed — assign manually if needed)` in the summary and continue.

Strip `ASSIGNEE_STATUS:` lines from the displayed summary regardless of outcome.

### 2b. Download and display attachments

Run this step only if the Python extractor printed any `ATTACH|...` lines.

**Fetch auth credentials** (same pattern as `create-ticket.md` — reads acli config + Windows Credential Manager, no user prompt):

```powershell
powershell.exe -Command "
\$cfg = Get-Content \"\$env:USERPROFILE\.config\acli\jira_config.yaml\" -Raw
\$cloudId   = (\$cfg | Select-String 'cloud_id:\s+(.+)').Matches[0].Groups[1].Value.Trim()
\$accountId = (\$cfg | Select-String 'account_id:\s+(.+)').Matches[0].Groups[1].Value.Trim()
\$email     = (\$cfg | Select-String 'email:\s+(.+)').Matches[0].Groups[1].Value.Trim()
\$target    = \"acli:jira:\${cloudId}:\${accountId}\"
\$code = @'
using System; using System.Runtime.InteropServices;
public class CredMan2 {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CREDENTIAL {
        public uint Flags; public uint Type; public string TargetName;
        public string Comment; public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize; public IntPtr CredentialBlob;
        public uint Persist; public uint AttributeCount; public IntPtr Attributes;
        public string TargetAlias; public string UserName;
    }
    [DllImport(\"advapi32.dll\", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool CredRead(string target, uint type, int flags, out IntPtr credential);
    [DllImport(\"advapi32.dll\")] public static extern void CredFree(IntPtr buffer);
    public static string GetPassword(string target) {
        IntPtr ptr = IntPtr.Zero;
        if (!CredRead(target, 1, 0, out ptr)) return null;
        try {
            var cred = Marshal.PtrToStructure<CREDENTIAL>(ptr);
            byte[] bytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, bytes, 0, (int)cred.CredentialBlobSize);
            return System.Text.Encoding.UTF8.GetString(bytes);
        } finally { CredFree(ptr); }
    }
}
'@
Add-Type -TypeDefinition \$code
\$token = [CredMan2]::GetPassword(\$target)
Write-Output \"\$email \$token\"
\$json = \"{\`\"email\`\":\`\"\$email\`\",\`\"token\`\":\`\"\$token\`\",\`\"accountId\`\":\`\"\$accountId\`\",\`\"cloudId\`\":\`\"\$cloudId\`\"}\"
[System.IO.File]::WriteAllText(\"\$env:TEMP\claude_jira_session.json\", \$json, [System.Text.UTF8Encoding]::new(\$false))
"
```

Parse output as `JIRA_EMAIL` (first word) and `JIRA_TOKEN` (second word). The block also writes `%TEMP%\claude_jira_session.json` for reuse by subsequent Jira skill calls.

**For each `ATTACH|...` line**, parse the five pipe-delimited fields: `id | filename | mimeType | size`.

Always build the download URL from the attachment ID using the public Jira domain — never use the `content` URL from the JSON directly (it may point to an internal Atlassian CDN that the corporate proxy cannot reach):
```
https://utron-parking.atlassian.net/rest/api/3/attachment/content/<id>
```

- **Image or PDF** (`mimeType` starts with `image/` or equals `application/pdf`):
  1. Download to `%TEMP%\<filename>` using PowerShell — do NOT use curl (fails against corporate proxies). The `-ProxyUseDefaultCredentials` flag passes Windows NTLM credentials to the proxy while the `Authorization` header handles Jira Basic auth:
     ```powershell
     powershell.exe -Command "
     \$email   = '<JIRA_EMAIL>'
     \$token   = '<JIRA_TOKEN>'
     \$url     = 'https://utron-parking.atlassian.net/rest/api/3/attachment/content/<id>'
     \$outPath = \"\$env:TEMP\<filename>\"
     \$b64     = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(\"\${email}:\${token}\"))
     \$proxy   = [System.Net.WebRequest]::GetSystemWebProxy()
     \$proxyUri = \$proxy.GetProxy(\$url)
     Invoke-WebRequest -Uri \$url \`
         -Headers @{ Authorization = \"Basic \$b64\" } \`
         -Proxy \$proxyUri \`
         -ProxyUseDefaultCredentials \`
         -OutFile \$outPath
     Write-Output \$outPath
     "
     ```
  2. **Immediately after download succeeds**, do both of the following — do not skip either:
     - Call the Read tool on `$outPath` so Claude can describe the image content.
     - Open the file in the default Windows viewer so the user can see it:
       ```bash
       start "" "<outPath>"
       ```
  3. Caption it: `📎 <filename> (<size>) — opened in default viewer`

- **All other types**: list as a single line — `📎 <filename> (<mimeType>, <size>)` — no download needed.

On failure (PowerShell throws or `Invoke-WebRequest` returns 401/403): report `Attachment download failed — check that the Jira token is valid.` and skip remaining downloads.

### 3. Confirm understanding
Ask: *"Does this match what you want to work on? Any clarifications needed?"*
Wait for confirmation before continuing.

### 4. Suggest type and show plan guide

Based on the ticket content, suggest the type:

| Type | Trigger |
|---|---|
| `bug` | crash, wrong value, regression |
| `feature` | new capability, endpoint, UI, service |
| `refactor` | restructure without behavior change |
| `investigation` | no symptom yet — profiling, pre-feature research |
| `script` | shell/Python/SQL/JSON — no compiled output |

Read `.claude/rules/plans/<type>.md` and display it to the user:

```
Suggested type: <type>

Your guide for this ticket (.claude/rules/plans/<type>.md):
─────────────────────────────────────
<contents of the file>
─────────────────────────────────────
```

Then ask — BLOCKING, wait for answer:
> "Want me to follow the guide, write the plan directly, or skip the workflow?"

- **Follow guide** → execute the instructions from the guide shown above, then write `.plans/<ticket>.md`
- **Write directly** → write `.plans/<ticket>.md` from the ticket information alone
- **Skip** → stop here. Answer questions normally, no plan file, no workflow.
