provider "aws" {
  region = var.region
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_name
}

provider "helm" {
  kubernetes = {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

################################################################################
# Complete example: most addons with least-privilege options enabled
################################################################################

module "eks_helm_addons" {
  source = "../../helm-addons"

  account_name = var.account_name
  project_name = var.project_name

  eks_name             = var.eks_name
  eks_region           = var.region
  eks_cluster_endpoint = var.eks_cluster_endpoint
  openid_provider_arn  = var.openid_provider_arn

  node_role_arn  = var.node_role_arn
  node_role_name = var.node_role_name

  # Load balancing / ingress
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    vpc_id = var.vpc_id
    values = [yamlencode({ replicaCount = 2 })]
  }

  # Metrics
  enable_metrics_server = true
  enable_vpa            = true

  # DNS and certificates
  enable_external_dns = true
  external_dns = {
    domain_filters    = ["example.com"]
    route53_zone_arns = var.route53_zone_arns
  }

  enable_cert_manager = true

  # Logging
  enable_aws_for_fluent_bit = true
  aws_for_fluent_bit = {
    cloudwatch_log_group     = "/aws/eks/${var.eks_name}/fluent-bit"
    cloudwatch_log_retention = 30
  }

  # Node autoscaling with interruption handling
  enable_karpenter = true
  karpenter = {
    spotconsolidation       = true
    enable_spot_termination = true
  }

  # Secrets
  enable_external_secrets = true
  external_secrets = {
    secrets_manager_arns = ["arn:aws:secretsmanager:${var.region}:*:secret:${var.project_name}/*"]
    ssm_parameter_arns   = ["arn:aws:ssm:${var.region}:*:parameter/${var.project_name}/*"]
  }

  # Storage
  enable_ebs_csi_driver = true

  # Event-driven autoscaling
  enable_keda = true

  # Backups
  enable_velero = true
  velero = {
    backup_bucket = var.velero_backup_bucket
  }

  tags_common = var.tags_common
}
