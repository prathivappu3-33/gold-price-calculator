output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private application subnet IDs."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "data_subnet_ids" {
  description = "Private data subnet IDs."
  value       = [for subnet in aws_subnet.data : subnet.id]
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = var.enable_eks ? aws_eks_cluster.main[0].name : null
}

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = var.enable_eks ? aws_eks_cluster.main[0].endpoint : null
  sensitive   = true
}

output "eks_node_role_arn" {
  description = "IAM role ARN used by EKS managed node groups."
  value       = var.enable_eks && length(var.eks_node_groups) > 0 ? aws_iam_role.eks_nodes[0].arn : null
}

output "ecr_repository_urls" {
  description = "ECR repository URLs by logical repository name."
  value       = { for name, repository in aws_ecr_repository.app : name => repository.repository_url }
}

output "private_s3_bucket_names" {
  description = "Private S3 bucket names by logical bucket name."
  value       = { for name, bucket in aws_s3_bucket.private : name => bucket.bucket }
}

output "static_site_bucket_name" {
  description = "Static site S3 bucket name."
  value       = var.static_site.enabled && var.static_site.create_bucket ? aws_s3_bucket.static_site[0].bucket : null
}

output "database_endpoint" {
  description = "PostgreSQL primary endpoint."
  value       = var.enable_database ? aws_db_instance.postgres[0].endpoint : null
  sensitive   = true
}

output "database_secret_arn" {
  description = "Secrets Manager ARN containing PostgreSQL connection details."
  value       = var.enable_database ? aws_secretsmanager_secret.database[0].arn : null
  sensitive   = true
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint."
  value       = var.enable_cache ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
  sensitive   = true
}

output "redis_secret_arn" {
  description = "Secrets Manager ARN containing Redis connection details."
  value       = var.enable_cache ? aws_secretsmanager_secret.redis[0].arn : null
  sensitive   = true
}

output "regional_waf_arn" {
  description = "Regional AWS WAF web ACL ARN."
  value       = var.enable_regional_waf ? aws_wafv2_web_acl.regional[0].arn : null
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for the static S3 origin."
  value       = var.static_site.enabled && var.static_site.cloudfront_enabled ? aws_cloudfront_distribution.static_site[0].id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for the static S3 origin."
  value       = var.static_site.enabled && var.static_site.cloudfront_enabled ? aws_cloudfront_distribution.static_site[0].domain_name : null
}
