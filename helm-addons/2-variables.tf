################################################################################
# Common Variables
################################################################################

variable "account_name" {
  description = "Account name for resource naming"
  type        = string

  validation {
    condition     = length(var.account_name) >= 1 && length(var.account_name) <= 32
    error_message = "account_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.account_name))
    error_message = "account_name solo puede contener letras minúsculas, números y guiones (^[a-z0-9-]+$)."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string

  validation {
    condition     = length(var.project_name) >= 1 && length(var.project_name) <= 32
    error_message = "project_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name solo puede contener letras minúsculas, números y guiones (^[a-z0-9-]+$)."
  }
}

variable "region_prefix" {
  description = "Region prefix for resource naming (e.g., ause1 for us-east-1). If null, auto-detected from current region"
  type        = string
  default     = null
}

variable "use_region_prefix" {
  description = "Whether to include the region prefix in resource names. When false, names omit the region prefix."
  type        = bool
  default     = true
}

variable "tags_common" {
  description = "Common tags to apply to all resources"
  type        = map(any)
  default     = {}
}

################################################################################
# EKS Cluster Configuration
################################################################################

variable "eks_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_region" {
  description = "AWS region where the EKS cluster is deployed"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster (used for addon version compatibility)"
  type        = string
  default     = null
}

variable "openid_provider_arn" {
  description = "ARN of the IAM OpenID Connect Provider for IRSA"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS nodes (used by Karpenter)"
  type        = string
  default     = null
}

variable "node_role_name" {
  description = "Name of the IAM role for EKS nodes (used by Karpenter)"
  type        = string
  default     = null
}

################################################################################
# AWS Load Balancer Controller
################################################################################

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller addon"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller addon configuration. values: list of raw YAML values files. vpc_id: VPC ID passed to the chart (vpcId); when null the controller discovers it from instance metadata."
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "kube-system")
    create_namespace = optional(bool, false)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    vpc_id           = optional(string)
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# Metrics Server
################################################################################

variable "enable_metrics_server" {
  description = "Enable Metrics Server addon"
  type        = bool
  default     = false
}

variable "metrics_server" {
  description = "Metrics Server addon configuration"
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "kube-system")
    create_namespace = optional(bool, false)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# External DNS
################################################################################

variable "enable_external_dns" {
  description = "Enable External DNS addon"
  type        = bool
  default     = false
}

