data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
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
      values   = ["system:serviceaccount:${var.karpenter.namespace}:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  name               = "${local.name_prefix}-karpenter-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json

  tags = local.common_tags
}

resource "aws_iam_policy" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  name = "${local.policy_prefix}-karpenter-controller-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KarpenterControllerPolicy"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
          "ssm:GetParameter",
          "pricing:GetProducts",
          "iam:PassRole",
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "eks:DescribeCluster"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_controller[0].name
  policy_arn = aws_iam_policy.karpenter_controller[0].arn
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "${local.instance_profile_prefix}-karpenter-${var.account_name}-${var.project_name}"
  role = var.node_role_name

  tags = local.common_tags
}

# Local variables for backwards compatibility
locals {
  karpenter_helm_version = coalesce(var.karpenter.helm_version, var.karpenter_helm_version)
  karpenter_spotconsolidation = coalesce(var.karpenter.spotconsolidation, var.spotconsolidation)
}

resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "karpenter"

  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  namespace           = var.karpenter.namespace
  version             = local.karpenter_helm_version
  create_namespace    = var.karpenter.create_namespace
  timeout             = var.karpenter.timeout

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller[0].arn
  }

  set {
    name  = "settings.clusterName"
    value = var.eks_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = var.eks_cluster_endpoint
  }

  set {
    name  = "settings.featureGates.spotToSpotConsolidation"
    value = local.karpenter_spotconsolidation
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter[0].name
  }

  dynamic "set" {
    for_each = var.karpenter.set_values

    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}
