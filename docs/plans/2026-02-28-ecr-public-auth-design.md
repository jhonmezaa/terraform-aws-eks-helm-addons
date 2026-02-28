# ECR Public Authentication Design

## Problem

The helm-addons module installs Karpenter and Dynatrace from OCI registries on ECR Public (`oci://public.ecr.aws`). Helm provider v3.x has a bug where `repository_username`/`repository_password` on `helm_release` resources sends POST to the ECR Public token endpoint, which only accepts GET, causing 405 errors.

The v3.1.0 fix removed per-resource auth, but left `data "aws_ecrpublic_authorization_token" "token" {}` as dead code in `4-data.tf` and unclear comments about auth responsibility.

## Decision

**Approach B: Anonymous Pull by Default + Document Ephemeral Pattern**

ECR Public charts are publicly accessible without authentication. Both Karpenter (chart 1.9.0) and Dynatrace (chart 1.8.1) were tested successfully with anonymous pull in the v3.1.0 deployment.

## Key Findings

1. **Terraform architectural constraint**: Child modules cannot configure providers. The `provider "helm" { registries = [...] }` block can only live in the root module. No solution can make ECR auth fully self-contained within this module.

2. **Anonymous pull works**: ECR Public allows unauthenticated pulls for all public content. Rate limits (approx 1 pull/sec/IP without auth) are sufficient for standard deployments.

3. **Ephemeral resources** (Terraform >= 1.10) are the official HashiCorp pattern for feeding credentials into provider configs without storing them in state.

## Changes

### Inside the module

1. **Remove dead code**: Delete `data "aws_ecrpublic_authorization_token" "token" {}` from `4-data.tf`
2. **Update comments**: Clarify in `6-karpenter.tf` and `18-dynatrace.tf` that anonymous pull is the default and auth is optional
3. **Update README**: Document OCI registry auth behavior

### Documentation (examples/)

4. **Add example**: Show the ephemeral resource pattern for enterprise/CI-CD use cases that need authenticated access

## When Auth Is Needed

| Scenario                                                   | Auth Required?           |
| ---------------------------------------------------------- | ------------------------ |
| Standard deployment (1 cluster)                            | No                       |
| CI/CD with few deploys                                     | No                       |
| High-frequency CI/CD (50+ concurrent deploys from same IP) | Possibly                 |
| Private ECR registries                                     | Yes (different solution) |

## Auth Pattern for Callers (Optional)

```hcl
# Terraform >= 1.10 - ephemeral resource (recommended)
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

# Terraform < 1.10 - data source (token stored in state)
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

## Version Impact

- **No breaking changes** - anonymous pull is backward compatible
- **Version**: PATCH bump (cleanup + docs)
