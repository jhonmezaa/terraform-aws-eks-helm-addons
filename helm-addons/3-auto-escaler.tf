# =============================================================================
# Cluster Autoscaler (DEPRECATED)
# =============================================================================
#
# NOTE: Cluster Autoscaler is deprecated in favor of Karpenter. Use Karpenter
# for new deployments as it provides better cost optimization and faster scaling.
#
# Cluster Autoscaler automatically adjusts the size of the Kubernetes cluster
# when there are pods that fail to run due to insufficient resources.
#
# Resources created:
# - IAM role with IRSA (IAM Roles for Service Accounts) trust policy
# - IAM policy with permissions for Auto Scaling Groups and EC2
# - Helm release for Cluster Autoscaler chart
# =============================================================================

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler.json
  name               = substr("${local.role_prefix}-autoscaler-${local.name_suffix}", 0, 64)
  tags               = merge(local.common_tags, { Name = substr("${local.role_prefix}-autoscaler-${local.name_suffix}", 0, 64) })
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name = "${local.policy_prefix}-autoscaler-${local.name_suffix}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ClusterAutoscalerReadPermissions"
        Action = [
          # Auto Scaling Groups permissions
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          # EC2 permissions
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          # EKS permissions
          "eks:Describe*",
          "eks:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "ClusterAutoscalerWritePermissions"
        Action = [
          # Permissions to scale Auto Scaling Groups
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = merge(local.common_tags, { Name = "${local.policy_prefix}-autoscaler-${local.name_suffix}" })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.cluster_autoscaler_helm_version

  set = [
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.cluster_autoscaler[0].arn
    },
    {
      name  = "autoDiscovery.clusterName"
      value = var.eks_name
    },
    {
      name  = "awsRegion"
      value = var.eks_region
    },
  ]
}
