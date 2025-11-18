# =============================================================================
# KEDA - Kubernetes Event-Driven Autoscaler
# =============================================================================
#
# KEDA enables event-driven autoscaling for Kubernetes workloads, particularly
# for Azure DevOps agent pools that scale based on pipeline queue depth.
#
# Resources created:
# - IAM role with IRSA (IAM Roles for Service Accounts) trust policy
# - IAM policy with permissions for Auto Scaling Groups and EC2
# - Helm release for KEDA chart
# =============================================================================

data "aws_iam_policy_document" "keda_operator_trust_policy" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:keda:keda-operator"]
    }
  }
}

resource "aws_iam_role" "keda" {
  count = var.enable_keda ? 1 : 0

  name               = "ause1-role-eks-addons-keda-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.keda_operator_trust_policy.json

  tags = var.tags_common
}

resource "aws_iam_policy" "keda" {
  count = var.enable_keda ? 1 : 0

  name = "ause1-policy-eks-addons-keda-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "KEDAAutoScalingReadPermissions"
        Action = [
          # Auto Scaling Groups permissions
          "autoscaling:DescribeAutoscalingGroups",
          "autoscaling:DescribeAutoscalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          # EC2 permissions for instance types and launch templates
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "KEDAAutoScalingWritePermissions"
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

  tags = var.tags_common
}

resource "aws_iam_role_policy_attachment" "keda" {
  count = var.enable_keda ? 1 : 0

  role       = aws_iam_role.keda[0].name
  policy_arn = aws_iam_policy.keda[0].arn
}

resource "helm_release" "keda" {
  count = var.enable_keda ? 1 : 0

  name = "keda"

  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = var.keda_helm_version
  namespace        = "keda"
  create_namespace = true

  set = [
    {
      name  = "rbac.serviceAccount.name"
      value = "keda"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.keda[0].arn
    },
    {
      name  = "autoDiscovery.clusterName"
      value = var.eks_name
    }
  ]
}
