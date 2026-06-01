---
name: setup-env-configs
description: Sets up multi-environment configuration for ASP.NET Core projects. Use this skill whenever the user wants to: configure environment-specific appsettings files (Development/Test/Production), add EnvironmentName to Azure Web Deploy publish profiles (.pubxml files), add a publish-time guard that prevents deploying without an environment set, refactor Program.cs or Startup.cs for environment-aware Key Vault and CORS wiring, migrate a hardcoded Credentials class to appsettings, create a developer-local appsettings.Local.json override, or wire up any combination of these. Trigger on phrases like "set up env configs", "add environment to publish profiles", "create appsettings per environment", "configure environments", "EnvironmentName in pubxml", "set up dev/test/prod appsettings", "refactor appsettings", "migrate credentials to config", or when working on a new ASP.NET Core project that needs multi-environment deployment configuration.
---

## Steps

> For each step: if the target pattern is absent, skip it and add a "skipped — not found" row in the final report.

### 1. Locate the project

Find:
- The `.csproj` file (current dir or one level up)
- `Properties/PublishProfiles/` relative to the `.csproj`

If multiple `.csproj` files exist, ask the user which project to configure.

---

### 2. Extract env-specific values from appsettings.json

Look for lines with inline environment comments: `// DEV`, `// TEST`, `// PROD` (case-insensitive).

| Rule | Destination |
|------|-------------|
| Currently active (uncommented) value | `appsettings.Development.json` |
| Line marked `// TEST` | `appsettings.Test.json` |
| Line marked `// PROD` | `appsettings.Production.json` |
| No env marker | stays in `appsettings.json` |

Rewrite `appsettings.json`: remove all env-specific lines, add if missing:
```json
"AzureKeyVaultUri": "",
"JwtSecretKeyName": "JWTSecretKey",
"AllowedOrigins": []
```

If no commented-out blocks are found, skip extraction and create stub files (step 5).

---

### 3. Patch publish profiles

For each `.pubxml` in `Properties/PublishProfiles/` missing `<EnvironmentName>`, infer from the filename and `<MSDeployServiceURL>` / `<SiteUrlToLaunchAfterPublish>` (first match wins):

| Signal (case-insensitive) | Environment |
|---------------------------|-------------|
| Contains `dev` | `Development` |
| Contains `test` | `Test` |
| Contains `prod` or `slot` | `Production` |

If no signal matches, ask the user before editing. Insert inside the existing `<PropertyGroup>`:
```xml
    <EnvironmentName>Development</EnvironmentName>
  </PropertyGroup>
```

---

### 4. Add the MSBuild validation target

If `ValidateEnvironmentName` target is absent from the `.csproj`, add before `</Project>`:
```xml
  <Target Name="ValidateEnvironmentName" BeforeTargets="BeforePublish">
    <Error Condition="'$(EnvironmentName)' == ''"
           Text="EnvironmentName is not set in the publish profile. Add &lt;EnvironmentName&gt;Development|Test|Production&lt;/EnvironmentName&gt; to your .pubxml file." />
  </Target>

</Project>
```

---

### 5. Create / populate appsettings env files

For each of `appsettings.Development.json`, `appsettings.Test.json`, `appsettings.Production.json`:
- Values were extracted → write/merge extracted values
- File exists, no extraction → skip
- File missing, no extraction → create stub: `{ "AppSettings": {} }`

Populated files include extracted `ConnectionStrings`, `AppSettings`, `ApplicationInsights`, `Azure.SignalR`, `AllowedOrigins`, and the env-specific vault URI:
```json
"AzureKeyVaultUri": "https://<env>-keyvault.vault.azure.net/"
```
`JwtSecretKeyName` is shared — it stays in base `appsettings.json` only.

Always create `appsettings.Local.json` if absent (loaded last, highest priority):
```json
{
  "AppSettings": {},
  "AllowedOrigins": [ "http://localhost:3000", "http://localhost:3001" ]
}
```

Add to `.csproj` so the file is visible in Solution Explorer but never deployed:
```xml
<ItemGroup>
  <Content Update="appsettings.Local.json">
    <CopyToOutputDirectory>Never</CopyToOutputDirectory>
    <ExcludeFromPublish>true</ExcludeFromPublish>
  </Content>
</ItemGroup>
```

> `<Content Remove>` hides the file from VS Solution Explorer entirely; `<Content Update>` keeps it visible while still preventing deployment.

---