variable "external_dns" {
  description = "External DNS addon configuration. route53_zone_arns restricts route53:ChangeResourceRecordSets to those hosted zones (default: all hosted zones)."
  type = object({
    helm_version      = optional(string)
    namespace         = optional(string, "external-dns")
    create_namespace  = optional(bool, true)
    timeout           = optional(number, 300)
    values            = optional(list(string), [])
    domain_filters    = optional(list(string), [])
    route53_zone_arns = optional(list(string), [])
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# Cert-Manager
################################################################################

variable "enable_cert_manager" {
  description = "Enable Cert-Manager addon"
  type        = bool
  default     = false
}

variable "cert_manager" {
  description = "Cert-Manager addon configuration"
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "cert-manager")
    create_namespace = optional(bool, true)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    install_crds     = optional(bool, true)
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# AWS for Fluent Bit
################################################################################

variable "enable_aws_for_fluent_bit" {
  description = "Enable AWS for Fluent Bit addon"
  type        = bool
  default     = false
}

variable "aws_for_fluent_bit" {
  description = "AWS for Fluent Bit addon configuration. cloudwatch_log_kms_key_id: KMS key ARN to encrypt the optional CloudWatch log group."
  type = object({
    helm_version              = optional(string)
    namespace                 = optional(string, "kube-system")
    create_namespace          = optional(bool, false)
    timeout                   = optional(number, 300)
    values                    = optional(list(string), [])
    cloudwatch_log_group      = optional(string)
    cloudwatch_log_retention  = optional(number, 7)
    cloudwatch_log_kms_key_id = optional(string)
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# Karpenter - Node Autoscaler
################################################################################

variable "enable_karpenter" {
  description = "Enable Karpenter addon"
  type        = bool
  default     = false
}

variable "karpenter" {
  description = "Karpenter addon configuration. enable_spot_termination creates an SQS interruption queue plus EventBridge rules (spot interruption, rebalance, state change, AWS Health) and sets settings.interruptionQueue. sqs_kms_master_key_id switches the queue from SQS-managed SSE to KMS."
  type = object({
    helm_version                  = optional(string)
    namespace                     = optional(string, "kube-system")
    create_namespace              = optional(bool, true)
    timeout                       = optional(number, 300)
    values                        = optional(list(string), [])
    spotconsolidation             = optional(bool, false)
    enable_spot_termination       = optional(bool, false)
    sqs_message_retention_seconds = optional(number, 300)
    sqs_kms_master_key_id         = optional(string)
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}

  validation {
    condition     = var.karpenter.sqs_message_retention_seconds >= 60 && var.karpenter.sqs_message_retention_seconds <= 1209600
    error_message = "karpenter.sqs_message_retention_seconds debe estar entre 60 y 1209600 segundos."
  }
}

# Backwards compatibility
variable "karpenter_helm_version" {
  description = "DEPRECATED: Use karpenter.helm_version instead"
  type        = string
  default     = null
}

variable "spotconsolidation" {
  description = "DEPRECATED: Use karpenter.spotconsolidation instead"
  type        = bool
  default     = false
}

################################################################################
# KEDA - Kubernetes Event-Driven Autoscaler
################################################################################

variable "enable_keda" {
  description = "Enable KEDA addon"
  type        = bool
  default     = false
}

variable "keda" {
  description = "KEDA addon configuration"
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "keda")
    create_namespace = optional(bool, true)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

# Backwards compatibility
variable "keda_helm_version" {
  description = "DEPRECATED: Use keda.helm_version instead"
  type        = string
  default     = null
}

################################################################################
# External Secrets Operator
################################################################################

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator addon"
  type        = bool
  default     = false
}

variable "external_secrets" {
  description = "External Secrets Operator addon configuration. secrets_manager_arns defaults to [\"*\"] (all secrets, previous behaviour); ssm_parameter_arns and kms_key_arns add SSM Parameter Store and KMS decrypt permissions when non-empty."
  type = object({
    helm_version         = optional(string)
    namespace            = optional(string, "external-secrets")
    create_namespace     = optional(bool, true)
    timeout              = optional(number, 300)
    values               = optional(list(string), [])
    secrets_manager_arns = optional(list(string), ["*"])
    ssm_parameter_arns   = optional(list(string), [])
    kms_key_arns         = optional(list(string), [])
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

# Backwards compatibility
variable "external_secrets_helm_version" {
  description = "DEPRECATED: Use external_secrets.helm_version instead"
  type        = string
  default     = null
}

################################################################################
# AWS EBS CSI Driver
################################################################################

variable "enable_ebs_csi_driver" {
  description = "Enable AWS EBS CSI Driver addon"
  type        = bool
  default     = false
}

variable "ebs_csi_driver" {
  description = "AWS EBS CSI Driver addon configuration. kms_key_arns grants the KMS permissions required for encrypted EBS volumes."
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "kube-system")
    create_namespace = optional(bool, false)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    kms_key_arns     = optional(list(string), [])
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

# Backwards compatibility
variable "ebs_csi_driver_helm_version" {
  description = "DEPRECATED: Use ebs_csi_driver.helm_version instead"
  type        = string
  default     = null
}

################################################################################
# Velero - Backup and Disaster Recovery
################################################################################

variable "enable_velero" {
  description = "Enable Velero addon"
  type        = bool
  default     = false
}

variable "velero" {
  description = "Velero addon configuration. plugin_image: velero-plugin-for-aws init container image."
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "velero")
    create_namespace = optional(bool, true)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    backup_bucket    = optional(string)
    plugin_image     = optional(string, "velero/velero-plugin-for-aws:v1.11.0")
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# Vertical Pod Autoscaler
################################################################################

variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaler addon"
  type        = bool
  default     = false
}

variable "vpa" {
  description = "Vertical Pod Autoscaler addon configuration"
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "vpa")
    create_namespace = optional(bool, true)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# AWS Node Termination Handler
################################################################################

variable "enable_aws_node_termination_handler" {
  description = "Enable AWS Node Termination Handler addon"
  type        = bool
  default     = false
}

variable "aws_node_termination_handler" {
  description = "AWS Node Termination Handler addon configuration"
  type = object({
    helm_version                      = optional(string)
    namespace                         = optional(string, "kube-system")
    create_namespace                  = optional(bool, false)
    timeout                           = optional(number, 300)
    values                            = optional(list(string), [])
    enable_spot_interruption_draining = optional(bool, true)
    enable_scheduled_event_draining   = optional(bool, true)
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# Ingress Nginx
################################################################################

variable "enable_ingress_nginx" {
  description = "Enable Ingress Nginx addon"
  type        = bool
  default     = false
}

variable "ingress_nginx" {
  description = "Ingress Nginx addon configuration"
  type = object({
    helm_version     = optional(string)
    namespace        = optional(string, "ingress-nginx")
    create_namespace = optional(bool, true)
    timeout          = optional(number, 300)
    values           = optional(list(string), [])
    wait             = optional(bool, true)
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

################################################################################
# Cluster Autoscaler (Deprecated - use Karpenter instead)
################################################################################

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler addon (DEPRECATED: use Karpenter instead)"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_helm_version" {
  description = "Version of the Cluster Autoscaler Helm chart (DEPRECATED)"
  type        = string
  default     = "9.43.2"
}

################################################################################
# Dynatrace Operator
################################################################################

variable "enable_dynatrace" {
  description = "Enable Dynatrace Operator addon"
  type        = bool
  default     = false
}

variable "dynatrace" {
  description = "Dynatrace Operator addon configuration"
  type = object({
    helm_version       = optional(string)
    namespace          = optional(string, "dynatrace")
    create_namespace   = optional(bool, true)
    timeout            = optional(number, 300)
    values             = optional(list(string), [])
    csi_driver_enabled = optional(bool, true)
    set_values = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

# Backwards compatibility
variable "dynatrace_helm_version" {
  description = "DEPRECATED: Use dynatrace.helm_version instead"
  type        = string
  default     = null
}
