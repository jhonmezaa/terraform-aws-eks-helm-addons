# ECR Public Auth Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Clean up dead ECR Public auth code, update comments to reflect anonymous pull as default, and document the optional ephemeral resource pattern for enterprise use.

**Architecture:** ECR Public OCI registries (Karpenter, Dynatrace) work with anonymous pull. The dead `data "aws_ecrpublic_authorization_token"` data source is removed. Comments are updated to reflect reality. README is corrected to remove references to non-existent `ecr_public_token_username`/`ecr_public_token_password` variables.

**Tech Stack:** Terraform (~> 1.0), AWS Provider (~> 6.0), Helm Provider (~> 3.0)

---

### Task 1: Remove dead ECR Public data source from 4-data.tf

**Files:**
- Modify: `helm-addons/4-data.tf:16-19`

**Step 1: Remove the dead data source and its comment**

Replace lines 16-19 in `helm-addons/4-data.tf`:

```hcl
# BEFORE (remove these 4 lines):
# ECR Public authorization token for OCI registries (Karpenter, Dynatrace)
# NOTE: This datasource requires the AWS provider to be configured for us-east-1,
# or the caller must have access to ECR Public from their configured region.
data "aws_ecrpublic_authorization_token" "token" {}
```

The file should now contain only:

```hcl
# =============================================================================
# Data Sources
# =============================================================================
#
# This file contains data sources used across all addon resources.
# These data sources provide necessary information from AWS and are shared
# by multiple addon configurations.
# =============================================================================

# OIDC provider for IRSA (IAM Roles for Service Accounts)
# Used by all addons to establish trust relationships with Kubernetes service accounts
data "aws_iam_openid_connect_provider" "this" {
  arn = var.openid_provider_arn
}

# Current AWS partition (aws, aws-cn, aws-us-gov)
# Used for constructing ARNs in a partition-agnostic way
data "aws_partition" "current" {}

# Current AWS region
# Used for region-specific configurations
data "aws_region" "current" {}

# Current AWS account identity
# Provides account ID and other caller identity information
data "aws_caller_identity" "current" {}
```

**Step 2: Validate**

Run: `cd terraform-aws-eks-helm-addons/helm-addons && terraform fmt -check 4-data.tf`
Expected: No output (already formatted)

**Step 3: Commit**

```bash
cd terraform-aws-eks-helm-addons
git add helm-addons/4-data.tf
git commit -m "refactor: remove dead ECR Public auth data source from 4-data.tf"
```

---

### Task 2: Update comments in 6-karpenter.tf

**Files:**
- Modify: `helm-addons/6-karpenter.tf:106-110`

**Step 1: Replace the misleading OCI auth comment**

Replace lines 106-110 in `helm-addons/6-karpenter.tf`:

```hcl
# BEFORE:
  # OCI registry - authentication handled via provider-level registries config
  # NOTE: repository_username/repository_password removed due to Helm provider v3
  # incompatibility with ECR Public token endpoint (405 Method Not Allowed).
  # The caller must configure registries = [{ url = "oci://public.ecr.aws", ... }]
  # in the helm provider block.

# AFTER:
  # OCI registry from ECR Public - anonymous pull (no auth required).
  # For high-frequency CI/CD pipelines that hit ECR Public rate limits,
  # configure registries = [{ url = "oci://public.ecr.aws", ... }] in
  # the helm provider block using an ephemeral aws_ecrpublic_authorization_token.
```

**Step 2: Validate**

Run: `cd terraform-aws-eks-helm-addons/helm-addons && terraform fmt -check 6-karpenter.tf`
Expected: No output

**Step 3: Commit**

```bash
git add helm-addons/6-karpenter.tf
git commit -m "docs: update Karpenter OCI comment to reflect anonymous pull default"
```

---

### Task 3: Update comments in 18-dynatrace.tf

