# Terraform AWS EKS Helm Addons

Production-ready Terraform module for deploying Kubernetes Helm-based addons on Amazon EKS clusters with IAM Roles for Service Accounts (IRSA) integration.

## Features

### Comprehensive Addon Support (15 addons)

**Critical Infrastructure** (⭐⭐⭐):

- ✅ AWS Load Balancer Controller - ALB/NLB ingress management
- ✅ Metrics Server - HPA/VPA resource metrics
- ✅ Karpenter - Next-generation node autoscaling
- ✅ External DNS - Automatic Route53 record management
- ✅ Cert-Manager - Automated TLS certificate management

**Observability & Logging**:

- ✅ AWS for Fluent Bit - CloudWatch Logs integration
- ✅ Vertical Pod Autoscaler (VPA) - Resource optimization

**Security & Secrets**:

- ✅ External Secrets Operator - AWS Secrets Manager sync
- ✅ KEDA - Event-driven autoscaling

**High Availability & DR**:

- ✅ Velero - Backup and disaster recovery
- ✅ AWS Node Termination Handler - Graceful spot termination
- ✅ Ingress Nginx - NGINX-based ingress controller

**Storage & Observability**:

- ✅ AWS EBS CSI Driver - EBS persistent volumes
- ✅ Dynatrace Operator - Full-stack observability

**Deprecated**:

- ⚠️ Cluster Autoscaler - Use Karpenter instead

### Advanced Features

- **IRSA Integration**: All addons use IAM Roles for Service Accounts for secure AWS API access
- **Flexible Configuration**: Per-addon object configuration with helm values, timeouts, namespaces
- **Dynamic Region Support**: Automatic region prefix detection for multi-region deployments
- **Backwards Compatible**: Legacy variable support with deprecation warnings
- **Dependency Management**: Smart addon ordering and dependencies
- **Custom Helm Values**: Support for custom configuration via `values` (YAML) and `set_values`

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.3  |
| aws       | >= 6.0  |
| helm      | >= 3.0  |

## Usage

### Basic Example

```hcl
module "eks_helm_addons" {
  source = "github.com/jhonmezaa/terraform-aws-eks-helm-addons//helm-addons?ref=v3.2.0"

  account_name = "prod"
  project_name = "myapp"

  eks_name             = module.eks.cluster_name
  eks_region           = "us-east-1"
  eks_cluster_endpoint = module.eks.cluster_endpoint
  openid_provider_arn  = module.eks.oidc_provider_arn

  # Critical addons
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    vpc_id = module.vpc.vpc_id # optional, auto-discovered from IMDS when null
  }
  enable_metrics_server = true
  enable_karpenter                    = true

  # Karpenter requires node role
  node_role_arn  = module.eks.node_iam_role_arn
  node_role_name = module.eks.node_iam_role_name

  tags_common = {
    Environment = "production"
  }
}
```

### Complete Example with Custom Configuration

```hcl
module "eks_helm_addons" {
  source = "github.com/jhonmezaa/terraform-aws-eks-helm-addons//helm-addons?ref=v3.2.0"

  account_name = "prod"
  project_name = "myapp"

  eks_name             = module.eks.cluster_name
  eks_region           = "us-east-1"
  eks_cluster_endpoint = module.eks.cluster_endpoint
  openid_provider_arn  = module.eks.oidc_provider_arn

  node_role_arn  = module.eks.node_iam_role_arn
  node_role_name = module.eks.node_iam_role_name

  # AWS Load Balancer Controller
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    helm_version = "1.6.2"
    namespace    = "kube-system"
    vpc_id       = module.vpc.vpc_id
    set_values = [
      {
        name  = "replicaCount"
        value = "2"
      }
    ]
  }

  # Metrics Server
  enable_metrics_server = true
  metrics_server = {
    helm_version = "3.11.0"
  }

  # External DNS
  enable_external_dns = true
  external_dns = {
    helm_version      = "1.13.1"
    domain_filters    = ["example.com", "example.org"]
    route53_zone_arns = ["arn:aws:route53:::hostedzone/Z0123456789ABC"]
  }

  # Cert-Manager
  enable_cert_manager = true
  cert_manager = {
    helm_version = "v1.13.2"
    install_crds = true
  }

  # AWS for Fluent Bit
  enable_aws_for_fluent_bit = true
  aws_for_fluent_bit = {
    cloudwatch_log_group     = "/aws/eks/prod-myapp/logs"
    cloudwatch_log_retention = 7
  }

  # Karpenter
  enable_karpenter = true
  karpenter = {
    helm_version            = "1.9.0"
    spotconsolidation       = true
    enable_spot_termination = true # SQS interruption queue + EventBridge rules
  }

  # External Secrets
  enable_external_secrets = true
  external_secrets = {
    secrets_manager_arns = ["arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/*"]
    ssm_parameter_arns   = ["arn:aws:ssm:us-east-1:123456789012:parameter/myapp/*"]
  }

  # KEDA
  enable_keda = true

  # Velero
  enable_velero = true
  velero = {
    backup_bucket = "my-velero-backup-bucket"
  }

  # VPA
  enable_vpa = true

  # AWS Node Termination Handler
  enable_aws_node_termination_handler = true

  # Ingress Nginx
  enable_ingress_nginx = true

  tags_common = {
    Environment = "production"
  }
}
```

