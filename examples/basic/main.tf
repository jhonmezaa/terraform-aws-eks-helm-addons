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
# Basic example: core addons (AWS Load Balancer Controller + Metrics Server)
################################################################################

module "eks_helm_addons" {
  source = "../../helm-addons"

  account_name = var.account_name
  project_name = var.project_name

  eks_name             = var.eks_name
  eks_region           = var.region
  eks_cluster_endpoint = var.eks_cluster_endpoint
  openid_provider_arn  = var.openid_provider_arn

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    vpc_id = var.vpc_id
  }

  enable_metrics_server = true

  tags_common = var.tags_common
}