**Files:**
- Modify: `helm-addons/18-dynatrace.tf:5-6` (header comment)
- Modify: `helm-addons/18-dynatrace.tf:27-31` (helm_release comment)

**Step 1: Fix the header comment**

Replace line 6:
```hcl
# BEFORE:
# It uses an OCI registry from ECR Public, requiring an ECR Public auth token.

# AFTER:
# It uses an OCI registry from ECR Public (anonymous pull, no auth required).
```

**Step 2: Replace the helm_release OCI auth comment**

Replace lines 27-31:
```hcl
# BEFORE:
  # OCI registry - authentication handled via provider-level registries config
  # NOTE: repository_username/repository_password removed due to Helm provider v3
  # incompatibility with ECR Public token endpoint (405 Method Not Allowed).
  # The caller must configure registries = [{ url = "oci://public.ecr.aws", ... }]
  # in the helm provider block, or the chart will be pulled anonymously.

# AFTER:
  # OCI registry from ECR Public - anonymous pull (no auth required).
  # For high-frequency CI/CD pipelines that hit ECR Public rate limits,
  # configure registries = [{ url = "oci://public.ecr.aws", ... }] in
  # the helm provider block using an ephemeral aws_ecrpublic_authorization_token.
```

**Step 3: Validate**

Run: `cd terraform-aws-eks-helm-addons/helm-addons && terraform fmt -check 18-dynatrace.tf`
Expected: No output

**Step 4: Commit**

```bash
git add helm-addons/18-dynatrace.tf
git commit -m "docs: update Dynatrace OCI comment to reflect anonymous pull default"
```

---

### Task 4: Update README.md - Karpenter section

**Files:**
- Modify: `README.md` (Karpenter section, lines ~296-343)

**Step 1: Replace the Karpenter section**

Replace the entire Karpenter section (from `### Karpenter` to just before `### External Secrets Operator`) with:

```markdown
### Karpenter

Next-generation Kubernetes node autoscaler.

**Features**:

- Fast node provisioning (<1 minute)
- Spot instance support
- Bin-packing optimization
- Custom instance type selection

**Configuration**:

```hcl
enable_karpenter = true
karpenter = {
  helm_version      = "1.9.0"
  spotconsolidation = true
}

# Required: node role for instance profile
node_role_arn  = module.eks.node_iam_role_arn
node_role_name = module.eks.node_iam_role_name
```

**OCI Registry**: Karpenter is distributed via `oci://public.ecr.aws/karpenter`. Charts are pulled anonymously by default (no authentication required). See [ECR Public Authentication](#ecr-public-oci-authentication-optional) for optional authenticated access.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: simplify Karpenter README section, remove obsolete ECR auth"
```

---

### Task 5: Update README.md - Troubleshooting section

**Files:**
- Modify: `README.md` (troubleshooting section, lines ~682-713)

**Step 1: Replace the ECR troubleshooting section**

Replace the `### Karpenter Installation Failed: ECR Public Token Expired` section with:

```markdown
### Karpenter/Dynatrace OCI Chart Pull Rate Limited

**Symptoms**:

```
Error: could not download chart: failed to authorize
429 Too Many Requests
```

**Solution**: ECR Public has rate limits for anonymous pulls. Add authenticated access via the Helm provider:

```hcl
# Terraform >= 1.10 (recommended - tokens never stored in state)
ephemeral "aws_ecrpublic_authorization_token" "token" {}

provider "helm" {
  kubernetes { ... }
  registries = [{
    url      = "oci://public.ecr.aws"
    username = ephemeral.aws_ecrpublic_authorization_token.token.user_name
    password = ephemeral.aws_ecrpublic_authorization_token.token.password
  }]
}

# Terraform < 1.10 (token stored in state)
data "aws_ecrpublic_authorization_token" "token" {}

