################################################################################
# Metrics Server
################################################################################
#
# Metrics Server collects resource metrics from Kubelets and exposes them in
# Kubernetes apiserver through Metrics API for use by Horizontal Pod Autoscaler
# and Vertical Pod Autoscaler. It does not require IRSA as it only reads from
# kubelet APIs within the cluster.
#
# Features:
# - Provides metrics.k8s.io API
# - Required for HPA (Horizontal Pod Autoscaler)
# - Required for VPA (Vertical Pod Autoscaler)
# - Required for `kubectl top` commands
#
# Resources created:
# - Helm release for Metrics Server (no IAM role required)
################################################################################

resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name = "metrics-server"

  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = var.metrics_server.helm_version
  namespace        = var.metrics_server.namespace
  create_namespace = var.metrics_server.create_namespace
  timeout          = var.metrics_server.timeout

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-insecure-tls"
  }

  dynamic "set" {
    for_each = var.metrics_server.set_values

    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}
