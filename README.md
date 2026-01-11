# Terraform AWS EKS Helm Addons

Production-ready Terraform module for deploying Kubernetes Helm-based addons on Amazon EKS clusters with IAM Roles for Service Accounts (IRSA) integration.

## Features

### Comprehensive Addon Support (13 addons)

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

**Deprecated**:
- ⚠️ Cluster Autoscaler - Use Karpenter instead

### Advanced Features

- **IRSA Integration**: All addons use IAM Roles for Service Accounts for secure AWS API access
- **Flexible Configuration**: Per-addon object configuration with helm values, timeouts, namespaces
- **Dynamic Region Support**: Automatic region prefix detection for multi-region deployments
- **Backwards Compatible**: Legacy variable support with deprecation warnings
- **Dependency Management**: Smart addon ordering and dependencies
- **Custom Helm Values**: Support for custom configuration via `set_values`

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | ~> 6.0 |
| helm | ~> 2.0 |
| kubernetes | ~> 2.0 |

## Usage

### Basic Example

```hcl
module "eks_helm_addons" {
  source = "github.com/your-org/terraform-aws-eks-helm-addons//helm-addons"

  account_name = "prod"
  project_name = "myapp"

  eks_name             = module.eks.cluster_name
  eks_region           = "us-east-1"
  eks_cluster_endpoint = module.eks.cluster_endpoint
  openid_provider_arn  = module.eks.oidc_provider_arn

  # Critical addons
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  enable_karpenter                    = true

  # Karpenter requires node role
  node_role_arn  = module.eks.node_iam_role_arn
  node_role_name = module.eks.node_iam_role_name

  tags_common = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Complete Example with Custom Configuration

```hcl
module "eks_helm_addons" {
  source = "./helm-addons"

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
    helm_version   = "1.13.1"
    domain_filters = ["example.com", "example.org"]
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
    helm_version      = "v0.33.0"
    spotconsolidation = true
  }

  # External Secrets
  enable_external_secrets = true

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
    ManagedBy   = "terraform"
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
  helm_version   = "1.13.1"
  domain_filters = ["example.com"]
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
  cloudwatch_log_group     = "/aws/eks/cluster/logs"
  cloudwatch_log_retention = 7  # Days
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
  helm_version      = "v0.33.0"
  spotconsolidation = true
}

# Required: node role ARN and name
node_role_arn  = module.eks.node_iam_role_arn
node_role_name = module.eks.node_iam_role_name
```

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
  helm_version = "0.9.9"
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

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `account_name` | Account name for resource naming | `string` |
| `project_name` | Project name for resource naming | `string` |
| `eks_name` | EKS cluster name | `string` |
| `eks_region` | AWS region | `string` |
| `eks_cluster_endpoint` | EKS API endpoint | `string` |
| `openid_provider_arn` | OIDC provider ARN for IRSA | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `region_prefix` | Region prefix (auto-detected if null) | `string` | `null` |
| `tags_common` | Common tags for all resources | `map(any)` | `{}` |
| `node_role_arn` | Node IAM role ARN (for Karpenter) | `string` | `null` |
| `node_role_name` | Node IAM role name (for Karpenter) | `string` | `null` |

### Addon Configuration Pattern

Each addon follows this configuration pattern:

```hcl
variable "addon_name" {
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "default-namespace")
    create_namespace = optional(bool, true)
    timeout          = optional(number, 300)
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

Each addon provides consistent outputs:

| Output Pattern | Description |
|----------------|-------------|
| `{addon}_role_arn` | IAM role ARN for IRSA |
| `{addon}_role_name` | IAM role name |
| `{addon}_helm_release_name` | Helm release name |
| `{addon}_helm_release_version` | Deployed Helm chart version |

**Example outputs**:
```hcl
output "karpenter_role_arn" {
  value = module.eks_helm_addons.karpenter_role_arn
}

output "aws_load_balancer_controller_version" {
  value = module.eks_helm_addons.aws_load_balancer_controller_helm_release_version
}
```

## Architecture

### Resource Naming Convention

All resources follow a standardized naming pattern:

```
{region_prefix}-{resource-type}-eks-addons-{addon}-{account_name}-{project_name}
```

**Examples**:
- IAM Role: `ause1-role-eks-addons-karpenter-prod-myapp`
- IAM Policy: `ause1-policy-eks-addons-external-dns-prod-myapp`
- Instance Profile: `ause1-instance-profile-eks-karpenter-prod-myapp`

### Region Prefix Mapping

Auto-detected from current AWS region:
- `us-east-1` → `ause1`
- `us-west-2` → `usw2`
- `eu-west-1` → `euw1`
- `ap-southeast-1` → `apse1`

Override with `region_prefix` variable if needed.

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

### AWS Load Balancer Controller Not Creating ALBs

**Solutions**:
1. Check controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`
2. Verify VPC has correct tags: `kubernetes.io/cluster/<cluster-name>=owned`
3. Ensure subnets are tagged: `kubernetes.io/role/elb=1` (public) or `kubernetes.io/role/internal-elb=1` (private)

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
