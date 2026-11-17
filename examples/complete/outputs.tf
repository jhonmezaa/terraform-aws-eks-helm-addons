output "karpenter_role_arn" {
  description = "IRSA role ARN of the Karpenter controller"
  value       = module.eks_helm_addons.karpenter_role_arn
}

output "karpenter_instance_profile_name" {
  description = "Instance profile used by Karpenter nodes"
  value       = module.eks_helm_addons.karpenter_instance_profile_name
}

output "karpenter_interruption_queue_name" {
  description = "SQS interruption queue used by Karpenter"
  value       = module.eks_helm_addons.karpenter_interruption_queue_name
}

output "external_dns_role_arn" {
  description = "IRSA role ARN of External DNS"
  value       = module.eks_helm_addons.external_dns_role_arn
}

output "external_secrets_role_arn" {
  description = "IRSA role ARN of External Secrets"
  value       = module.eks_helm_addons.external_secrets_role_arn
}

output "keda_role_arn" {
  description = "IRSA role ARN of KEDA"
  value       = module.eks_helm_addons.keda_role_arn
}

output "velero_role_arn" {
  description = "IRSA role ARN of Velero"
  value       = module.eks_helm_addons.velero_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "IRSA role ARN of the EBS CSI driver"
  value       = module.eks_helm_addons.ebs_csi_driver_role_arn
}
