# GitHub Actions Secrets & Variables Reference

Complete reference for GitHub Actions secrets and variables configuration.

## Overview

GitHub Actions supports storing sensitive and non-sensitive configuration at multiple scopes:

- **Secrets**: Encrypted, values hidden after set
- **Variables**: Not encrypted, values visible

## Scope Levels

### Repository Scope (Default)

Available to all workflows in the repository.

```bash
# Set repository secret
gh secret set SECRET_NAME -b "value"
gh secret set SECRET_NAME < file.txt

# Set repository variable
gh variable set VAR_NAME -b "value"

# List
gh secret list
gh variable list
```

### Environment Scope

Available only to workflows with `environment:` declaration.

```bash
# Set environment secret
gh secret set SECRET_NAME -e production -b "value"

# Set environment variable (value required, cannot be empty)
gh variable set VAR_NAME -e production -b "value"

# List for specific environment
gh secret list -e production
gh variable list -e production
```

**Workflow usage:**
```yaml
jobs:
  deploy:
    environment: production  # Required to access environment secrets/variables
    steps:
      - name: Use secret
        env:
          MY_SECRET: ${{ secrets.MY_SECRET }}
          MY_VAR: ${{ vars.MY_VAR }}
```

### Organization Scope (Paid Feature)

Available across multiple repositories. Requires GitHub Team or Enterprise.

```bash
# Set organization secret (paid feature)
gh secret set SECRET_NAME -o org-name --visibility all
gh secret set SECRET_NAME -o org-name --repos repo1,repo2

# Set organization variable (paid feature)
gh variable set VAR_NAME -o org-name -b "value"
```

## Precedence Order

When same name exists at multiple scopes:

**Environment > Repository > Organization**

## gh CLI Commands

### Secrets

```bash
# Create/Update
gh secret set <name> [flags]
  -b, --body string       Value (reads stdin if not specified)
  -e, --env string        Set deployment environment secret
  -f, --env-file file     Load from dotenv file
  -o, --org string        Set organization secret
  -r, --repos string      Repos for org secret (comma-separated)
  -v, --visibility string Org visibility: all|private|selected

# List
gh secret list [flags]
  -e, --env string        List environment secrets
  -o, --org string        List organization secrets

# Delete
gh secret delete <name> [flags]
  -e, --env string        Delete environment secret
  -o, --org string        Delete organization secret
```

### Variables

```bash
# Create/Update
gh variable set <name> [flags]
  -b, --body string       Value (REQUIRED, cannot be empty)
  -e, --env string        Set deployment environment variable
  -f, --env-file file     Load from dotenv file
  -o, --org string        Set organization variable
  -r, --repos string      Repos for org variable
  -v, --visibility string Org visibility: all|private|selected

# List
gh variable list [flags]
  -e, --env string        List environment variables
  -o, --org string        List organization variables

# Delete
gh variable delete <name> [flags]
  -e, --env string        Delete environment variable
  -o, --org string        Delete organization variable

# Get single variable
gh variable get <name> [flags]
  -e, --env string        Get environment variable
  -o, --org string        Get organization variable
```

### Environments

```bash
# List environments
gh api repos/:owner/:repo/environments --jq '.environments[].name'

# Create environment (via API)
gh api repos/:owner/:repo/environments/ENV_NAME -X PUT

# Delete environment (via API)
gh api repos/:owner/:repo/environments/ENV_NAME -X DELETE
```

## Workflow Syntax

### Accessing in Workflows

```yaml
env:
  # Repository-level (always available)
  REPO_SECRET: ${{ secrets.REPO_SECRET }}
  REPO_VAR: ${{ vars.REPO_VAR }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Use in step
        env:
          MY_SECRET: ${{ secrets.MY_SECRET }}
        run: echo "Using secret"

  deploy:
    environment: production  # Required for environment secrets
    runs-on: ubuntu-latest
    steps:
      - name: Use environment secret
        env:
          PROD_SECRET: ${{ secrets.PROD_SECRET }}  # From production env
          PROD_VAR: ${{ vars.PROD_VAR }}
```

### Conditional Environment

```yaml
jobs:
  deploy:
    environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
```

## Security Considerations

### Secrets

- Encrypted using Libsodium sealed boxes
- Automatically masked in logs
- Not passed to forked repository workflows
- Not passed to reusable workflows by default
- Cannot be viewed after creation (only updated/deleted)

