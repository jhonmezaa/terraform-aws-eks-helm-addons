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

  name               = substr("${local.role_prefix}-karpenter-${local.name_suffix}", 0, 64)
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json

  tags = merge(local.common_tags, { Name = substr("${local.role_prefix}-karpenter-${local.name_suffix}", 0, 64) })
}

resource "aws_iam_policy" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  name = "${local.policy_prefix}-karpenter-controller-${local.name_suffix}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
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
          "ec2:DescribeAvailabilityZones",
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
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },
      {
        # Scoped to the node role when node_role_arn is provided
        Sid      = "KarpenterPassNodeRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = var.node_role_arn != null ? var.node_role_arn : "*"
      },
      ],
      local.karpenter_enable_spot_termination ? [
        {
          Sid    = "KarpenterInterruptionQueue"
          Effect = "Allow"
          Action = [
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:ReceiveMessage"
          ]
          Resource = aws_sqs_queue.karpenter[0].arn
        },
      ] : []
    )
  })

  tags = merge(local.common_tags, { Name = "${local.policy_prefix}-karpenter-controller-${local.name_suffix}" })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_controller[0].name
  policy_arn = aws_iam_policy.karpenter_controller[0].arn
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "${local.instance_profile_prefix}-karpenter-${local.name_suffix}"
  role = var.node_role_name

  lifecycle {
    precondition {
      condition     = var.node_role_name != null
      error_message = "node_role_name es obligatorio cuando enable_karpenter = true (rol IAM de los nodos para el instance profile)."
    }
  }

  tags = merge(local.common_tags, { Name = "${local.instance_profile_prefix}-karpenter-${local.name_suffix}" })
}

# Local variables for backwards compatibility
locals {
  karpenter_helm_version = try(coalesce(var.karpenter.helm_version, var.karpenter_helm_version), null)
  # Either the new (karpenter.spotconsolidation) or the deprecated
  # (spotconsolidation) input enables the feature gate. coalesce() was used
  # before, which ignored the deprecated input because false is not null.
  karpenter_spotconsolidation = var.karpenter.spotconsolidation || var.spotconsolidation

  karpenter_enable_spot_termination = var.enable_karpenter && var.karpenter.enable_spot_termination

  karpenter_sqs_name = substr("${local.sqs_prefix}-karpenter-${local.name_suffix}", 0, 80)

  # EC2/Health events forwarded to the Karpenter interruption queue
  karpenter_ec2_events = {
    health_event = {
      name        = "health"
      description = "Karpenter interruption - AWS health event"
      event_pattern = {
        source      = ["aws.health"]
        detail-type = ["AWS Health Event"]
      }
    }
    spot_interrupt = {
      name        = "spot"
      description = "Karpenter interruption - EC2 spot instance interruption warning"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Spot Instance Interruption Warning"]
      }
    }
    instance_rebalance = {
      name        = "rebalance"
      description = "Karpenter interruption - EC2 instance rebalance recommendation"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance Rebalance Recommendation"]
      }
    }
    instance_state_change = {
      name        = "state"
      description = "Karpenter interruption - EC2 instance state-change notification"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance State-change Notification"]
      }
    }
  }
}

################################################################################
# Karpenter interruption handling (opt-in: karpenter.enable_spot_termination)
################################################################################

resource "aws_sqs_queue" "karpenter" {
  count = local.karpenter_enable_spot_termination ? 1 : 0

  name                      = local.karpenter_sqs_name
  message_retention_seconds = var.karpenter.sqs_message_retention_seconds
  sqs_managed_sse_enabled   = var.karpenter.sqs_kms_master_key_id == null ? true : null
  kms_master_key_id         = var.karpenter.sqs_kms_master_key_id

  tags = merge(local.common_tags, { Name = local.karpenter_sqs_name })
}

data "aws_iam_policy_document" "karpenter_sqs" {
  count = local.karpenter_enable_spot_termination ? 1 : 0

  statement {
    sid       = "SendEventsToQueue"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter[0].arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
  }

  statement {
    sid       = "DenyHTTP"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.karpenter[0].arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "karpenter" {
  count = local.karpenter_enable_spot_termination ? 1 : 0

  queue_url = aws_sqs_queue.karpenter[0].url
  policy    = data.aws_iam_policy_document.karpenter_sqs[0].json
}

resource "aws_cloudwatch_event_rule" "karpenter" {
  for_each = { for k, v in local.karpenter_ec2_events : k => v if local.karpenter_enable_spot_termination }

  name          = substr("${local.event_rule_prefix}-karpenter-${each.value.name}-${local.name_suffix}", 0, 64)
  description   = each.value.description
  event_pattern = jsonencode(each.value.event_pattern)

  tags = merge(
    local.common_tags,
    {
      Name        = substr("${local.event_rule_prefix}-karpenter-${each.value.name}-${local.name_suffix}", 0, 64)
      ClusterName = var.eks_name
    }
  )
}

resource "aws_cloudwatch_event_target" "karpenter" {
  for_each = { for k, v in local.karpenter_ec2_events : k => v if local.karpenter_enable_spot_termination }

  rule      = aws_cloudwatch_event_rule.karpenter[each.key].name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter[0].arn
}

resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "karpenter"

  # OCI registry from ECR Public - anonymous pull (no auth required).
  # For high-frequency CI/CD pipelines that hit ECR Public rate limits,
  # configure registries = [{ url = "oci://public.ecr.aws", ... }] in
  # the helm provider block using an ephemeral aws_ecrpublic_authorization_token.
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  namespace        = var.karpenter.namespace
  version          = local.karpenter_helm_version
  create_namespace = var.karpenter.create_namespace
  timeout          = var.karpenter.timeout

  values = var.karpenter.values

  set = concat(
    [
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
        value = tostring(local.karpenter_spotconsolidation)
      },
    ],
    local.karpenter_enable_spot_termination ? [
      {
        name  = "settings.interruptionQueue"
        value = aws_sqs_queue.karpenter[0].name
      },
    ] : [],
    var.karpenter.set_values
  )
}
