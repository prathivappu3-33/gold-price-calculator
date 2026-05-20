# Reusable AWS Terraform

This Terraform configuration is a reusable AWS infrastructure baseline based on the uploaded Playerhub architecture. It creates a parameterized stack for:

- VPC with public, private application, and private data subnets across multiple Availability Zones
- Internet gateway, optional NAT gateways, and optional VPC endpoints
- EKS cluster and managed node groups for application workloads
- ECR repositories for container images
- S3 buckets for application assets, artifacts, and logs
- RDS PostgreSQL with optional read replicas
- ElastiCache Redis replication group
- Secrets Manager and Parameter Store entries for application configuration
- Regional AWS WAF and optional CloudFront distribution for a static S3 origin

## Layout

```text
terraform/
  main.tf                         # Root example that consumes the reusable module
  providers.tf                    # AWS provider setup
  variables.tf                    # Root variables passed into the module
  outputs.tf                      # Root outputs
  terraform.tfvars.example        # Example environment values
  single-file/
    playerhub-architecture.tf     # Standalone one-file Terraform script
  modules/
    playerhub_aws_stack/          # Reusable infrastructure module
```

If you need one file only, use `single-file/playerhub-architecture.tf` as the standalone Terraform root.

## Usage

1. Copy the example variables file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` for the target environment. At minimum set:

   - `aws_region`
   - `name_prefix`
   - `environment`
   - subnet CIDRs if the defaults overlap with an existing network
   - domain and ACM values if enabling CloudFront aliases

3. Initialize and review the plan:

   ```bash
   terraform init
   terraform plan
   ```

4. Apply when the plan matches the target environment:

   ```bash
   terraform apply
   ```

## Reuse pattern

For another environment, either:

- keep this root module and provide a different `terraform.tfvars`, or
- call `./modules/playerhub_aws_stack` from a separate root module.

Example:

```hcl
module "playerhub_prod" {
  source = "./modules/playerhub_aws_stack"

  name_prefix = "playerhub"
  environment = "prod"
  vpc_cidr    = "10.40.0.0/16"

  app_repositories = ["api", "web", "worker"]

  tags = {
    Owner      = "platform"
    CostCenter = "playerhub"
  }
}
```

## Notes

- The module does not store plaintext database or Redis passwords in variables by default. If passwords are not provided, Terraform generates them and stores connection details in Secrets Manager.
- CloudFront aliases require an ACM certificate in `us-east-1`; pass the certificate ARN via `static_site.acm_certificate_arn`.
- Kubernetes ingress controllers, Karpenter Helm charts, application manifests, and DNS records are intentionally left to deployment automation because those are usually environment and cluster policy specific.
