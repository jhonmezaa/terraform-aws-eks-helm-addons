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

# =============================================================================
# AWS Load Balancer Controller Outputs
# =============================================================================

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

output "aws_load_balancer_controller_role_name" {
  description = "Name of the IAM role for AWS Load Balancer Controller"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].name : null
}

output "aws_load_balancer_controller_helm_release_name" {
  description = "Name of the AWS Load Balancer Controller Helm release"
  value       = var.enable_aws_load_balancer_controller ? helm_release.aws_load_balancer_controller[0].name : null
}

output "aws_load_balancer_controller_helm_release_version" {
  description = "Version of the AWS Load Balancer Controller Helm release"
  value       = var.enable_aws_load_balancer_controller ? helm_release.aws_load_balancer_controller[0].version : null
}

# =============================================================================
# Metrics Server Outputs
# =============================================================================

output "metrics_server_helm_release_name" {
  description = "Name of the Metrics Server Helm release"
  value       = var.enable_metrics_server ? helm_release.metrics_server[0].name : null
}

output "metrics_server_helm_release_version" {
  description = "Version of the Metrics Server Helm release"
  value       = var.enable_metrics_server ? helm_release.metrics_server[0].version : null
}

# =============================================================================
# External DNS Outputs
# =============================================================================

output "external_dns_role_arn" {
  description = "ARN of the IAM role for External DNS"
  value       = var.enable_external_dns ? aws_iam_role.external_dns[0].arn : null
}

output "external_dns_role_name" {
  description = "Name of the IAM role for External DNS"
  value       = var.enable_external_dns ? aws_iam_role.external_dns[0].name : null
}

output "external_dns_helm_release_name" {
  description = "Name of the External DNS Helm release"
  value       = var.enable_external_dns ? helm_release.external_dns[0].name : null
}

output "external_dns_helm_release_version" {
  description = "Version of the External DNS Helm release"
  value       = var.enable_external_dns ? helm_release.external_dns[0].version : null
}

# =============================================================================
# Cert-Manager Outputs
# =============================================================================

output "cert_manager_helm_release_name" {
  description = "Name of the Cert-Manager Helm release"
  value       = var.enable_cert_manager ? helm_release.cert_manager[0].name : null
}

output "cert_manager_helm_release_version" {
  description = "Version of the Cert-Manager Helm release"
  value       = var.enable_cert_manager ? helm_release.cert_manager[0].version : null
}

# =============================================================================
# AWS for Fluent Bit Outputs
# =============================================================================

output "aws_for_fluent_bit_role_arn" {
  description = "ARN of the IAM role for AWS for Fluent Bit"
  value       = var.enable_aws_for_fluent_bit ? aws_iam_role.aws_for_fluent_bit[0].arn : null
}

output "aws_for_fluent_bit_role_name" {
  description = "Name of the IAM role for AWS for Fluent Bit"
  value       = var.enable_aws_for_fluent_bit ? aws_iam_role.aws_for_fluent_bit[0].name : null
}

output "aws_for_fluent_bit_helm_release_name" {
  description = "Name of the AWS for Fluent Bit Helm release"
  value       = var.enable_aws_for_fluent_bit ? helm_release.aws_for_fluent_bit[0].name : null
}

output "aws_for_fluent_bit_helm_release_version" {
  description = "Version of the AWS for Fluent Bit Helm release"
  value       = var.enable_aws_for_fluent_bit ? helm_release.aws_for_fluent_bit[0].version : null
}

output "aws_for_fluent_bit_log_group_name" {
  description = "Name of the CloudWatch log group (if created by module)"
  value       = var.enable_aws_for_fluent_bit && var.aws_for_fluent_bit.cloudwatch_log_group != null ? var.aws_for_fluent_bit.cloudwatch_log_group : null
}

# =============================================================================
# Velero Outputs
# =============================================================================

output "velero_role_arn" {
  description = "ARN of the IAM role for Velero"
  value       = var.enable_velero ? aws_iam_role.velero[0].arn : null
}

output "velero_role_name" {
  description = "Name of the IAM role for Velero"
  value       = var.enable_velero ? aws_iam_role.velero[0].name : null
}

output "velero_helm_release_name" {
  description = "Name of the Velero Helm release"
  value       = var.enable_velero ? helm_release.velero[0].name : null
}

output "velero_helm_release_version" {
  description = "Version of the Velero Helm release"
  value       = var.enable_velero ? helm_release.velero[0].version : null
}

# =============================================================================
# Vertical Pod Autoscaler Outputs
# =============================================================================

output "vpa_helm_release_name" {
  description = "Name of the VPA Helm release"
  value       = var.enable_vpa ? helm_release.vpa[0].name : null
}

output "vpa_helm_release_version" {
  description = "Version of the VPA Helm release"
  value       = var.enable_vpa ? helm_release.vpa[0].version : null
}

# =============================================================================
# AWS Node Termination Handler Outputs
# =============================================================================

output "aws_node_termination_handler_role_arn" {
  description = "ARN of the IAM role for AWS Node Termination Handler"
  value       = var.enable_aws_node_termination_handler ? aws_iam_role.aws_node_termination_handler[0].arn : null
}

output "aws_node_termination_handler_role_name" {
  description = "Name of the IAM role for AWS Node Termination Handler"
  value       = var.enable_aws_node_termination_handler ? aws_iam_role.aws_node_termination_handler[0].name : null
}

output "aws_node_termination_handler_helm_release_name" {
  description = "Name of the AWS Node Termination Handler Helm release"
  value       = var.enable_aws_node_termination_handler ? helm_release.aws_node_termination_handler[0].name : null
}

output "aws_node_termination_handler_helm_release_version" {
  description = "Version of the AWS Node Termination Handler Helm release"
  value       = var.enable_aws_node_termination_handler ? helm_release.aws_node_termination_handler[0].version : null
}

# =============================================================================
# Ingress Nginx Outputs
# =============================================================================

output "ingress_nginx_helm_release_name" {
  description = "Name of the Ingress Nginx Helm release"
  value       = var.enable_ingress_nginx ? helm_release.ingress_nginx[0].name : null
}

output "ingress_nginx_helm_release_version" {
  description = "Version of the Ingress Nginx Helm release"
  value       = var.enable_ingress_nginx ? helm_release.ingress_nginx[0].version : null
}
