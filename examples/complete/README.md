# Example: complete

Deploys most addons on an existing EKS cluster: AWS Load Balancer Controller, Metrics Server, VPA, External DNS (scoped to hosted zones), Cert-Manager, AWS for Fluent Bit, Karpenter with an SQS interruption queue, External Secrets (Secrets Manager + SSM scoped by ARN), EBS CSI driver, KEDA and Velero.

## Usage

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

The cluster (endpoint, CA certificate and IAM OIDC provider) must already exist, as well as the Karpenter node IAM role and the Velero S3 bucket.

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.3  |
| aws       | ~> 6.0  |
| helm      | ~> 3.0  |
