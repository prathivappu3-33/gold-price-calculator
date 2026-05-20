output "vpc_id" {
  description = "VPC ID."
  value       = module.playerhub_aws_stack.vpc_id
}

output "private_subnet_ids" {
  description = "Private application subnet IDs."
  value       = module.playerhub_aws_stack.private_subnet_ids
}

output "data_subnet_ids" {
  description = "Private data subnet IDs."
  value       = module.playerhub_aws_stack.data_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.playerhub_aws_stack.eks_cluster_name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs by logical repository name."
  value       = module.playerhub_aws_stack.ecr_repository_urls
}

output "database_secret_arn" {
  description = "Secrets Manager ARN containing PostgreSQL connection details."
  value       = module.playerhub_aws_stack.database_secret_arn
  sensitive   = true
}

output "redis_secret_arn" {
  description = "Secrets Manager ARN containing Redis connection details."
  value       = module.playerhub_aws_stack.redis_secret_arn
  sensitive   = true
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for the static S3 origin."
  value       = module.playerhub_aws_stack.cloudfront_domain_name
}