## Addon Details

### AWS Load Balancer Controller

Manages AWS Elastic Load Balancers for Kubernetes clusters.

**Features**:

- ALB Ingress support with advanced routing
- NLB Service type LoadBalancer
- IP and instance targeting modes
- AWS WAF integration
- SSL/TLS termination

**Configuration**:

```hcl
enable_aws_load_balancer_controller = true
aws_load_balancer_controller = {
  helm_version = "1.6.2"      # Optional
  namespace    = "kube-system" # Default
  timeout      = 300           # Seconds
  vpc_id       = "vpc-0123abcd" # Optional: chart vpcId. When null the controller uses IMDS (hop limit >= 2)
  values       = []            # Optional raw YAML values files
  set_values = [
    {
      name  = "replicaCount"
      value = "2"
    }
  ]
}
```

### Metrics Server

Required for Horizontal Pod Autoscaler (HPA) and `kubectl top` commands.

**Features**:

- Provides `metrics.k8s.io` API
- Essential for HPA
- Required for VPA
- No IRSA required (reads from kubelet)

**Configuration**:

```hcl
enable_metrics_server = true
metrics_server = {
  helm_version = "3.11.0"
}
```

### External DNS

Automatically manages Route53 DNS records for Services and Ingresses.

**Features**:

- Automatic DNS record creation/deletion
- Multiple hosted zone support
- Domain filtering
- TXT record ownership tracking

**Configuration**:

```hcl
enable_external_dns = true
external_dns = {
  helm_version      = "1.13.1"
  domain_filters    = ["example.com"]
  route53_zone_arns = ["arn:aws:route53:::hostedzone/Z0123456789ABC"] # Optional: restrict record changes (default: all zones)
}
```

### Cert-Manager

Automates TLS certificate management.

**Features**:

- Let's Encrypt integration
- Automatic certificate renewal
- Multiple issuer support
- Kubernetes native CRDs

**Configuration**:

```hcl
enable_cert_manager = true
cert_manager = {
  helm_version = "v1.13.2"
  install_crds = true  # Install CRDs
}
```

### AWS for Fluent Bit

Lightweight log forwarder to CloudWatch Logs.

**Features**:

- Optimized for AWS
- CloudWatch Logs integration
- More efficient than Fluentd
- Filter and transform logs

**Configuration**:

```hcl
enable_aws_for_fluent_bit = true
aws_for_fluent_bit = {
  cloudwatch_log_group      = "/aws/eks/cluster/logs"
  cloudwatch_log_retention  = 7    # Days
  cloudwatch_log_kms_key_id = null # Optional KMS key ARN for the log group
}
```

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

  # Optional interruption handling: SQS queue + EventBridge rules (spot
  # interruption, rebalance, state change, AWS Health) and settings.interruptionQueue
  enable_spot_termination       = true
  sqs_message_retention_seconds = 300
  sqs_kms_master_key_id         = null # SQS-managed SSE when null
}

