# =============================================================================
# External Secrets Operator
# =============================================================================
#
# External Secrets Operator synchronizes secrets from AWS Secrets Manager and
# AWS Systems Manager Parameter Store to Kubernetes secrets. This enables
# secure secret management using AWS native services.
#
# Resources created:
# - IAM role with IRSA (IAM Roles for Service Accounts) trust policy
# - IAM policy with permissions for Secrets Manager access
# - Helm release for External Secrets chart
# =============================================================================

data "aws_iam_policy_document" "external_secret_trust_policy" {
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
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name               = "ause1-role-eks-addons-external-secrets-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.external_secret_trust_policy.json

  tags = var.tags_common
}

resource "aws_iam_policy" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name = "ause1-policy-eks-addons-external-secrets-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ExternalSecretsSecretsManagerPermissions"
        Action = [
          # Secrets Manager read permissions
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

  tags = var.tags_common
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name = "external-secrets"

  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_helm_version
  namespace        = "external-secrets"
  create_namespace = true

  set = [
    {
      name  = "serviceAccount.name"
      value = "external-secrets"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_secrets[0].arn
    }
  ]
}
