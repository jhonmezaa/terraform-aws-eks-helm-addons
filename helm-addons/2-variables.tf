# =============================================================================
# Common Variables
# =============================================================================

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "tags_common" {
  description = "Common tags to apply to all resources"
  type        = map(any)
}

# =============================================================================
# EKS Cluster Configuration
# =============================================================================

variable "eks_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_region" {
  description = "AWS region where the EKS cluster is deployed"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "openid_provider_arn" {
  description = "ARN of the IAM OpenID Connect Provider for IRSA"
  type        = string
}

# =============================================================================
# KEDA - Kubernetes Event-Driven Autoscaler
# =============================================================================

variable "enable_keda" {
  description = "Whether to deploy KEDA for event-driven autoscaling"
  type        = bool
  default     = false
}

variable "keda_helm_version" {
  description = "Version of the KEDA Helm chart"
  type        = string
}

# =============================================================================
# Karpenter - Node Autoscaler
# =============================================================================

variable "enable_karpenter" {
  description = "Whether to deploy Karpenter for node autoscaling"
  type        = bool
  default     = false
}

variable "karpenter_helm_version" {
  description = "Version of the Karpenter Helm chart"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS nodes (used by Karpenter)"
  type        = string
}

variable "node_role_name" {
  description = "Name of the IAM role for EKS nodes (used by Karpenter)"
  type        = string
}

variable "spotconsolidation" {
  description = "Enable spot-to-spot consolidation for cost optimization"
  type        = bool
  default     = false
}

# =============================================================================
# External Secrets Operator
# =============================================================================

variable "enable_external_secrets" {
  description = "Whether to deploy External Secrets Operator"
  type        = bool
  default     = false
}

variable "external_secrets_helm_version" {
  description = "Version of the External Secrets Helm chart"
  type        = string
}

# =============================================================================
# AWS EBS CSI Driver
# =============================================================================

variable "enable_ebs_csi_driver" {
  description = "Whether to deploy the AWS EBS CSI Driver for persistent volumes"
  type        = bool
  default     = false
}

variable "ebs_csi_driver_helm_version" {
  description = "Version of the AWS EBS CSI Driver Helm chart"
  type        = string
}

# =============================================================================
# Cluster Autoscaler (Deprecated - use Karpenter instead)
# =============================================================================

variable "enable_cluster_autoscaler" {
  description = "Whether to deploy Cluster Autoscaler (deprecated in favor of Karpenter)"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_helm_version" {
  description = "Version of the Cluster Autoscaler Helm chart"
  type        = string
  default     = "9.43.2"
}
