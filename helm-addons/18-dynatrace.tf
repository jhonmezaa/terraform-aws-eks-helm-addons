################################################################################
# Dynatrace Operator
################################################################################
#
# Dynatrace Operator enables full-stack observability for Kubernetes clusters.
# It uses an OCI registry from ECR Public, requiring an ECR Public auth token.
#
# Features:
# - Full-stack monitoring with OneAgent
# - Kubernetes monitoring
# - Application performance monitoring (APM)
# - Infrastructure monitoring
#
# Resources created:
# - Helm release for Dynatrace Operator (no IAM role required)
################################################################################

# Local variables for backwards compatibility
locals {
  dynatrace_helm_version = try(coalesce(var.dynatrace.helm_version, var.dynatrace_helm_version), null)
}

resource "helm_release" "dynatrace_operator" {
  count = var.enable_dynatrace ? 1 : 0

  name = "dynatrace-operator"
  # OCI registry - authentication handled via provider-level registries config
  # NOTE: repository_username/repository_password removed due to Helm provider v3
  # incompatibility with ECR Public token endpoint (405 Method Not Allowed).
  # The caller must configure registries = [{ url = "oci://public.ecr.aws", ... }]
  # in the helm provider block, or the chart will be pulled anonymously.
  repository       = "oci://public.ecr.aws/dynatrace"
  chart            = "dynatrace-operator"
  version          = local.dynatrace_helm_version
  namespace        = var.dynatrace.namespace
  create_namespace = var.dynatrace.create_namespace
  timeout          = var.dynatrace.timeout
  atomic           = true

  set = concat(
    [
      {
        name  = "csidriver.enabled"
        value = tostring(var.dynatrace.csi_driver_enabled)
      }
    ],
    var.dynatrace.set_values
  )
}
