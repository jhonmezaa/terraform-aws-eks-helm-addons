################################################################################
# Velero - Backup and Disaster Recovery
################################################################################
#
# Velero is a tool to backup and restore Kubernetes cluster resources and persistent volumes.
#
# Features:
# - Backup and restore cluster resources
# - Schedule automatic backups
# - Disaster recovery
# - Cluster migration
# - Uses S3 for backup storage
#
# Resources created:
# - IAM role with IRSA trust policy
# - IAM policy for S3 bucket access
# - Helm release for Velero
################################################################################

data "aws_iam_policy_document" "velero_trust_policy" {
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
      values   = ["system:serviceaccount:${var.velero.namespace}:velero"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "velero" {
  count = var.enable_velero ? 1 : 0

  name               = "${local.name_prefix}-velero-${var.account_name}-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.velero_trust_policy.json

  tags = local.common_tags
}

resource "aws_iam_policy" "velero" {
  count = var.enable_velero ? 1 : 0

  name = "${local.policy_prefix}-velero-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VeleroEC2Permissions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Sid    = "VeleroS3Permissions"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = var.velero.backup_bucket != null ? "arn:${data.aws_partition.current.partition}:s3:::${var.velero.backup_bucket}/*" : "*"
      },
      {
        Sid    = "VeleroS3BucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.velero.backup_bucket != null ? "arn:${data.aws_partition.current.partition}:s3:::${var.velero.backup_bucket}" : "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "velero" {
  count = var.enable_velero ? 1 : 0

  role       = aws_iam_role.velero[0].name
  policy_arn = aws_iam_policy.velero[0].arn
}

resource "helm_release" "velero" {
  count = var.enable_velero ? 1 : 0

  name = "velero"

  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  version          = var.velero.helm_version
  namespace        = var.velero.namespace
  create_namespace = var.velero.create_namespace
  timeout          = var.velero.timeout

  set = concat(
    [
      {
        name  = "serviceAccount.server.create"
        value = "true"
      },
      {
        name  = "serviceAccount.server.name"
        value = "velero"
      },
      {
        name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
        value = aws_iam_role.velero[0].arn
      },
      {
        name  = "configuration.provider"
        value = "aws"
      },
      {
        name  = "configuration.backupStorageLocation.config.region"
        value = data.aws_region.current.id
      },
      {
        name  = "configuration.volumeSnapshotLocation.config.region"
        value = data.aws_region.current.id
      },
      {
        name  = "initContainers[0].name"
        value = "velero-plugin-for-aws"
      },
      {
        name  = "initContainers[0].image"
        value = "velero/velero-plugin-for-aws:v1.9.0"
      },
      {
        name  = "initContainers[0].volumeMounts[0].mountPath"
        value = "/target"
      },
      {
        name  = "initContainers[0].volumeMounts[0].name"
        value = "plugins"
      }
    ],
    var.velero.backup_bucket != null ? [
      {
        name  = "configuration.backupStorageLocation.bucket"
        value = var.velero.backup_bucket
      }
    ] : [],
    var.velero.set_values
  )
}
