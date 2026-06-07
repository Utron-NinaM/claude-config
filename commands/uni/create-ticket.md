---
description: Create a Jira ticket in the RDNEW project using acli.
---

# /uni:create-ticket — Create Jira Ticket

## Project configuration (utron-parking.atlassian.net)

| Field | Value |
|---|---|
| Project key | `RDNEW` |
| Default type | `Task` |
| Default assignee | unassigned |
| Default status | To Do (automatic on creation) |
### Available labels (RDNEW)

| Label |
|---|
| 2022_Q3 |
| 2022_Q4 |
| 2023_Q1 |
| 2023_Q2 |
| 2023_Q3 |
| 2023_Q4 |
| 2024_Q1 |
| 2024_Q2 |
| 2024_Q3 |
| 2024_Q4 |
| 2025_Q1 |
| 2025_Q2 |
| 2025_Q3 |
| Fridenson |
| Pelephone |
| PuzzleSmart |
| Q2_2025 |
| run-automation |
| Scope-QA |
| Slide |

### Available components (RDNEW)

| Component |
|---|
| AMPS |
| APMS Slide |
| Bay Lift 4.1 |
| bay room |
| ev rail |
| External Warehouse |
| FullStack General |
| GMT |
| interfaces |
| Kiosk |
| Kiosk Puzzle |
| MAP |
| MFC |
| Mobile App |
| Puzzle |
| reports |
| Side lift4.0 |
| Simulator WH |
| Slide |
| TLF |
| TT+Cent |
| Warehouse Crane |
| WH General |
| WH- Management Screens |
| WH Miniload Conveyors |
| WH Miniload Crane |
| WH Pallet buffer |
| WH Pallet Conveyors |
| WH Pallet Crane |
| WH Pallet Lift |
| WH Spec |
| WH SW |
| WH Working station |
| X4.0 |
| Z3.1 |
| Z4.0 |
| Z5.0 |

### Required custom fields (always include both)

| Field | customfield ID | Format | Default value |
|---|---|---|---|
| Planned Start Date | `customfield_10160` | `"YYYY-MM-DD"` | **ask user** |
| Unexpected | `customfield_10193` | `[{"id": "10307"}]` (= No) | `[{"id": "10307"}]` |

## Steps

### 1. Parse arguments
Accept from `$ARGUMENTS` (all optional — prompt for missing required fields):
- `--type` / `-t` — issue type (default: `Task`)
- `--summary` / `-s` — ticket title (required)
- `--description` / `-d` — description in plain text
- `--label` / `-l` — one or more labels (comma-separated); confirmed in step 1b
- `--start` — planned start date (YYYY-MM-DD); **required — always ask if not provided**
- `--component` / `-c` — one or more components (comma-separated); confirmed in step 1b
- `--link` / `-L` — existing ticket key to link to (e.g. `RDNEW-1234`); confirmed in step 1b
- `--parent` / `-P` — parent epic/issue key to link to (uses "Relates" link, not sub-task — RDNEW sub-tasks cannot have children)
- `--attach` / `-A` — one or more file paths to attach (comma-separated); also detect any file paths the user pasted inline in the conversation

If `--summary` is not provided, ask it as a **single-question** `AskUserQuestion` first — offer a suggested title derived from the description (if any) as option 1, with `multiSelect: false`. Wait for the answer before continuing.

### 1b. Collect all ticket metadata in one pass

Present **one `AskUserQuestion` block** with exactly these 4 questions. Skip any whose value was already provided via args (e.g. if `--start` was given, omit the start date question and use 3 questions instead).

1. **Start date** — offer 3 concrete upcoming dates (today, the coming Monday, the Monday after). No explicit "Other" option — the built-in Other lets the user type any date. If the user picks Other, wait for them to type the date in their next message before continuing.

2. **Components** (`multiSelect: true`) — full list from the **Available components** table. Suggest sensible defaults in the question text (e.g. `FullStack General` + `GMT` for general GMT work, `Kiosk Puzzle` + `GMT` for puzzle-related). Use exactly the names from the table — casing matters.

3. **Labels** (`multiSelect: true`) — full list from the **Available labels** table. Suggest based on context (e.g. `PuzzleSmart` for puzzle-related). Include a `None` option; if selected, omit the `labels` key from the JSON entirely.

4. **Link to existing ticket** — one explicit option: `"No link"`. The built-in Other lets the user type a ticket number (e.g. `RDNEW-1234`). Question text: *"Do you want to link this ticket to an existing ticket? Select 'No link' or type the ticket number via Other."*

Wait for all answers before proceeding to Step 2.

### 2. Build the JSON payload and create

The CLI `--project` flag does not support components or required custom fields, so always use `--from-json`.

**Always use PowerShell** to build and write the payload — never use the Bash tool for this step. PowerShell's `Out-File -Encoding utf8` silently adds a BOM that causes `acli` to reject the file with "json: invalid format". Use `[System.IO.File]::WriteAllText` with explicit no-BOM encoding instead.

Build the payload as a PowerShell ordered hashtable and write it:

