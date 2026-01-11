# =============================================================================
# KEDA - Kubernetes Event-Driven Autoscaler
# =============================================================================
#
# KEDA enables event-driven autoscaling for Kubernetes workloads.
#
# Resources created:
# - IAM role with IRSA trust policy
# - IAM policy with permissions for Auto Scaling Groups and EC2
# - Helm release for KEDA chart
# =============================================================================

data "aws_iam_policy_document" "keda_operator_trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.keda.namespace}:keda-operator"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "keda" {
  count = var.enable_keda ? 1 : 0

  name               = "${local.name_prefix}-keda-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.keda_operator_trust_policy.json

  tags = local.common_tags
}

resource "aws_iam_policy" "keda" {
  count = var.enable_keda ? 1 : 0

  name = "${local.policy_prefix}-keda-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "KEDAAutoScalingReadPermissions"
        Action = [
          "autoscaling:DescribeAutoscalingGroups",
          "autoscaling:DescribeAutoscalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "KEDAAutoScalingWritePermissions"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "keda" {
  count = var.enable_keda ? 1 : 0

  role       = aws_iam_role.keda[0].name
  policy_arn = aws_iam_policy.keda[0].arn
}

# Local variable for backwards compatibility
locals {
  keda_helm_version = coalesce(var.keda.helm_version, var.keda_helm_version)
}

resource "helm_release" "keda" {
  count = var.enable_keda ? 1 : 0

  name = "keda"

  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = local.keda_helm_version
  namespace        = var.keda.namespace
  create_namespace = var.keda.create_namespace
  timeout          = var.keda.timeout

  set {
    name  = "rbac.serviceAccount.name"
    value = "keda"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.keda[0].arn
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks_name
  }

  dynamic "set" {
    for_each = var.keda.set_values

    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}