### 6. CORS origins migration (Startup.cs)

Find a hardcoded `WithOrigins(...)` call. If found, move localhost values to `AllowedOrigins` in `appsettings.Local.json` (machine-specific, not env-specific). Set `AllowedOrigins` to `[]` in all env files. Replace the call:
```csharp
var allowedOrigins = Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
builder.AllowAnyHeader().AllowAnyMethod().WithOrigins(allowedOrigins).AllowCredentials();
```
Populate `AllowedOrigins` in Test/Production files with `["<env-domain>"]` placeholders.

---

### 7. Credentials class migration

Find usage of a static `Credentials` class (e.g. `Credentials.AZURE_KEY_VAULT_URI`). If found, add `AzureKeyVaultUri` per env file and `JwtSecretKeyName` to base `appsettings.json`, then replace in `Startup.cs`:
```csharp
SecretClient kv = new SecretClient(new Uri(Configuration["AzureKeyVaultUri"]), new DefaultAzureCredential());
string secret = kv.GetSecret(Configuration["JwtSecretKeyName"]).Value.Value;
```
Remove the `using` for the credentials namespace if no longer referenced.

---

### 8. Program.cs env-aware wiring

**A) Manual `ConfigurationBuilder` in `Main()`** — if it loads `appsettings.json` but not env-specific files, update (break the fluent chain to guard Local loading):
```csharp
var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development";
var configBuilder = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: false)
    .AddJsonFile($"appsettings.{environment}.json", optional: true);
if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("IS_LOCAL")))
    configBuilder.AddJsonFile("appsettings.Local.json", optional: true);
var config = configBuilder.AddEnvironmentVariables().Build();
```

**B) `WebApplication.CreateBuilder`** — add immediately after the builder is created:
```csharp
if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("IS_LOCAL")))
    builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false);
```

**C) `CreateHostBuilder`** — add or replace `ConfigureAppConfiguration`:
```csharp
.ConfigureAppConfiguration((context, config) =>
{
    if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("IS_LOCAL")))
        config.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false);
})
```

If none of these patterns are detected, skip.

---

### 9. Update launchSettings.json

**Add `IS_LOCAL: "true"` to every existing profile** (Development, Test, Production, IIS Express). `launchSettings.json` is never deployed to Azure, so this is safe in all profiles — it ensures `appsettings.Local.json` loads for every local run regardless of which environment profile is selected:
```json
"environmentVariables": {
  "ASPNETCORE_ENVIRONMENT": "Development",
  "IS_LOCAL": "true"
}
```

For each of `Test` and `Production` not already present in `Properties/launchSettings.json`, add alongside the existing `Development` profile (include `IS_LOCAL`):
```json
"ProjectName (Test)": {
  "commandName": "Project",
  "launchBrowser": true,
  "launchUrl": "swagger",
  "environmentVariables": { "ASPNETCORE_ENVIRONMENT": "Test", "IS_LOCAL": "true" },
  "dotnetRunMessages": "true",
  "applicationUrl": "https://localhost:5001;http://localhost:5000"
}
```

---

### 10. Report

End with a summary table:

```
| Item                          | Action                                          |
|-------------------------------|-------------------------------------------------|
| appsettings.json              | Stripped env blocks (DEV/TEST/PROD)             |
| appsettings.Development.json  | Populated with DEV values                       |
| appsettings.Test.json         | Created with TEST values                        |
| appsettings.Production.json   | Created with PROD values                        |
| appsettings.Local.json        | Created (stub)                                  |
| ProjectName-Dev.pubxml        | Added EnvironmentName=Development               |
| ProjectName-Test.pubxml       | Added EnvironmentName=Test                      |
| ProjectName-Prod.pubxml       | Added EnvironmentName=Production                |
| ValidateEnvironmentName       | Added to ProjectName.csproj                     |
| Startup.cs — CORS             | Moved origins to AllowedOrigins[] in Local.json |
| Startup.cs — Key Vault        | Migrated from Credentials class                 |
| Program.cs — ConfigBuilder    | Loads env + Local files (IS_LOCAL guarded)      |
| Program.cs — CreateBuilder    | Added appsettings.Local.json (IS_LOCAL guarded) |
| Program.cs — CreateHostBuilder| Added appsettings.Local.json (IS_LOCAL guarded) |
| launchSettings.json — profiles| Added Test + Production profiles                |
| launchSettings.json — IS_LOCAL| Added IS_LOCAL=true to all profiles             |
```