```powershell
powershell.exe -Command "
\$payload = [ordered]@{
    projectKey = 'RDNEW'
    summary    = '<summary>'
    type       = '<type>'
    labels     = @('<label1>', '<label2>')
    description = [ordered]@{
        type    = 'doc'
        version = 1
        content = @(
            [ordered]@{
                type    = 'paragraph'
                content = @([ordered]@{ type = 'text'; text = '<description text>' })
            }
        )
    }
    additionalAttributes = [ordered]@{
        components        = @([ordered]@{ name = '<comp1>' }, [ordered]@{ name = '<comp2>' })
        customfield_10160 = '<planned start date>'
        customfield_10193 = @([ordered]@{ id = '10307' })
    }
}
\$json = \$payload | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText(\"\$env:TEMP\jira_ticket.json\", \$json, [System.Text.UTF8Encoding]::new(\$false))
"
```

- Omit `labels` key entirely if no label provided.
- For a rich ADF description (headings, bullet lists), add more entries to the `content` array.
- Do NOT include `assignee` — tickets must be unassigned by default.

Then run:
```powershell
powershell.exe -Command "acli jira workitem create --from-json \"\$env:TEMP\jira_ticket.json\""
```

### 3. Create links (if any link was provided)

Run once for each of `--parent` / `--link` / the link answer from step 1b, if any. Skip if "No link" was selected.

```powershell
powershell.exe -Command "acli jira workitem link create --out '<new-key>' --in '<link-key>' --type 'Relates' --yes"
```

Note: RDNEW sub-tasks (e.g. RDNEW-3117, RDNEW-3118) cannot be parents in Jira — use "Relates" link instead.

Confirm each link with a one-line output:
```
Linked: RDNEW-XXXX ↔ <link-key>
```

### 4. Upload attachments (if any file paths were provided)

`acli` does not support attachment upload — use `Invoke-WebRequest` via PowerShell (proxy-safe; curl fails against corporate proxies).

**Collect image paths**: gather all paths from `--attach` / `-A` args AND any file paths the user pasted inline in the conversation (e.g. quoted Windows paths ending in `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.mp4`, `.pdf`).

**Get credentials** — check session file first, fall back to Windows Credential Manager (and write the session file for future calls):

```powershell
powershell.exe -Command "
\$sessionPath = \"\$env:TEMP\claude_jira_session.json\"
if (Test-Path \$sessionPath) {
    \$s = Get-Content \$sessionPath -Raw | ConvertFrom-Json
    Write-Output \"\$(\$s.email) \$(\$s.token)\"
} else {
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
    [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool CredRead(string target, uint type, int flags, out IntPtr credential);
    [DllImport("advapi32.dll")] public static extern void CredFree(IntPtr buffer);
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
    [System.IO.File]::WriteAllText(\$sessionPath, \$json, [System.Text.UTF8Encoding]::new(\$false))
}
"
```

Parse the output as `JIRA_EMAIL` (first word) and `JIRA_TOKEN` (second word).

**Upload each file** using `System.Net.Http.MultipartFormDataContent` (binary-safe, proxy-aware):

```powershell
powershell.exe -Command "
Add-Type -AssemblyName System.Net.Http
\$email    = '<JIRA_EMAIL>'
\$token    = '<JIRA_TOKEN>'
\$filePath = '<absolute-file-path>'
\$url      = 'https://utron-parking.atlassian.net/rest/api/3/issue/<new-key>/attachments'
\$b64      = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(\"\${email}:\${token}\"))
\$proxy    = [System.Net.WebRequest]::GetSystemWebProxy()
\$proxyUri = \$proxy.GetProxy(\$url)
\$handler  = New-Object System.Net.Http.HttpClientHandler
if (\$proxyUri.AbsoluteUri -ne \$url) {
    \$handler.Proxy = New-Object System.Net.WebProxy(\$proxyUri, \$true)
    \$handler.UseDefaultCredentials = \$true
}
\$client   = New-Object System.Net.Http.HttpClient(\$handler)
\$client.DefaultRequestHeaders.Add('Authorization', \"Basic \$b64\")
\$client.DefaultRequestHeaders.Add('X-Atlassian-Token', 'no-check')
\$fileName  = [System.IO.Path]::GetFileName(\$filePath)
\$multipart = New-Object System.Net.Http.MultipartFormDataContent
\$stream    = [System.IO.File]::OpenRead(\$filePath)
\$part      = New-Object System.Net.Http.StreamContent(\$stream)
\$part.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('application/octet-stream')
\$multipart.Add(\$part, 'file', \$fileName)
\$response  = \$client.PostAsync(\$url, \$multipart).Result
\$body      = \$response.Content.ReadAsStringAsync().Result
\$stream.Dispose()
if (\$response.IsSuccessStatusCode) {
    (\$body | Select-String '\"filename\":\"([^\"]+)\"').Matches | ForEach-Object { Write-Output \$_.Groups[1].Value }
} else {
    Write-Error \"Upload failed (\$([int]\$response.StatusCode)): \$body\"
}
"
```

- On success (filename printed): echo `Attached: <filename> → RDNEW-XXXX`
- On 401/403: tell the user the token may have expired and stop
- On other error: print the error body and stop

**After all uploads**, verify using acli (no credentials needed):
```bash
acli jira workitem view <new-key> --fields attachment --json | python -c "import json, sys; [print(a['filename']) for a in json.load(sys.stdin).get('fields', {}).get('attachment', [])]"
```

Print each filename returned. If any expected file is missing, report it to the user.

### 5. Report result

On success echo:
```
Created: https://utron-parking.atlassian.net/browse/RDNEW-XXXX
```

On error, print the raw CLI output and stop.