# Required: node role for instance profile (node_role_arn also scopes iam:PassRole)
node_role_arn  = module.eks.node_iam_role_arn
node_role_name = module.eks.node_iam_role_name
```

**OCI Registry**: Karpenter is distributed via `oci://public.ecr.aws/karpenter`. Charts are pulled anonymously by default (no authentication required). See [ECR Public OCI Authentication](#ecr-public-oci-authentication-optional) for optional authenticated access.

### External Secrets Operator

Syncs AWS Secrets Manager secrets to Kubernetes.

**Features**:

- AWS Secrets Manager integration
- Parameter Store support
- Automatic secret rotation
- Multiple secret stores

**Configuration**:

```hcl
enable_external_secrets = true
external_secrets = {
  helm_version         = "0.9.9"
  secrets_manager_arns = ["*"] # Default (all secrets). Restrict with secret ARNs/patterns
  ssm_parameter_arns   = []    # Grants SSM Parameter Store read when not empty
  kms_key_arns         = []    # Grants kms:Decrypt when not empty
}
```

### KEDA

Event-driven autoscaling for Kubernetes workloads.

**Features**:

- Scale based on event sources
- SQS, CloudWatch, custom metrics
- HPA integration
- Azure DevOps agent scaling

**Configuration**:

```hcl
enable_keda = true
keda = {
  helm_version = "2.12.0"
}
```

The IRSA role is attached to the `keda-operator` service account through the chart's `podIdentity.aws.irsa.*` values.

### Velero

Backup and disaster recovery for Kubernetes.

**Features**:

- Cluster resource backup
- Persistent volume snapshots
- Scheduled backups
- Cluster migration support

**Configuration**:

```hcl
enable_velero = true
velero = {
  helm_version  = "5.1.0"
  backup_bucket = "my-velero-backups"  # S3 bucket
  plugin_image  = "velero/velero-plugin-for-aws:v1.11.0" # Default
}
```

### Vertical Pod Autoscaler (VPA)

Automatically adjusts container resource requests/limits.

**Features**:

- Auto resource recommendations
- Prevent over/under provisioning
- Recommendation and auto modes
- Requires Metrics Server

**Configuration**:

```hcl
enable_vpa = true
enable_metrics_server = true  # Required dependency
```

### AWS Node Termination Handler

Gracefully drain nodes before EC2 termination.

**Features**:

- Spot interruption handling
- Scheduled maintenance events
- ASG lifecycle hooks
- Graceful pod eviction

**Configuration**:

```hcl
enable_aws_node_termination_handler = true
aws_node_termination_handler = {
  enable_spot_interruption_draining = true
  enable_scheduled_event_draining   = true
}
```

### Ingress Nginx

NGINX-based Ingress controller.

**Features**:

- NGINX reverse proxy
- SSL/TLS termination
- WebSocket support
- Rate limiting

**Configuration**:

```hcl
enable_ingress_nginx = true
ingress_nginx = {
  helm_version = "4.8.3"
}
```

### AWS EBS CSI Driver

Dynamic provisioning of EBS volumes (IRSA on `ebs-csi-controller-sa`).

```hcl
enable_ebs_csi_driver = true
ebs_csi_driver = {
  kms_key_arns = ["arn:aws:kms:us-east-1:123456789012:key/..."] # Optional: customer managed keys for encrypted volumes
}
```

### Dynatrace Operator

Full-stack observability (`oci://public.ecr.aws/dynatrace`, no IAM role).

```hcl
enable_dynatrace = true
dynatrace = {
  csi_driver_enabled = true
}
```

### Cluster Autoscaler (deprecated)

```hcl
enable_cluster_autoscaler       = true
cluster_autoscaler_helm_version = "9.43.2"
```

## Input Variables

### Required Variables

| Name                   | Description                                                   | Type     |
| ---------------------- | ------------------------------------------------------------- | -------- |
| `account_name`         | Account name for resource naming (1-32 chars, `^[a-z0-9-]+$`) | `string` |
| `project_name`         | Project name for resource naming (1-32 chars, `^[a-z0-9-]+$`) | `string` |
| `eks_name`             | EKS cluster name                                              | `string` |
| `eks_region`           | AWS region of the cluster (used by Cluster Autoscaler)        | `string` |
| `eks_cluster_endpoint` | EKS API endpoint                                              | `string` |
| `openid_provider_arn`  | IAM OIDC provider ARN for IRSA                                | `string` |

