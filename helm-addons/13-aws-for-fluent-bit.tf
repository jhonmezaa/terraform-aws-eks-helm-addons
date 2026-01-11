################################################################################
# AWS for Fluent Bit
################################################################################
#
# AWS for Fluent Bit is a Fluent Bit image optimized for sending logs to AWS services
# including CloudWatch Logs, Kinesis Data Firehose, and Kinesis Data Streams.
#
# Features:
# - Lightweight log forwarder (uses less resources than Fluentd)
# - Send logs to CloudWatch Logs
# - Optimized for EKS and AWS infrastructure
# - Filter and transform logs before sending
#
# Resources created:
# - IAM role with IRSA trust policy
# - IAM policy for CloudWatch Logs access
# - CloudWatch Log Group (if specified)
# - Helm release for AWS for Fluent Bit
################################################################################

data "aws_iam_policy_document" "aws_for_fluent_bit_trust_policy" {
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
      values   = ["system:serviceaccount:${var.aws_for_fluent_bit.namespace}:aws-for-fluent-bit"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_for_fluent_bit" {
  count = var.enable_aws_for_fluent_bit ? 1 : 0

  name               = "${local.name_prefix}-aws-fluent-bit-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.aws_for_fluent_bit_trust_policy.json

  tags = local.common_tags
}

resource "aws_iam_policy" "aws_for_fluent_bit" {
  count = var.enable_aws_for_fluent_bit ? 1 : 0

  name = "${local.policy_prefix}-aws-fluent-bit-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FluentBitCloudWatchLogsPermissions"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_for_fluent_bit" {
  count = var.enable_aws_for_fluent_bit ? 1 : 0

  role       = aws_iam_role.aws_for_fluent_bit[0].name
  policy_arn = aws_iam_policy.aws_for_fluent_bit[0].arn
}

# Optional CloudWatch Log Group
resource "aws_cloudwatch_log_group" "fluent_bit" {
  count = var.enable_aws_for_fluent_bit && var.aws_for_fluent_bit.cloudwatch_log_group != null ? 1 : 0

  name              = var.aws_for_fluent_bit.cloudwatch_log_group
  retention_in_days = var.aws_for_fluent_bit.cloudwatch_log_retention

  tags = local.common_tags
}

resource "helm_release" "aws_for_fluent_bit" {
  count = var.enable_aws_for_fluent_bit ? 1 : 0

  name = "aws-for-fluent-bit"

  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-for-fluent-bit"
  version          = var.aws_for_fluent_bit.helm_version
  namespace        = var.aws_for_fluent_bit.namespace
  create_namespace = var.aws_for_fluent_bit.create_namespace
  timeout          = var.aws_for_fluent_bit.timeout

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-for-fluent-bit"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_for_fluent_bit[0].arn
  }

  set {
    name  = "cloudWatchLogs.region"
    value = data.aws_region.current.id
  }

  dynamic "set" {
    for_each = var.aws_for_fluent_bit.cloudwatch_log_group != null ? [1] : []

    content {
      name  = "cloudWatchLogs.logGroupName"
      value = var.aws_for_fluent_bit.cloudwatch_log_group
    }
  }

  dynamic "set" {
    for_each = var.aws_for_fluent_bit.set_values

    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.fluent_bit
  ]
}
