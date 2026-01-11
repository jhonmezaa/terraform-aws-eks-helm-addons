################################################################################
# Local Variables
################################################################################

locals {
  # Region prefix mapping (consistent with EKS module)
  region_prefix_map = {
    "us-east-1"      = "ause1"
    "us-east-2"      = "ause2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-west-3"      = "euw3"
    "eu-central-1"   = "euc1"
    "eu-north-1"     = "eun1"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-south-1"     = "aps1"
    "ca-central-1"   = "cac1"
    "sa-east-1"      = "sae1"
  }

  # Auto-detect region prefix or use provided value
  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    data.aws_region.current.id,
    "custom"
  )

  # Common resource naming prefix
  name_prefix = "${local.region_prefix}-role-eks-addons"
  policy_prefix = "${local.region_prefix}-policy-eks-addons"
  instance_profile_prefix = "${local.region_prefix}-instance-profile-eks"

  # Common tags
  common_tags = merge(
    var.tags_common,
    {
      Module = "terraform-aws-eks-helm-addons"
    }
  )

  # OIDC provider URL without https://
  oidc_provider_url = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")
}