### Optional Variables

| Name                  | Description                                                    | Type       | Default |
| --------------------- | -------------------------------------------------------------- | ---------- | ------- |
| `region_prefix`       | Region prefix (auto-detected from the provider region if null) | `string`   | `null`  |
| `use_region_prefix`   | Include the region prefix in resource names                    | `bool`     | `true`  |
| `tags_common`         | Common tags for all resources                                  | `map(any)` | `{}`    |
| `eks_cluster_version` | Kubernetes version (informational)                             | `string`   | `null`  |
| `node_role_arn`       | Node IAM role ARN (Karpenter: scopes `iam:PassRole`)           | `string`   | `null`  |
| `node_role_name`      | Node IAM role name (required when `enable_karpenter = true`)   | `string`   | `null`  |

### Addon toggles and configuration objects

Every addon is disabled by default and is configured through an object variable.

| Toggle                                | Object                                | Addon-specific attributes (besides the common ones)                                                       |
| ------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `enable_aws_load_balancer_controller` | `aws_load_balancer_controller`        | `vpc_id`                                                                                                  |
| `enable_metrics_server`               | `metrics_server`                      | -                                                                                                         |
| `enable_external_dns`                 | `external_dns`                        | `domain_filters`, `route53_zone_arns`                                                                     |
| `enable_cert_manager`                 | `cert_manager`                        | `install_crds`                                                                                            |
| `enable_aws_for_fluent_bit`           | `aws_for_fluent_bit`                  | `cloudwatch_log_group`, `cloudwatch_log_retention`, `cloudwatch_log_kms_key_id`                           |
| `enable_karpenter`                    | `karpenter`                           | `spotconsolidation`, `enable_spot_termination`, `sqs_message_retention_seconds`, `sqs_kms_master_key_id`  |
| `enable_keda`                         | `keda`                                | -                                                                                                         |
| `enable_external_secrets`             | `external_secrets`                    | `secrets_manager_arns`, `ssm_parameter_arns`, `kms_key_arns`                                              |
| `enable_ebs_csi_driver`               | `ebs_csi_driver`                      | `kms_key_arns`                                                                                            |
| `enable_velero`                       | `velero`                              | `backup_bucket`, `plugin_image`                                                                           |
| `enable_vpa`                          | `vpa`                                 | -                                                                                                         |
| `enable_aws_node_termination_handler` | `aws_node_termination_handler`        | `enable_spot_interruption_draining`, `enable_scheduled_event_draining`                                    |
| `enable_ingress_nginx`                | `ingress_nginx`                       | `wait`                                                                                                    |
| `enable_dynatrace`                    | `dynatrace`                           | `csi_driver_enabled`                                                                                      |
| `enable_cluster_autoscaler`           | - (`cluster_autoscaler_helm_version`) | -                                                                                                         |

Deprecated inputs kept for backwards compatibility: `karpenter_helm_version`, `spotconsolidation`, `keda_helm_version`, `external_secrets_helm_version`, `ebs_csi_driver_helm_version`, `dynatrace_helm_version`.

### Addon Configuration Pattern

Each addon object shares these attributes:

```hcl
variable "addon_name" {
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "default-namespace")
    create_namespace = optional(bool, true)
    timeout          = optional(number, 300)
    values           = optional(list(string), []) # raw YAML values files
    set_values       = optional(list(object({
      name  = string
      value = string
    })), [])
    # Addon-specific options...
  })
  default = {}
}
```

## Outputs

Each addon provides consistent outputs (`null` when the addon is disabled):

| Output Pattern                 | Description                 |
| ------------------------------ | --------------------------- |
| `{addon}_role_arn`             | IAM role ARN for IRSA       |
| `{addon}_role_name`            | IAM role name               |
| `{addon}_helm_release_name`    | Helm release name           |
| `{addon}_helm_release_version` | Deployed Helm chart version |

