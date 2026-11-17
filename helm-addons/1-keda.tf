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

  name               = substr("${local.role_prefix}-keda-${local.name_suffix}", 0, 64)
  assume_role_policy = data.aws_iam_policy_document.keda_operator_trust_policy.json

  tags = merge(local.common_tags, { Name = substr("${local.role_prefix}-keda-${local.name_suffix}", 0, 64) })
}

resource "aws_iam_policy" "keda" {
  count = var.enable_keda ? 1 : 0

  name = "${local.policy_prefix}-keda-${local.name_suffix}"

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

  tags = merge(local.common_tags, { Name = "${local.policy_prefix}-keda-${local.name_suffix}" })
}

resource "aws_iam_role_policy_attachment" "keda" {
  count = var.enable_keda ? 1 : 0

  role       = aws_iam_role.keda[0].name
  policy_arn = aws_iam_policy.keda[0].arn
}

# Local variable for backwards compatibility
locals {
  keda_helm_version = try(coalesce(var.keda.helm_version, var.keda_helm_version), null)
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

  values = var.keda.values

  # IRSA for the keda-operator service account (the one trusted by the IAM role).
  # podIdentity.aws.irsa.* annotates the operator service account with the role
  # ARN and is supported by every KEDA chart since 2.7.
  set = concat(
    [
      {
        name  = "podIdentity.aws.irsa.enabled"
        value = "true"
      },
      {
        name  = "podIdentity.aws.irsa.roleArn"
        value = aws_iam_role.keda[0].arn
      },
    ],
    var.keda.set_values
  )
}
