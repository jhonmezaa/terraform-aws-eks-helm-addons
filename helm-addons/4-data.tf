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

# ECR Public authorization token is now fetched in the parent module
# and passed via variables: var.ecr_public_token_username and var.ecr_public_token_password
# This avoids credential expiration issues with Terraform state

# Current AWS partition (aws, aws-cn, aws-us-gov)
# Used for constructing ARNs in a partition-agnostic way
data "aws_partition" "current" {}

# Current AWS region
# Used for region-specific configurations
data "aws_region" "current" {}

# Current AWS account identity
# Provides account ID and other caller identity information
data "aws_caller_identity" "current" {}
