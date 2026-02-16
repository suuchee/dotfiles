---
name: GitHub Environment Awareness
description: This skill should be used when the user is about to "create a PR", "review PR", "prepare for deployment", or when working on CI/CD workflows. It identifies environment variables and secrets that should be configured in GitHub but may be missing. Also triggered when the user mentions "GitHub secrets", "GitHub variables", "environment setup", or asks "what variables do I need to set?". This skill provides awareness and suggestions only - it does not perform actual configuration.
---

# GitHub Environment Awareness

This skill identifies environment variables and secrets that should be configured in GitHub Actions but may be missing or misconfigured. It provides awareness and suggestions to help developers ensure their CI/CD pipelines have all required configuration before deployment.

## Purpose

Analyze project context to detect:

1. Environment variables referenced in workflows but not configured in GitHub
2. Secrets that should be set for deployments
3. Scope recommendations (Environment vs Repository level)
4. Secret vs Variable classification based on sensitivity

## When to Activate

Trigger this skill in the following scenarios:

- Before creating a Pull Request
- When reviewing CI/CD workflow files
- When `.env` files are modified
- When deployment-related tasks are being performed
- When user asks about GitHub configuration requirements

## Analysis Process

### Step 1: Gather Project Context

Scan the following sources to identify required variables:

**Workflow Files** (`.github/workflows/*.yml`):
```yaml
# Look for env references
env:
  PROJECT_ID: ${{ vars.PROJECT_ID }}
  API_KEY: ${{ secrets.API_KEY }}

# Look for environment declarations
jobs:
  deploy:
    environment: production
```

**Environment Files** (`.env`, `.env.example`, `.env.local`):
```
# Variables that may need GitHub configuration
NEXT_PUBLIC_API_URL=
DATABASE_URL=
```

**Application Configuration**:
- `next.config.js` / `next.config.mjs` - Next.js environment variables
- `package.json` scripts - Build-time variables
- Docker/Compose files - Container environment

### Step 2: Check Current GitHub Configuration

Query existing GitHub configuration using `gh` CLI:

```bash
# List repository secrets
gh secret list

# List repository variables
gh variable list

# List environment secrets (for each environment)
gh secret list -e <environment_name>

# List environment variables
gh variable list -e <environment_name>

# List available environments
gh api repos/:owner/:repo/environments --jq '.environments[].name'
```

### Step 3: Classify Variables

Determine whether each variable should be a **Secret** or **Variable**:

**Secrets** (encrypted, not visible after set):
- API keys and tokens
- Passwords and credentials
- Service account JSON/keys
- Private keys and certificates
- OAuth client secrets
- Database connection strings with passwords
- Any value containing sensitive authentication data

**Variables** (visible, not encrypted):
- Project IDs and names
- Region/zone identifiers
- Feature flags (true/false)
- Public URLs
- Environment identifiers
- Non-sensitive configuration

### Step 4: Determine Scope

Recommend appropriate scope for each variable:

**Environment Scope** (`-e <env>`):
- Variables that differ between environments (stg, prod)
- Deployment-specific credentials
- Environment-specific feature flags
- Use when: Different values needed per environment

**Repository Scope** (default):
- Variables shared across all workflows
- CI-only configuration (not deployment)
- Values that don't change between environments
- Use when: Same value needed everywhere

### Step 5: Generate Report

Present findings in a clear format:

```markdown
## GitHub Configuration Analysis

### Missing Configuration

| Variable | Type | Recommended Scope | Source |
|----------|------|-------------------|--------|
| `PROJECT_ID` | Variable | Environment (stg, prod) | workflow deploy.yml |
| `FIREBASE_API_KEY` | Secret | Environment | .env.example |
| `NPM_TOKEN` | Secret | Repository | workflow ci.yml |

### Already Configured

| Variable | Type | Current Scope |
|----------|------|---------------|
| `GH_TOKEN` | Secret | Repository |

### Recommendations

1. **Environment-specific secrets**: Consider moving `X` to environment scope
2. **Missing environments**: Environment `prod` referenced but not created
```

## Common Patterns

### Next.js / Firebase Projects

Typical variables for Next.js with Firebase:

```
# Secrets (sensitive)
NEXT_PUBLIC_FIREBASE_API_KEY
SERVICE_ACCOUNT_JSON
WIF_PROVIDER

# Variables (non-sensitive but environment-specific)
PROJECT_ID
NEXT_PUBLIC_FIREBASE_PROJECT_ID
```

### GCP Deployment Projects

Typical variables for GCP deployments:

```
# Secrets
SERVICE_ACCOUNT_DEPLOY    # SA email for WIF
WIF_PROVIDER_DEPLOY       # Workload Identity Federation provider

# Variables
PROJECT_ID                # GCP project ID
REGION                    # Deployment region
```

### General CI/CD

Common CI/CD variables:

```
# Secrets
NPM_TOKEN                 # For private npm packages
CODECOV_TOKEN             # For coverage reports
SONAR_TOKEN               # For code quality

# Variables
NODE_VERSION              # Node.js version
```

## Important Notes

### This Skill Does NOT

- Create or modify GitHub secrets/variables
- Execute `gh secret set` or `gh variable set` commands
- Make changes to GitHub configuration

### This Skill DOES

- Analyze and identify missing configuration
- Provide recommendations and classifications
- Help users understand what needs to be configured
- Suggest appropriate scopes and types

### User Action Required

After receiving recommendations, the user should:

1. Review the suggested configuration
2. Decide on actual values for each variable
3. Use `gh secret set` / `gh variable set` to configure
4. Or use GitHub Web UI for sensitive values

Example commands for user reference:

```bash
# Environment secret
echo -n "value" | gh secret set SECRET_NAME -e environment_name

# Repository secret
echo -n "value" | gh secret set SECRET_NAME

# Environment variable (requires actual value, not empty)
gh variable set VAR_NAME -e environment_name -b "value"

# Repository variable
gh variable set VAR_NAME -b "value"
```

## Scope Reference

### Precedence Order

When the same variable exists at multiple scopes:
**Environment > Repository > Organization**

### Scope Comparison

| Feature | Environment | Repository |
|---------|-------------|------------|
| Requires `environment:` in workflow | Yes | No |
| Protection rules available | Yes | No |
| Required reviewers | Yes | No |
| Visibility | Per environment | All workflows |

### gh CLI Options

| Scope | Secret Command | Variable Command |
|-------|----------------|------------------|
| Environment | `gh secret set NAME -e ENV` | `gh variable set NAME -e ENV -b VAL` |
| Repository | `gh secret set NAME` | `gh variable set NAME -b VAL` |

## Additional Resources

### Reference Files

For detailed GitHub Actions secrets/variables documentation:
- **`references/github-secrets-variables.md`** - Complete API and CLI reference

### Related Commands

If user needs to actually configure variables, suggest:
- Project-specific: `/github-env-setup` command (if available)
- Manual: `gh secret set` / `gh variable set` commands
- Web UI: GitHub repository Settings > Secrets and variables
