data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json
  name               = "ause1-role-eks-addons-karpenter-${var.account_name}-${var.project_name}"

  tags = var.tags_common
}

resource "aws_iam_policy" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  name = "ause1-policy-eks-addons-karpenter-controller-${var.account_name}-${var.project_name}"

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

  tags = var.tags_common
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_controller[0].name
  policy_arn = aws_iam_policy.karpenter_controller[0].arn
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "ause1-instance-profile-eks-karpenter-${var.account_name}-${var.project_name}"
  role = var.node_role_name

  tags = var.tags_common

}

resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "karpenter"

  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  namespace           = "kube-system"
  version             = var.karpenter_helm_version
  create_namespace    = true

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.karpenter_controller[0].arn
    },
    {
      name  = "settings.clusterName"
      value = var.eks_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = var.eks_cluster_endpoint
    },
    {
      name  = "settings.featureGates.spotToSpotConsolidation"
      value = var.spotconsolidation
    },
    {
      name  = "aws.defaultInstanceProfile"
      value = aws_iam_instance_profile.karpenter[0].name
    }
  ]
}
