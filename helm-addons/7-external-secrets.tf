# =============================================================================
# External Secrets Operator
# =============================================================================
#
# External Secrets Operator synchronizes secrets from AWS Secrets Manager and
# AWS Systems Manager Parameter Store to Kubernetes secrets.
#
# Resources created:
# - IAM role with IRSA trust policy
# - IAM policy with permissions for Secrets Manager access
# - Helm release for External Secrets chart
# =============================================================================

data "aws_iam_policy_document" "external_secret_trust_policy" {
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
      values   = ["system:serviceaccount:${var.external_secrets.namespace}:external-secrets"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name               = "${local.name_prefix}-external-secrets-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.external_secret_trust_policy.json

  tags = local.common_tags
}

resource "aws_iam_policy" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name = "${local.policy_prefix}-external-secrets-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ExternalSecretsSecretsManagerPermissions"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:BatchGetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}

# Local variable for backwards compatibility
locals {
  external_secrets_helm_version = coalesce(var.external_secrets.helm_version, var.external_secrets_helm_version)
}

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name = "external-secrets"

  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = local.external_secrets_helm_version
  namespace        = var.external_secrets.namespace
  create_namespace = var.external_secrets.create_namespace
  timeout          = var.external_secrets.timeout

  # Wait for AWS Load Balancer Controller to be ready to avoid webhook conflicts
  # NOTE: This dependency is only relevant when both addons are enabled.
  # External Secrets does NOT require the Load Balancer Controller to function.
  # This prevents webhook conflicts during simultaneous first-time installation.
  depends_on = [
    helm_release.aws_load_balancer_controller
  ]

  set = concat(
    [
      {
        name  = "serviceAccount.name"
        value = "external-secrets"
      },
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = aws_iam_role.external_secrets[0].arn
      }
    ],
    var.external_secrets.set_values
  )
}
