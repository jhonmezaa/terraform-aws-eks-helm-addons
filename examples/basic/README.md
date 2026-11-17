# Example: basic

Deploys the core addons (AWS Load Balancer Controller and Metrics Server) on an existing EKS cluster.

## Usage

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

The cluster (endpoint, CA certificate and IAM OIDC provider) must already exist.

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.3  |
| aws       | ~> 6.0  |
| helm      | ~> 3.0  |
