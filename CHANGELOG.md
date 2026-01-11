# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-11

### Added

#### New Addons (8 total)

**Critical Infrastructure:**
- **AWS Load Balancer Controller** - ALB/NLB ingress management with AWS WAF integration
  - File: `helm-addons/9-aws-load-balancer-controller.tf`
  - Comprehensive IAM policy for ELB, EC2, WAF, Shield, and ACM
  - Automatic VPC and region configuration

- **Metrics Server** - Essential for HPA and `kubectl top` commands
  - File: `helm-addons/10-metrics-server.tf`
  - No IRSA required (reads from kubelet API)
  - Pre-configured with kubelet TLS settings

- **External DNS** - Automatic Route53 DNS record management
  - File: `helm-addons/11-external-dns.tf`
  - Domain filtering support
  - TXT record ownership tracking

- **Cert-Manager** - Automated TLS certificate management
  - File: `helm-addons/12-cert-manager.tf`
  - Let's Encrypt integration
  - Optional CRD installation

- **AWS for Fluent Bit** - CloudWatch Logs integration
  - File: `helm-addons/13-aws-for-fluent-bit.tf`
  - Optional CloudWatch log group creation with retention policies
  - Optimized for AWS compared to Fluentd

**High Availability & Disaster Recovery:**
- **Velero** - Backup and disaster recovery
  - File: `helm-addons/14-velero.tf`
  - S3 backup storage with regional configuration
  - EBS snapshot support via AWS plugin

- **Vertical Pod Autoscaler (VPA)** - Resource optimization
  - File: `helm-addons/15-vpa.tf`
  - Auto resource request/limit recommendations
  - Requires Metrics Server (automatic dependency)

- **AWS Node Termination Handler** - Graceful spot termination
  - File: `helm-addons/16-aws-node-termination-handler.tf`
  - Spot interruption draining
  - Scheduled event handling

- **Ingress Nginx** - NGINX-based ingress controller
  - File: `helm-addons/17-ingress-nginx.tf`
  - NLB integration with cross-zone load balancing
  - Alternative to AWS Load Balancer Controller

#### Architectural Improvements

- **Dynamic Region Prefix Mapping** (`helm-addons/0-locals.tf`)
  - Automatic region prefix detection for 15+ AWS regions
  - Centralized local variables: `oidc_provider_url`, `name_prefix`, `policy_prefix`, `common_tags`
  - Support for custom region prefixes via `region_prefix` variable

- **Object-Based Variable Configuration** (`helm-addons/2-variables.tf`)
  - Complete refactor from simple strings to structured objects
  - Consistent pattern across all addons:
    - `helm_version` (optional string)
    - `namespace` (optional with defaults)
    - `create_namespace` (optional bool, default: true)
    - `timeout` (optional number, default: 300)
    - `set_values` (optional list of objects for custom Helm values)
  - Addon-specific options (e.g., `domain_filters`, `backup_bucket`, `install_crds`)

- **Comprehensive Outputs** (`helm-addons/8-outputs.tf`)
  - Consistent pattern for all addons:
    - `{addon}_role_arn` - IAM role ARN for IRSA
    - `{addon}_role_name` - IAM role name
    - `{addon}_helm_release_name` - Helm release name
    - `{addon}_helm_release_version` - Deployed chart version
  - Special outputs (e.g., CloudWatch log group, instance profile)

- **Comprehensive Documentation** (`README.md`)
  - 600+ lines covering all 13 addons
  - Basic and advanced usage examples
  - Detailed addon documentation (features, configuration, IAM policies)
  - Architecture and naming conventions
  - Migration guide from v1.x to v2.0
  - Best practices and troubleshooting

### Changed

- **Updated Existing Addons** to use new locals pattern:
  - `helm-addons/1-keda.tf` - Uses `local.oidc_provider_url`, `local.name_prefix`, `local.common_tags`
  - `helm-addons/6-karpenter.tf` - Refactored with locals and backwards compatibility
  - `helm-addons/7-external-secrets.tf` - Standardized IRSA pattern

- **Backwards Compatibility Variables**:
  - Added `coalesce()` pattern to support deprecated variables
  - Old variables still work: `karpenter_helm_version`, `keda_helm_version`, `external_secrets_helm_version`, `spotconsolidation`
  - Deprecation warnings via variable descriptions

### Fixed

- **Helm `set` Configuration** - Corrected to use official list syntax
  - Changed from individual `set {}` blocks and `dynamic "set" {}` to proper list syntax: `set = [...]`
  - Used `concat()` to merge required addon values with custom user values
  - Applied `tostring()` for boolean values where needed
  - Implemented conditional expressions for optional values
  - Affected all 12 addons with helm_release resources
  - Reduces code by 97 lines while improving correctness

### Security

- **Least Privilege IAM Policies** for all new addons
  - Scoped permissions per addon requirements
  - IRSA trust policies limited to specific service accounts
  - Resource-level permissions where applicable

### Module Statistics

- **Total Addons**: 13 (5 existing + 8 new)
- **Total Files Modified/Created**: 16 files
- **Lines Added**: +2,482
- **Lines Removed**: -133
- **Net Change**: +2,349 lines

### Compatibility

- ✅ **Fully backwards compatible** - Old variable format still works
- ✅ **No breaking changes** - Existing deployments continue to function
- ✅ **Terraform**: >= 1.0
- ✅ **AWS Provider**: ~> 6.0
- ✅ **Helm Provider**: ~> 2.0
- ✅ **Kubernetes Provider**: ~> 2.0

### Migration Notes

To migrate from v1.x to v2.0:

**Option 1: Continue using old variables (no changes required)**
```hcl
karpenter_helm_version = "v0.33.0"
spotconsolidation      = true
```

**Option 2: Migrate to new object-based syntax (recommended)**
```hcl
karpenter = {
  helm_version      = "v0.33.0"
  spotconsolidation = true
  namespace         = "kube-system"
  timeout           = 300
  set_values        = []
}
```

Both approaches work identically. New features and flexibility are available only with object-based syntax.

---

## [1.0.0] - 2024-XX-XX

### Added

- Initial release with 5 core addons:
  - KEDA - Event-driven autoscaling
  - Karpenter - Next-generation node autoscaler
  - External Secrets Operator - AWS Secrets Manager integration
  - AWS EBS CSI Driver - Persistent volume support
  - Cluster Autoscaler - Legacy autoscaler (deprecated)
- IRSA (IAM Roles for Service Accounts) integration
- Basic variable configuration
- Module outputs for IAM roles and Helm releases

[2.0.0]: https://github.com/jhonmezaa/terraform-aws-eks-helm-addons/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/jhonmezaa/terraform-aws-eks-helm-addons/releases/tag/v1.0.0