Additional outputs: `karpenter_instance_profile_name`, `karpenter_interruption_queue_name`, `karpenter_interruption_queue_arn`, `aws_for_fluent_bit_log_group_name`.
Addons without IAM (`metrics_server`, `cert_manager`, `vpa`, `ingress_nginx`, `dynatrace`) only expose the `helm_release_*` outputs.

**Example outputs**:

```hcl
output "karpenter_role_arn" {
  value = module.eks_helm_addons.karpenter_role_arn
}

output "aws_load_balancer_controller_version" {
  value = module.eks_helm_addons.aws_load_balancer_controller_helm_release_version
}
```

## Examples

- [`examples/basic`](examples/basic) - AWS Load Balancer Controller + Metrics Server
- [`examples/complete`](examples/complete) - most addons with least-privilege options (Karpenter interruption queue, scoped External DNS / External Secrets)

## Architecture

### Resource Naming Convention

All resources follow a standardized naming pattern:

```
{region_prefix}-{resource-type}-eks-addons-{addon}-{account_name}-{project_name}
```

With `use_region_prefix = false` the `{region_prefix}-` part is omitted. IAM role and EventBridge rule names are truncated to 64 characters and SQS queue names to 80 (AWS limits).
Every resource is tagged with `tags_common` plus `Module`, `Name` and `ManagedBy = "Terraform"`.

**Examples**:

- IAM Role: `ause1-role-eks-addons-karpenter-prod-myapp`
- IAM Policy: `ause1-policy-eks-addons-external-dns-prod-myapp`
- Instance Profile: `ause1-instance-profile-eks-karpenter-prod-myapp`
- SQS queue: `ause1-sqs-eks-addons-karpenter-prod-myapp`
- EventBridge rule: `ause1-evtr-eks-addons-karpenter-spot-prod-myapp`

### Region Prefix Mapping

Auto-detected from the current AWS region (same map as `terraform-aws-eks`):

| Region         | Prefix  | Region           | Prefix  |
| -------------- | ------- | ---------------- | ------- |
| `us-east-1`    | `ause1` | `eu-central-1`   | `euc1`  |
| `us-east-2`    | `ause2` | `eu-north-1`     | `eun1`  |
| `us-west-1`    | `usw1`  | `ap-south-1`     | `aps1`  |
| `us-west-2`    | `usw2`  | `ap-southeast-1` | `apse1` |
| `eu-west-1`    | `euw1`  | `ap-southeast-2` | `apse2` |
| `eu-west-2`    | `euw2`  | `ap-northeast-1` | `apne1` |
| `eu-west-3`    | `euw3`  | `ap-northeast-2` | `apne2` |
| `ca-central-1` | `cac1`  | `sa-east-1`      | `sae1`  |

Any other region resolves to `custom`. Override with the `region_prefix` variable if needed.

### IRSA (IAM Roles for Service Accounts)

All addons requiring AWS API access use IRSA:

1. **Trust Policy**: Scoped to specific service account
2. **OIDC Provider**: EKS cluster OIDC provider
3. **Least Privilege**: Minimum required permissions
4. **Service Account Annotation**: `eks.amazonaws.com/role-arn`

## Migration from v1.x to v2.0

### Variable Structure Changes

**Old (deprecated)**:

```hcl
karpenter_helm_version = "v0.33.0"
spotconsolidation      = true
```

**New (recommended)**:

```hcl
karpenter = {
  helm_version      = "v0.33.0"
  spotconsolidation = true
  namespace         = "kube-system"
  timeout           = 300
}
```

Backwards compatibility is maintained - both work, but old variables show deprecation warnings.

## Best Practices

### 1. Start with Core Addons

```hcl
# Minimum recommended addons
enable_aws_load_balancer_controller = true
enable_metrics_server               = true
enable_karpenter                    = true  # or Cluster Autoscaler
enable_external_dns                 = true
enable_cert_manager                 = true
```

### 2. Enable Observability

```hcl
# Logging and monitoring
enable_aws_for_fluent_bit = true
enable_vpa                = true
```

### 3. Implement Disaster Recovery

```hcl
# Backup and HA
enable_velero                        = true
enable_aws_node_termination_handler  = true
```

### 4. Secure Secrets Management