provider "helm" {
  kubernetes { ... }
  registries = [{
    url      = "oci://public.ecr.aws"
    username = data.aws_ecrpublic_authorization_token.token.user_name
    password = data.aws_ecrpublic_authorization_token.token.password
  }]
}
```
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update troubleshooting for ECR Public rate limiting"
```

---

### Task 6: Add ECR Public OCI section to README.md

**Files:**
- Modify: `README.md` (add new section before "## Contributing")

**Step 1: Add the new section**

Insert before the `## Contributing` section:

```markdown
## ECR Public OCI Authentication (Optional)

Karpenter and Dynatrace charts are hosted on ECR Public OCI registries (`oci://public.ecr.aws`). By default, charts are pulled **anonymously** without authentication. This works for most deployments.

### When You Need Authentication

| Scenario | Auth Needed? |
|----------|-------------|
| Standard deployment | No |
| CI/CD with occasional deploys | No |
| High-frequency CI/CD (50+ concurrent deploys) | Possibly |
| Private ECR registries | Yes (different mechanism) |

### Adding Authenticated Access

Configure the Helm provider in your **root module** (not inside this module - Terraform requires provider configuration in root modules):

**Terraform >= 1.10 (Recommended)**:

```hcl
# Tokens are ephemeral - never stored in Terraform state
ephemeral "aws_ecrpublic_authorization_token" "token" {}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }

  registries = [{
    url      = "oci://public.ecr.aws"
    username = ephemeral.aws_ecrpublic_authorization_token.token.user_name
    password = ephemeral.aws_ecrpublic_authorization_token.token.password
  }]
}
```

**Terraform < 1.10**:

```hcl
# Note: token is stored in Terraform state
data "aws_ecrpublic_authorization_token" "token" {}

provider "helm" {
  kubernetes { ... }

  registries = [{
    url      = "oci://public.ecr.aws"
    username = data.aws_ecrpublic_authorization_token.token.user_name
    password = data.aws_ecrpublic_authorization_token.token.password
  }]
}
```

### Why Can't the Module Handle This Internally?

Terraform requires provider configuration (`provider "helm" { ... }`) in the **root module**. Child modules cannot configure their own providers. This is a fundamental Terraform architectural constraint, not a limitation of this module. The module works out-of-the-box with anonymous pull for all standard use cases.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add ECR Public OCI authentication section to README"
```

---

### Task 7: Update CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Add v3.1.1 entry at the top**

Insert after the `# Changelog` header:

```markdown
## [v3.1.1] - 2026-02-28

### Changed

- Removed dead `data "aws_ecrpublic_authorization_token"` data source from `4-data.tf` (unused since v3.1.0)
- Updated OCI registry comments in `6-karpenter.tf` and `18-dynatrace.tf` to reflect anonymous pull as default behavior

### Documentation

- Simplified Karpenter README section (removed references to non-existent `ecr_public_token_username`/`ecr_public_token_password` variables)
- Added "ECR Public OCI Authentication (Optional)" section to README with ephemeral resource pattern
- Updated troubleshooting section for ECR Public rate limiting (replaced expired token guidance)
- Documented Terraform architectural constraint for provider-level OCI authentication
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add v3.1.1 changelog entry for ECR Public auth cleanup"
```

---

### Task 8: Final validation and tag

**Step 1: Format check**

Run: `cd terraform-aws-eks-helm-addons/helm-addons && terraform fmt -recursive -check`
Expected: No output (all files formatted)

**Step 2: Init and validate**

Run: `cd terraform-aws-eks-helm-addons/helm-addons && terraform init && terraform validate`
Expected: `Success! The configuration is valid.`

**Step 3: Tag and release**

```bash
cd terraform-aws-eks-helm-addons
git tag -a v3.1.1 -m "v3.1.1"
git push origin main
git push origin v3.1.1
gh release create v3.1.1 --title "v3.1.1" --notes "Clean up dead ECR Public auth code, document anonymous pull as default, add optional ephemeral resource auth pattern for enterprise use."
```