### Variables

- Stored in plain text
- Visible to anyone with repository read access
- Appear in logs unless explicitly hidden
- Can be viewed and edited anytime

### Best Practices

1. **Minimum privilege**: Grant only necessary permissions
2. **Rotate regularly**: Update secrets periodically
3. **Use environments**: Add protection rules for production
4. **Avoid hardcoding**: Never commit secrets to repository
5. **Use GitHub Apps**: Prefer apps over personal tokens

## Common Patterns

### Workload Identity Federation (GCP)

```yaml
jobs:
  deploy:
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.SERVICE_ACCOUNT }}
```

Required secrets:
- `WIF_PROVIDER`: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER`
- `SERVICE_ACCOUNT`: `sa-name@project.iam.gserviceaccount.com`

### Docker Registry

```yaml
steps:
  - uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
```

### npm Private Packages

```yaml
steps:
  - run: npm ci
    env:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

Required `.npmrc`:
```
//registry.npmjs.org/:_authToken=${NPM_TOKEN}
```

### Firebase Deployment

```yaml
env:
  NEXT_PUBLIC_FIREBASE_API_KEY: ${{ secrets.NEXT_PUBLIC_FIREBASE_API_KEY }}
  NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN: ${{ secrets.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN }}
  NEXT_PUBLIC_FIREBASE_PROJECT_ID: ${{ secrets.NEXT_PUBLIC_FIREBASE_PROJECT_ID }}
```

## Troubleshooting

### Secret Not Available

**Symptom**: `${{ secrets.NAME }}` is empty

**Causes**:
1. Secret doesn't exist at expected scope
2. Missing `environment:` declaration for environment secrets
3. Workflow from forked repository
4. Reusable workflow without `secrets: inherit`

**Solutions**:
```bash
# Verify secret exists
gh secret list
gh secret list -e ENV_NAME

# Check workflow has environment
# environment: production
```

### Variable Empty String Error

**Symptom**: `HTTP 422: Invalid request - value required`

**Cause**: Variables cannot be empty string

**Solution**: Use a placeholder or actual value
```bash
gh variable set NAME -b "placeholder"
```

### Permission Denied

**Symptom**: `HTTP 403: Must have admin rights`

**Cause**: Insufficient repository permissions

**Solution**: Request admin access or use repository owner account

## API Reference

### REST API Endpoints

```bash
# Repository secrets
GET    /repos/{owner}/{repo}/actions/secrets
GET    /repos/{owner}/{repo}/actions/secrets/{secret_name}
PUT    /repos/{owner}/{repo}/actions/secrets/{secret_name}
DELETE /repos/{owner}/{repo}/actions/secrets/{secret_name}

# Environment secrets
GET    /repos/{owner}/{repo}/environments/{env}/secrets
GET    /repos/{owner}/{repo}/environments/{env}/secrets/{secret_name}
PUT    /repos/{owner}/{repo}/environments/{env}/secrets/{secret_name}
DELETE /repos/{owner}/{repo}/environments/{env}/secrets/{secret_name}

# Repository variables
GET    /repos/{owner}/{repo}/actions/variables
GET    /repos/{owner}/{repo}/actions/variables/{name}
POST   /repos/{owner}/{repo}/actions/variables
PATCH  /repos/{owner}/{repo}/actions/variables/{name}
DELETE /repos/{owner}/{repo}/actions/variables/{name}

# Environment variables
GET    /repos/{owner}/{repo}/environments/{env}/variables
GET    /repos/{owner}/{repo}/environments/{env}/variables/{name}
POST   /repos/{owner}/{repo}/environments/{env}/variables
PATCH  /repos/{owner}/{repo}/environments/{env}/variables/{name}
DELETE /repos/{owner}/{repo}/environments/{env}/variables/{name}
```

### Using gh api

```bash
# Get repository public key (needed for encryption)
gh api repos/:owner/:repo/actions/secrets/public-key

# List all secrets
gh api repos/:owner/:repo/actions/secrets --jq '.secrets[].name'

# List all variables
gh api repos/:owner/:repo/actions/variables --jq '.variables[] | "\(.name)=\(.value)"'

# List environment secrets
gh api repos/:owner/:repo/environments/production/secrets --jq '.secrets[].name'
```
