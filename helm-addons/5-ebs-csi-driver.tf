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
      variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
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
  name               = "ause1-role-eks-addons-ebs-csi-driver-${var.account_name}-${var.project_name}"

  tags = var.tags_common
}

resource "aws_iam_policy" "csi_ebs_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "ause1-policy-eks-addons-ebs-csi-driver-${var.account_name}-${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
    ]
  })

  tags = var.tags_common
}

resource "aws_iam_role_policy_attachment" "csi_ebs_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.csi_ebs_driver[0].name
  policy_arn = aws_iam_policy.csi_ebs_driver[0].arn
}

resource "helm_release" "csi_ebs_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "ebs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = var.ebs_csi_driver_helm_version

  set = [
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
    }
  ]
}
