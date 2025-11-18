# =============================================================================
# KEDA Outputs
# =============================================================================

output "keda_role_arn" {
  description = "ARN of the IAM role for KEDA"
  value       = var.enable_keda ? aws_iam_role.keda[0].arn : null
}

output "keda_role_name" {
  description = "Name of the IAM role for KEDA"
  value       = var.enable_keda ? aws_iam_role.keda[0].name : null
}

output "keda_helm_release_name" {
  description = "Name of the KEDA Helm release"
  value       = var.enable_keda ? helm_release.keda[0].name : null
}

output "keda_helm_release_version" {
  description = "Version of the KEDA Helm release"
  value       = var.enable_keda ? helm_release.keda[0].version : null
}

# =============================================================================
# Karpenter Outputs
# =============================================================================

output "karpenter_role_arn" {
  description = "ARN of the IAM role for Karpenter controller"
  value       = var.enable_karpenter ? aws_iam_role.karpenter_controller[0].arn : null
}

output "karpenter_role_name" {
  description = "Name of the IAM role for Karpenter controller"
  value       = var.enable_karpenter ? aws_iam_role.karpenter_controller[0].name : null
}

output "karpenter_instance_profile_name" {
  description = "Name of the instance profile for Karpenter"
  value       = var.enable_karpenter ? aws_iam_instance_profile.karpenter[0].name : null
}

output "karpenter_helm_release_name" {
  description = "Name of the Karpenter Helm release"
  value       = var.enable_karpenter ? helm_release.karpenter[0].name : null
}

output "karpenter_helm_release_version" {
  description = "Version of the Karpenter Helm release"
  value       = var.enable_karpenter ? helm_release.karpenter[0].version : null
}

# =============================================================================
# External Secrets Outputs
# =============================================================================

output "external_secrets_role_arn" {
  description = "ARN of the IAM role for External Secrets"
  value       = var.enable_external_secrets ? aws_iam_role.external_secrets[0].arn : null
}

output "external_secrets_role_name" {
  description = "Name of the IAM role for External Secrets"
  value       = var.enable_external_secrets ? aws_iam_role.external_secrets[0].name : null
}

output "external_secrets_helm_release_name" {
  description = "Name of the External Secrets Helm release"
  value       = var.enable_external_secrets ? helm_release.external_secrets[0].name : null
}

output "external_secrets_helm_release_version" {
  description = "Version of the External Secrets Helm release"
  value       = var.enable_external_secrets ? helm_release.external_secrets[0].version : null
}

# =============================================================================
# EBS CSI Driver Outputs
# =============================================================================

output "ebs_csi_driver_role_arn" {
  description = "ARN of the IAM role for EBS CSI Driver"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.csi_ebs_driver[0].arn : null
}

output "ebs_csi_driver_role_name" {
  description = "Name of the IAM role for EBS CSI Driver"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.csi_ebs_driver[0].name : null
}

output "ebs_csi_driver_helm_release_name" {
  description = "Name of the EBS CSI Driver Helm release"
  value       = var.enable_ebs_csi_driver ? helm_release.csi_ebs_driver[0].name : null
}

output "ebs_csi_driver_helm_release_version" {
  description = "Version of the EBS CSI Driver Helm release"
  value       = var.enable_ebs_csi_driver ? helm_release.csi_ebs_driver[0].version : null
}

# =============================================================================
# Cluster Autoscaler Outputs (Deprecated)
# =============================================================================

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IAM role for Cluster Autoscaler (deprecated)"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "cluster_autoscaler_role_name" {
  description = "Name of the IAM role for Cluster Autoscaler (deprecated)"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].name : null
}

output "cluster_autoscaler_helm_release_name" {
  description = "Name of the Cluster Autoscaler Helm release (deprecated)"
  value       = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].name : null
}

output "cluster_autoscaler_helm_release_version" {
  description = "Version of the Cluster Autoscaler Helm release (deprecated)"
  value       = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].version : null
}
