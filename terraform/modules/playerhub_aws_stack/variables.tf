variable "name_prefix" {
  description = "Short name used as the prefix for resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to use when availability_zones is empty."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "availability_zones" {
  description = "Explicit Availability Zones to use."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "Optional public subnet CIDRs."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Optional private application subnet CIDRs."
  type        = list(string)
  default     = []
}

variable "data_subnet_cidrs" {
  description = "Optional private data subnet CIDRs."
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

variable "eks_endpoint_public_access" {
  description = "Allow public access to the EKS Kubernetes API endpoint."
  type        = bool
  default     = true
}

variable "eks_endpoint_private_access" {
  description = "Allow private access to the EKS Kubernetes API endpoint."
  type        = bool
  default     = true
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
  default = {}
}

variable "app_repositories" {
  description = "ECR repositories to create for application images."
  type        = set(string)
  default     = []
}

variable "s3_buckets" {
  description = "Additional private S3 buckets for assets, artifacts, or logs."
  type = map(object({
    force_destroy  = optional(bool, false)
    versioning     = optional(bool, true)
    lifecycle_days = optional(number, 365)
  }))
  default = {}
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

variable "database_master_password" {
  description = "Optional PostgreSQL admin password. If null, a password is generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "database_instance_class" {
  description = "RDS instance class for the primary database and read replicas."
  type        = string
  default     = "db.t4g.medium"
}

variable "database_allocated_storage" {
  description = "Initial allocated storage in GiB for PostgreSQL."
  type        = number
  default     = 100
}

variable "database_max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB for PostgreSQL."
  type        = number
  default     = 500
}

variable "database_backup_retention_period" {
  description = "Database backup retention period in days."
  type        = number
  default     = 7
}

variable "database_read_replica_count" {
  description = "Number of PostgreSQL read replicas."
  type        = number
  default     = 0
}

variable "database_deletion_protection" {
  description = "Protect the PostgreSQL primary from accidental deletion."
  type        = bool
  default     = true
}

variable "database_skip_final_snapshot" {
  description = "Skip the final DB snapshot on destroy. Keep false for shared environments."
  type        = bool
  default     = false
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

variable "redis_auth_token" {
  description = "Optional Redis auth token. If null, a token is generated."
  type        = string
  default     = null
  sensitive   = true
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

variable "waf_rate_limit" {
  description = "Maximum requests per five-minute window per source IP for the rate-based WAF rule."
  type        = number
  default     = 2000
}
