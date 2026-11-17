variable "region" {
  description = "AWS region where the EKS cluster runs"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name used in resource names"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used in resource names"
  type        = string
  default     = "myapp"
}

variable "eks_name" {
  description = "Name of an existing EKS cluster"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "API endpoint of the EKS cluster"
  type        = string
}

variable "eks_cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  type        = string
}

variable "openid_provider_arn" {
  description = "ARN of the cluster IAM OIDC provider (IRSA)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID of the cluster (passed to the AWS Load Balancer Controller)"
  type        = string
}

variable "tags_common" {
  description = "Common tags"
  type        = map(string)
  default = {
    Environment = "prod"
  }
}

variable "node_role_arn" {
  description = "ARN of the IAM role used by the Karpenter nodes"
  type        = string
}

variable "node_role_name" {
  description = "Name of the IAM role used by the Karpenter nodes"
  type        = string
}

variable "route53_zone_arns" {
  description = "Route53 hosted zone ARNs managed by External DNS"
  type        = list(string)
  default     = []
}

variable "velero_backup_bucket" {
  description = "Existing S3 bucket for Velero backups"
  type        = string
}
