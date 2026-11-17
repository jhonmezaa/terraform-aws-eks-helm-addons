output "aws_load_balancer_controller_role_arn" {
  description = "IRSA role ARN of the AWS Load Balancer Controller"
  value       = module.eks_helm_addons.aws_load_balancer_controller_role_arn
}

output "aws_load_balancer_controller_role_name" {
  description = "IRSA role name of the AWS Load Balancer Controller"
  value       = module.eks_helm_addons.aws_load_balancer_controller_role_name
}

output "metrics_server_helm_release_name" {
  description = "Helm release name of Metrics Server"
  value       = module.eks_helm_addons.metrics_server_helm_release_name
}