```hcl
# Don't store secrets in Kubernetes directly
enable_external_secrets = true
```

### 5. Use Custom Values Sparingly

Only override defaults when necessary:

```hcl
aws_load_balancer_controller = {
  set_values = [
    {
      name  = "replicaCount"
      value = "2"  # High availability
    }
  ]
}
```

## Troubleshooting

### IRSA Not Working

**Symptoms**: Pods can't access AWS services

**Solutions**:

1. Verify OIDC provider exists: `aws eks describe-cluster --name <cluster> --query cluster.identity.oidc.issuer`
2. Check service account annotation: `kubectl describe sa <sa-name> -n <namespace>`
3. Verify IAM role trust policy includes correct OIDC provider

### Helm Release Failed

**Symptoms**: `helm_release` stuck in failed state

**Solutions**:

```bash
# Check Helm release status
helm list -A

# Get release details
helm status <release-name> -n <namespace>

# Delete failed release
helm delete <release-name> -n <namespace>

# Re-apply Terraform
terraform apply
```

### Karpenter Not Provisioning Nodes

**Solutions**:

1. Verify node role ARN/name are correct
2. Check Karpenter logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter`
3. Ensure instance profile exists: `aws iam get-instance-profile --instance-profile-name <name>`

### Karpenter/Dynatrace OCI Chart Pull Rate Limited

**Symptoms**:

```
Error: could not download chart: failed to authorize
429 Too Many Requests
```

**Solution**: ECR Public has rate limits for anonymous pulls. Add authenticated access via the Helm provider. See [ECR Public OCI Authentication](#ecr-public-oci-authentication-optional) for configuration details.

### EBS CSI Driver Installation Failed

**Symptoms**:

```
Error: values don't meet the specifications of the schema(s)
- Additional property awsRegion is not allowed
```

**Solution**: This was fixed in v2.1.0. The `awsRegion` parameter has been removed as the driver auto-detects the region from EC2 metadata. Update to v2.1.0 or later.

### External Secrets Webhook Conflict

**Symptoms**:

```
Error: no endpoints available for service "aws-load-balancer-webhook-service"
```

**Solution**: This was fixed in v2.1.0 by adding proper dependency ordering. External Secrets now waits for AWS Load Balancer Controller webhook to be ready. Update to v2.1.0 or later.

### AWS Load Balancer Controller Not Creating ALBs

**Solutions**:

1. Check controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`
2. Verify VPC has correct tags: `kubernetes.io/cluster/<cluster-name>=owned`
3. Ensure subnets are tagged: `kubernetes.io/role/elb=1` (public) or `kubernetes.io/role/internal-elb=1` (private)

## ECR Public OCI Authentication (Optional)

Karpenter and Dynatrace charts are hosted on ECR Public OCI registries (`oci://public.ecr.aws`). By default, charts are pulled **anonymously** without authentication. This works for most deployments.

### When You Need Authentication

| Scenario                                       | Auth Needed? |
| ---------------------------------------------- | ------------ |
| Standard deployment                            | No           |
| CI/CD with occasional deploys                  | No           |
| High-frequency CI/CD (50+ concurrent deploys)  | Possibly     |
| Private ECR registries                         | Yes (different mechanism) |

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

## Contributing

Contributions welcome! To add a new addon:

1. Create `<number>-<addon-name>.tf` in `helm-addons/`
2. Add variables in `2-variables.tf`
3. Add outputs in `8-outputs.tf`
4. Follow IRSA pattern if AWS access required
5. Update README.md with addon documentation

## License

MIT License - see LICENSE file for details.

## Authors

Maintained by Jhon Meza

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## References

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Karpenter Documentation](https://karpenter.sh/)
- [External DNS Documentation](https://github.com/kubernetes-sigs/external-dns)
- [Cert-Manager Documentation](https://cert-manager.io/)
- [External Secrets Operator Documentation](https://external-secrets.io/)
- [KEDA Documentation](https://keda.sh/)
- [Velero Documentation](https://velero.io/)

---

**Community References**:

- [AWS EKS Blueprints Addons](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons) - Official AWS reference
- [Amazon EKS Best Practices](https://aws.github.io/aws-eks-best-practices/) - AWS official guide
