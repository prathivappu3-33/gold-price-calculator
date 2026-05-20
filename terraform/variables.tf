variable "aws_region" {
  description = "AWS region for regional resources."
  type        = string
  default     = "us-west-1"
}

variable "name_prefix" {
  description = "Short name used as the prefix for resource names."
  type        = string
  default     = "playerhub"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,24}$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name, such as dev, staging, or prod."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones to use. If empty, Terraform selects the first az_count zones in the region."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "Optional public subnet CIDRs. If empty, CIDRs are derived from vpc_cidr."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Optional private application subnet CIDRs. If empty, CIDRs are derived from vpc_cidr."
  type        = list(string)
  default     = []
}

variable "data_subnet_cidrs" {
  description = "Optional private data subnet CIDRs. If empty, CIDRs are derived from vpc_cidr."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateways" {
  description = "Create NAT gateways for private application subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one NAT gateway per Availability Zone."
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create common VPC endpoints for private AWS service access."
  type        = bool
  default     = true
}

variable "enable_eks" {
  description = "Create an EKS cluster and managed node groups."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "eks_node_groups" {
  description = "Map of managed node group settings."
  type = map(object({
    instance_types = optional(list(string), ["t3.medium"])
    capacity_type  = optional(string, "ON_DEMAND")
    desired_size   = optional(number, 2)
    min_size       = optional(number, 1)
    max_size       = optional(number, 4)
    disk_size      = optional(number, 40)
    labels         = optional(map(string), {})
  }))
  default = {
    application = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }
}

variable "app_repositories" {
  description = "ECR repositories to create for application images."
  type        = set(string)
  default     = ["api", "web", "worker"]
}

variable "s3_buckets" {
  description = "Additional private S3 buckets for assets, artifacts, or logs."
  type = map(object({
    force_destroy  = optional(bool, false)
    versioning     = optional(bool, true)
    lifecycle_days = optional(number, 365)
  }))
  default = {
    artifacts = {}
    logs      = {}
  }
}

variable "static_site" {
  description = "Static S3 origin and optional CloudFront distribution settings."
  type = object({
    enabled             = optional(bool, true)
    create_bucket       = optional(bool, true)
    bucket_name         = optional(string)
    cloudfront_enabled  = optional(bool, true)
    aliases             = optional(list(string), [])
    acm_certificate_arn = optional(string)
    web_acl_id          = optional(string)
    price_class         = optional(string, "PriceClass_100")
  })
  default = {}
}

variable "enable_database" {
  description = "Create RDS PostgreSQL resources."
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "playerhub"
}

variable "database_username" {
  description = "PostgreSQL admin username."
  type        = string
  default     = "playerhub_admin"
}

variable "database_instance_class" {
  description = "RDS instance class for the primary database and read replicas."
  type        = string
  default     = "db.t4g.medium"
}

variable "database_read_replica_count" {
  description = "Number of PostgreSQL read replicas."
  type        = number
  default     = 1
}

variable "enable_cache" {
  description = "Create ElastiCache Redis resources."
  type        = bool
  default     = true
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_node_count" {
  description = "Number of Redis cache nodes."
  type        = number
  default     = 2
}

variable "parameter_store_values" {
  description = "Non-secret SSM Parameter Store values to create."
  type        = map(string)
  default     = {}
}

variable "secrets_manager_values" {
  description = "Additional Secrets Manager secret values to create."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "enable_regional_waf" {
  description = "Create a regional AWS WAF web ACL for application load balancers or API endpoints."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default = {
    Project   = "playerhub"
    ManagedBy = "terraform"
  }
}
