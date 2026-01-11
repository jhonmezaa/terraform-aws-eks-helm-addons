################################################################################
# AWS Node Termination Handler
################################################################################
#
# AWS Node Termination Handler ensures that Kubernetes control plane responds appropriately to events
# that can cause EC2 instance to become unavailable, such as EC2 maintenance events, EC2 Spot interruptions,
# ASG scale-in events, and EC2 instance rebalance recommendations.
#
# Features:
# - Gracefully drain nodes before termination
# - Handle EC2 Spot interruptions
# - Handle scheduled maintenance events
# - ASG lifecycle hook integration
#
# Resources created:
# - IAM role with IRSA trust policy
# - IAM policy for SQS and ASG access
# - Helm release for Node Termination Handler
################################################################################

data "aws_iam_policy_document" "aws_node_termination_handler_trust_policy" {
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
      values   = ["system:serviceaccount:${var.aws_node_termination_handler.namespace}:aws-node-termination-handler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_node_termination_handler" {
  count = var.enable_aws_node_termination_handler ? 1 : 0

  name               = "${local.name_prefix}-node-termination-handler-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.aws_node_termination_handler_trust_policy.json

  tags = local.common_tags
}

resource "aws_iam_policy" "aws_node_termination_handler" {
  count = var.enable_aws_node_termination_handler ? 1 : 0

  name = "${local.policy_prefix}-node-termination-handler-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NodeTerminationHandlerASGPermissions"
        Effect = "Allow"
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "NodeTerminationHandlerSQSPermissions"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_node_termination_handler" {
  count = var.enable_aws_node_termination_handler ? 1 : 0

  role       = aws_iam_role.aws_node_termination_handler[0].name
  policy_arn = aws_iam_policy.aws_node_termination_handler[0].arn
}

resource "helm_release" "aws_node_termination_handler" {
  count = var.enable_aws_node_termination_handler ? 1 : 0

  name = "aws-node-termination-handler"

  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-node-termination-handler"
  version          = var.aws_node_termination_handler.helm_version
  namespace        = var.aws_node_termination_handler.namespace
  create_namespace = var.aws_node_termination_handler.create_namespace
  timeout          = var.aws_node_termination_handler.timeout

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-node-termination-handler"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_node_termination_handler[0].arn
  }

  set {
    name  = "enableSpotInterruptionDraining"
    value = var.aws_node_termination_handler.enable_spot_interruption_draining
  }

  set {
    name  = "enableScheduledEventDraining"
    value = var.aws_node_termination_handler.enable_scheduled_event_draining
  }

  dynamic "set" {
    for_each = var.aws_node_termination_handler.set_values

    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}
