################################################################################
# Ingress Nginx
################################################################################
#
# Ingress Nginx is an Ingress controller for Kubernetes using NGINX as a reverse proxy
# and load balancer. It's an alternative to AWS Load Balancer Controller.
#
# Features:
# - NGINX-based ingress controller
# - SSL/TLS termination
# - URL-based routing
# - WebSocket support
# - Rate limiting and authentication
#
# Resources created:
# - Helm release for Ingress Nginx (no IAM role required)
################################################################################

resource "helm_release" "ingress_nginx" {
  count = var.enable_ingress_nginx ? 1 : 0

  name = "ingress-nginx"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx.helm_version
  namespace        = var.ingress_nginx.namespace
  create_namespace = var.ingress_nginx.create_namespace
  timeout          = var.ingress_nginx.timeout

  set = concat(
    [
      {
        name  = "controller.service.type"
        value = "LoadBalancer"
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = "nlb"
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
        value = "true"
      }
    ],
    var.ingress_nginx.set_values
  )
}
