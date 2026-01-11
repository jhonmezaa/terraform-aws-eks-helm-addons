################################################################################
# External DNS
################################################################################
#
# External DNS synchronizes exposed Kubernetes Services and Ingresses with DNS providers.
# For AWS, it creates Route53 records based on annotations in Kubernetes resources.
#
# Features:
# - Automatic Route53 record creation/deletion
# - Support for multiple hosted zones
# - Domain filtering
# - TXT record ownership tracking
#
# Resources created:
# - IAM role with IRSA trust policy
# - IAM policy for Route53 access
# - Helm release for External DNS
################################################################################

data "aws_iam_policy_document" "external_dns_trust_policy" {
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
      values   = ["system:serviceaccount:${var.external_dns.namespace}:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name               = "${local.name_prefix}-external-dns-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.external_dns_trust_policy.json

  tags = local.common_tags
}

resource "aws_iam_policy" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name = "${local.policy_prefix}-external-dns-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ExternalDNSRoute53ReadPermissions"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "ExternalDNSRoute53WritePermissions"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:route53:::hostedzone/*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  role       = aws_iam_role.external_dns[0].name
  policy_arn = aws_iam_policy.external_dns[0].arn
}

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name = "external-dns"

  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.external_dns.helm_version
  namespace        = var.external_dns.namespace
  create_namespace = var.external_dns.create_namespace
  timeout          = var.external_dns.timeout

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns[0].arn
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  dynamic "set" {
    for_each = var.external_dns.domain_filters

    content {
      name  = "domainFilters[${set.key}]"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.external_dns.set_values

    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}
