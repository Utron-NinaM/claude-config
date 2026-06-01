---
name: Key Vault migration is next step after config refactor
description: After the env config file split is done, the agreed next step is migrating secrets to Azure Key Vault
type: project
originSessionId: 3c7f280c-20bf-4d37-8ccd-cfdaa29ad806
---
After completing the multi-environment appsettings.json split (DEV/TEST/PROD/LOCAL), the team deliberately deferred moving secrets (connection strings with credentials) to Azure Key Vault.

**Why:** Keeping it simple for the current phase — secrets stay in env-specific JSON files locally. Key Vault migration was scoped out to reduce risk and complexity.

**How to apply:** When the env config refactor is complete or the user asks about secrets/credentials management, remind them that Key Vault migration is the agreed next step. The plan in `this-s-a-net-virtual-marble.md` (Phase 4) documents the approach:
- Store secrets in Key Vault with `AppSettings--ConnectionStrings--...` naming
- Replace manual `SecretClient` call in Startup.cs (lines 99-103) with `config.AddAzureKeyVault()` in Program.cs
- Enable Managed Identity on each App Service + Key Vault Secrets User role
