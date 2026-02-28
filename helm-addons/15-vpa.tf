################################################################################
# Vertical Pod Autoscaler (VPA)
################################################################################
#
# VPA automatically adjusts CPU and memory requests/limits for containers based on usage.
# It can work in recommendation mode or auto mode.
#
# Features:
# - Automatic resource request/limit recommendations
# - Auto-update pods with recommended values
# - Prevents resource over/under provisioning
# - Works with Metrics Server
#
# Resources created:
# - Helm release for VPA (no IAM role required)
################################################################################

resource "helm_release" "vpa" {
  count = var.enable_vpa ? 1 : 0

  name = "vpa"

  repository       = "https://charts.fairwinds.com/stable"
  chart            = "vpa"
  version          = var.vpa.helm_version
  namespace        = var.vpa.namespace
  create_namespace = var.vpa.create_namespace
  timeout          = var.vpa.timeout

  set = var.vpa.set_values

  # VPA requires Metrics Server
  depends_on = [
    helm_release.metrics_server
  ]
}
