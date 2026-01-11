################################################################################
# Cert-Manager
################################################################################
#
# Cert-Manager automates the management and issuance of TLS certificates from
# various issuing sources (Let's Encrypt, HashiCorp Vault, Venafi, self-signed).
#
# Features:
# - Automatic certificate issuance and renewal
# - Integration with Let's Encrypt for free TLS certificates
# - Support for multiple certificate issuers
# - Kubernetes native CRDs (Certificate, Issuer, ClusterIssuer)
#
# Resources created:
# - Helm release for Cert-Manager (with CRDs)
# - No IAM role required for basic functionality
################################################################################

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name = "cert-manager"

  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager.helm_version
  namespace        = var.cert_manager.namespace
  create_namespace = var.cert_manager.create_namespace
  timeout          = var.cert_manager.timeout

  set {
    name  = "installCRDs"
    value = var.cert_manager.install_crds
  }

  dynamic "set" {
    for_each = var.cert_manager.set_values

    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}
