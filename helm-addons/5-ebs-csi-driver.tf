# =============================================================================
# AWS EBS CSI Driver
# =============================================================================
#
# The AWS EBS CSI Driver allows Kubernetes to manage Amazon EBS volumes as
# persistent volumes. This driver is required for dynamic provisioning of
# EBS volumes in EKS clusters running Kubernetes 1.23+.
#
# Resources created:
# - IAM role with IRSA (IAM Roles for Service Accounts) trust policy
# - IAM policy with permissions for EBS volume and snapshot management
# - Helm release for EBS CSI Driver chart
# =============================================================================

data "aws_iam_policy_document" "csi_ebs_driver_trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.ebs_csi_driver.namespace}:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "csi_ebs_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.csi_ebs_driver_trust_policy.json
  name               = substr("${local.role_prefix}-ebs-csi-driver-${local.name_suffix}", 0, 64)
  tags               = merge(local.common_tags, { Name = substr("${local.role_prefix}-ebs-csi-driver-${local.name_suffix}", 0, 64) })
}

resource "aws_iam_policy" "csi_ebs_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "${local.policy_prefix}-ebs-csi-driver-${local.name_suffix}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "EBSCSIDriverGeneralPermissions"
        Effect = "Allow",
        Action = [
          # Snapshot management
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          # Volume operations
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          # Read permissions
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          # Tagging
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        Resource = "*"
      },
      {
        Sid    = "EBSCSIDriverVolumeCreationPermissions"
        Effect = "Allow",
        Action = [
          # Volume lifecycle management
          "ec2:CreateVolume",
          "ec2:DeleteVolume"
        ],
        Resource = "*",
        Condition = {
          StringEqualsIfExists = {
            "ec2:CreateVolumePermission" : "true"
          }
        }
      },
      ],
      # Customer managed KMS keys for encrypted EBS volumes (opt-in)
      [for statement in [
        {
          Sid    = "EBSCSIDriverKMSGrants"
          Effect = "Allow"
          Action = [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ]
          Resource = var.ebs_csi_driver.kms_key_arns
          Condition = {
            Bool = {
              "kms:GrantIsForAWSResource" = "true"
            }
          }
        },
        {
          Sid    = "EBSCSIDriverKMSUsage"
          Effect = "Allow"
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = var.ebs_csi_driver.kms_key_arns
        },
      ] : statement if length(var.ebs_csi_driver.kms_key_arns) > 0]
    )
  })

  tags = merge(local.common_tags, { Name = "${local.policy_prefix}-ebs-csi-driver-${local.name_suffix}" })
}

resource "aws_iam_role_policy_attachment" "csi_ebs_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.csi_ebs_driver[0].name
  policy_arn = aws_iam_policy.csi_ebs_driver[0].arn
}

# Local variable for backwards compatibility
locals {
  ebs_csi_driver_helm_version = try(coalesce(var.ebs_csi_driver.helm_version, var.ebs_csi_driver_helm_version), null)
}

resource "helm_release" "csi_ebs_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "ebs-csi-driver"

  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  namespace        = var.ebs_csi_driver.namespace
  version          = local.ebs_csi_driver_helm_version
  create_namespace = var.ebs_csi_driver.create_namespace
  timeout          = var.ebs_csi_driver.timeout

  values = var.ebs_csi_driver.values

  set = concat(
    [
      {
        name  = "controller.serviceAccount.create"
        value = "true"
      },
      {
        name  = "controller.serviceAccount.name"
        value = "ebs-csi-controller-sa"
      },
      {
        name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = aws_iam_role.csi_ebs_driver[0].arn
      },
    ],
    var.ebs_csi_driver.set_values
  )
}
