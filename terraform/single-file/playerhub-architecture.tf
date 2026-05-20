terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

variable "aws_region" {
  description = "AWS region for regional resources."
  type        = string
  default     = "us-west-1"
}

variable "name_prefix" {
  description = "Short name used as the prefix for resource names."
  type        = string
  default     = "playerhub"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default = {
    Project   = "playerhub"
    ManagedBy = "terraform"
  }
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
  description = "Explicit Availability Zones to use. Leave empty to select automatically."
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
  description = "Managed node groups for application pods."
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
  description = "Additional private S3 buckets for assets, artifacts, and logs."
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

variable "database_master_password" {
  description = "Optional PostgreSQL admin password. If null, a password is generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "database_instance_class" {
  description = "RDS instance class for primary and replica databases."
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

variable "redis_auth_token" {
  description = "Optional Redis auth token. If null, a token is generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "parameter_store_values" {
  description = "Non-secret SSM Parameter Store values to create."
  type        = map(string)
  default = {
    "/playerhub/dev/app/environment" = "dev"
  }
}

variable "secrets_manager_values" {
  description = "Additional Secrets Manager secret values to create."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "enable_regional_waf" {
  description = "Create a regional AWS WAF web ACL for application entry points."
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Maximum requests per five-minute window per source IP."
  type        = number
  default     = 2000
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  name = "${var.name_prefix}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, var.az_count)
  subnet_count = length(local.selected_azs)

  public_subnet_cidrs  = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [for index in range(local.subnet_count) : cidrsubnet(var.vpc_cidr, 8, index)]
  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [for index in range(local.subnet_count) : cidrsubnet(var.vpc_cidr, 8, index + 10)]
  data_subnet_cidrs    = length(var.data_subnet_cidrs) > 0 ? var.data_subnet_cidrs : [for index in range(local.subnet_count) : cidrsubnet(var.vpc_cidr, 8, index + 20)]

  public_subnets = {
    for index, az in local.selected_azs : az => {
      index = index
      cidr  = local.public_subnet_cidrs[index]
    }
  }

  private_subnets = {
    for index, az in local.selected_azs : az => {
      index = index
      cidr  = local.private_subnet_cidrs[index]
    }
  }

  data_subnets = {
    for index, az in local.selected_azs : az => {
      index = index
      cidr  = local.data_subnet_cidrs[index]
    }
  }

  nat_gateway_subnets = var.enable_nat_gateways ? (
    var.single_nat_gateway ? {
      (local.selected_azs[0]) = local.public_subnets[local.selected_azs[0]]
    } : local.public_subnets
  ) : {}

  interface_vpc_endpoints = toset([
    "com.amazonaws.${data.aws_region.current.region}.ec2",
    "com.amazonaws.${data.aws_region.current.region}.ecr.api",
    "com.amazonaws.${data.aws_region.current.region}.ecr.dkr",
    "com.amazonaws.${data.aws_region.current.region}.kms",
    "com.amazonaws.${data.aws_region.current.region}.logs",
    "com.amazonaws.${data.aws_region.current.region}.secretsmanager",
    "com.amazonaws.${data.aws_region.current.region}.ssm"
  ])
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${local.name}-public-${each.value.index + 1}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value.cidr

  tags = merge(local.common_tags, {
    Name                              = "${local.name}-private-app-${each.value.index + 1}"
    Tier                              = "application"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "data" {
  for_each = local.data_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value.cidr

  tags = merge(local.common_tags, {
    Name = "${local.name}-private-data-${each.value.index + 1}"
    Tier = "data"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateway_subnets

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name}-nat-eip-${each.value.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  for_each = local.nat_gateway_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-nat-${each.value.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-private-app-rt-${local.private_subnets[each.key].index + 1}"
    Tier = "application"
  })
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateways ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[local.selected_azs[0]].id : aws_nat_gateway.main[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table" "data" {
  for_each = aws_subnet.data

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-private-data-rt-${local.data_subnets[each.key].index + 1}"
    Tier = "data"
  })
}

resource "aws_route_table_association" "data" {
  for_each = aws_subnet.data

  subnet_id      = each.value.id
  route_table_id = aws_route_table.data[each.key].id
}

resource "aws_security_group" "workloads" {
  name        = "${local.name}-workloads"
  description = "Security group for application workloads and EKS nodes"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-workloads"
  })
}

resource "aws_security_group_rule" "workloads_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.workloads.id
  description       = "Allow workload-to-workload traffic"
}

resource "aws_security_group_rule" "workloads_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.workloads.id
  description       = "Allow outbound workload traffic"
}

resource "aws_security_group" "database" {
  name        = "${local.name}-postgres"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-postgres"
  })
}

resource "aws_security_group_rule" "database_from_workloads" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.workloads.id
  security_group_id        = aws_security_group.database.id
  description              = "Allow PostgreSQL from application workloads"
}

resource "aws_security_group_rule" "database_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database.id
  description       = "Allow outbound PostgreSQL maintenance traffic"
}

resource "aws_security_group" "redis" {
  name        = "${local.name}-redis"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-redis"
  })
}

resource "aws_security_group_rule" "redis_from_workloads" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.workloads.id
  security_group_id        = aws_security_group.redis.id
  description              = "Allow Redis from application workloads"
}

resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis.id
  description       = "Allow outbound Redis maintenance traffic"
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name}-vpc-endpoints"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc-endpoints"
  })
}

resource "aws_security_group_rule" "vpc_endpoints_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow private HTTPS access to interface endpoints"
}

resource "aws_security_group_rule" "vpc_endpoints_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow endpoint responses"
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([for route_table in aws_route_table.private : route_table.id], [for route_table in aws_route_table.data : route_table.id])

  tags = merge(local.common_tags, {
    Name = "${local.name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_vpc_endpoints ? local.interface_vpc_endpoints : toset([])

  vpc_id              = aws_vpc.main.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = replace("${local.name}-${each.value}", ".", "-")
  })
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  count = var.enable_eks ? 1 : 0

  name               = "${local.name}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  count = var.enable_eks ? 1 : 0

  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_eks ? 1 : 0

  name              = "/aws/eks/${local.name}-eks/cluster"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_eks_cluster" "main" {
  count = var.enable_eks ? 1 : 0

  name     = "${local.name}-eks"
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = var.kubernetes_version

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.workloads.id]
    subnet_ids              = [for subnet in aws_subnet.private : subnet.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.eks_cluster
  ]
}

resource "aws_iam_role" "eks_nodes" {
  count = var.enable_eks && length(var.eks_node_groups) > 0 ? 1 : 0

  name               = "${local.name}-eks-nodes"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_nodes_worker" {
  count = var.enable_eks && length(var.eks_node_groups) > 0 ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_cni" {
  count = var.enable_eks && length(var.eks_node_groups) > 0 ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_ecr" {
  count = var.enable_eks && length(var.eks_node_groups) > 0 ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_ssm" {
  count = var.enable_eks && length(var.eks_node_groups) > 0 ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_eks_node_group" "managed" {
  for_each = var.enable_eks ? var.eks_node_groups : {}

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${local.name}-${each.key}"
  node_role_arn   = aws_iam_role.eks_nodes[0].arn
  subnet_ids      = [for subnet in aws_subnet.private : subnet.id]

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
  labels         = each.value.labels

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_worker,
    aws_iam_role_policy_attachment.eks_nodes_cni,
    aws_iam_role_policy_attachment.eks_nodes_ecr,
    aws_iam_role_policy_attachment.eks_nodes_ssm
  ]
}

resource "aws_ecr_repository" "app" {
  for_each = var.app_repositories

  name                 = "${local.name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the most recent 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "private" {
  for_each = var.s3_buckets

  bucket        = "${local.name}-${each.key}-${data.aws_region.current.region}"
  force_destroy = each.value.force_destroy

  tags = merge(local.common_tags, {
    Name = "${local.name}-${each.key}"
  })
}

resource "aws_s3_bucket_public_access_block" "private" {
  for_each = aws_s3_bucket.private

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  versioning_configuration {
    status = var.s3_buckets[each.key].versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "private" {
  for_each = aws_s3_bucket.private

  bucket = each.value.id

  rule {
    id     = "expire-old-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.s3_buckets[each.key].lifecycle_days
    }
  }
}

resource "aws_s3_bucket" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket        = coalesce(var.static_site.bucket_name, "${local.name}-static-${data.aws_region.current.region}")
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = "${local.name}-static"
  })
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.static_site[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_site" {
  count = var.static_site.enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_password" "database" {
  count = var.enable_database && var.database_master_password == null ? 1 : 0

  length  = 32
  special = true
}

resource "aws_db_subnet_group" "postgres" {
  count = var.enable_database ? 1 : 0

  name       = "${local.name}-postgres"
  subnet_ids = [for subnet in aws_subnet.data : subnet.id]

  tags = merge(local.common_tags, {
    Name = "${local.name}-postgres"
  })
}

resource "aws_db_instance" "postgres" {
  count = var.enable_database ? 1 : 0

  identifier = "${local.name}-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.database_instance_class

  db_name  = var.database_name
  username = var.database_username
  password = var.database_master_password != null ? var.database_master_password : random_password.database[0].result

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.postgres[0].name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = true

  backup_retention_period   = 7
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-postgres-final"

  performance_insights_enabled = true
  copy_tags_to_snapshot        = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-postgres"
  })
}

resource "aws_db_instance" "postgres_replica" {
  count = var.enable_database ? var.database_read_replica_count : 0

  identifier          = "${local.name}-postgres-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.postgres[0].identifier
  instance_class      = var.database_instance_class

  storage_encrypted      = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.database.id]

  backup_retention_period = 0
  deletion_protection     = true
  skip_final_snapshot     = true
  copy_tags_to_snapshot   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-postgres-replica-${count.index + 1}"
  })
}

resource "aws_secretsmanager_secret" "database" {
  count = var.enable_database ? 1 : 0

  name        = "${local.name}/database"
  description = "PostgreSQL connection details for ${local.name}"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "database" {
  count = var.enable_database ? 1 : 0

  secret_id = aws_secretsmanager_secret.database[0].id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.postgres[0].address
    port     = aws_db_instance.postgres[0].port
    database = var.database_name
    username = var.database_username
    password = var.database_master_password != null ? var.database_master_password : random_password.database[0].result
  })
}

resource "random_password" "redis" {
  count = var.enable_cache && var.redis_auth_token == null ? 1 : 0

  length           = 32
  special          = true
  override_special = "!&#$^<>-"
}

resource "aws_elasticache_subnet_group" "redis" {
  count = var.enable_cache ? 1 : 0

  name       = "${local.name}-redis"
  subnet_ids = [for subnet in aws_subnet.data : subnet.id]

  tags = local.common_tags
}

resource "aws_elasticache_replication_group" "redis" {
  count = var.enable_cache ? 1 : 0

  replication_group_id = substr("${local.name}-redis", 0, 40)
  description          = "Redis cache for ${local.name}"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = var.redis_node_type
  port           = 6379

  num_cache_clusters         = var.redis_node_count
  automatic_failover_enabled = var.redis_node_count > 1
  multi_az_enabled           = var.redis_node_count > 1

  subnet_group_name  = aws_elasticache_subnet_group.redis[0].name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token != null ? var.redis_auth_token : random_password.redis[0].result

  tags = merge(local.common_tags, {
    Name = "${local.name}-redis"
  })
}

resource "aws_secretsmanager_secret" "redis" {
  count = var.enable_cache ? 1 : 0

  name        = "${local.name}/redis"
  description = "Redis connection details for ${local.name}"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redis" {
  count = var.enable_cache ? 1 : 0

  secret_id = aws_secretsmanager_secret.redis[0].id
  secret_string = jsonencode({
    engine = "redis"
    host   = aws_elasticache_replication_group.redis[0].primary_endpoint_address
    port   = aws_elasticache_replication_group.redis[0].port
    token  = var.redis_auth_token != null ? var.redis_auth_token : random_password.redis[0].result
  })
}

resource "aws_ssm_parameter" "config" {
  for_each = var.parameter_store_values

  name        = each.key
  description = "Configuration value for ${local.name}"
  type        = "String"
  value       = each.value

  tags = local.common_tags
}

resource "aws_secretsmanager_secret" "custom" {
  for_each = toset(keys(nonsensitive(var.secrets_manager_values)))

  name        = each.value
  description = "Managed secret for ${local.name}"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "custom" {
  for_each = toset(keys(nonsensitive(var.secrets_manager_values)))

  secret_id     = aws_secretsmanager_secret.custom[each.value].id
  secret_string = var.secrets_manager_values[each.value]
}

resource "aws_wafv2_web_acl" "regional" {
  count = var.enable_regional_waf ? 1 : 0

  name        = "${local.name}-regional-waf"
  description = "Regional WAF for ${local.name} application entry points"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-managed-common"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit"
    priority = 20

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = var.waf_rate_limit
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-regional-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_cloudfront_origin_access_control" "static_site" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled && var.static_site.create_bucket ? 1 : 0

  name                              = "${local.name}-static-oac"
  description                       = "Origin access control for ${local.name} static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static_site" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled ? 1 : 0

  enabled             = true
  comment             = "${local.name} static site"
  default_root_object = "index.html"
  price_class         = var.static_site.price_class
  aliases             = var.static_site.aliases
  web_acl_id          = var.static_site.web_acl_id

  origin {
    domain_name              = var.static_site.create_bucket ? aws_s3_bucket.static_site[0].bucket_regional_domain_name : "${var.static_site.bucket_name}.s3.${data.aws_region.current.region}.amazonaws.com"
    origin_id                = "static-s3"
    origin_access_control_id = var.static_site.create_bucket ? aws_cloudfront_origin_access_control.static_site[0].id : null
  }

  default_cache_behavior {
    target_origin_id       = "static-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.static_site.acm_certificate_arn
    cloudfront_default_certificate = var.static_site.acm_certificate_arn == null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = var.static_site.acm_certificate_arn == null ? null : "sni-only"
  }

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = length(var.static_site.aliases) == 0 || var.static_site.acm_certificate_arn != null
      error_message = "static_site.acm_certificate_arn is required when static_site.aliases is not empty."
    }

    precondition {
      condition     = var.static_site.create_bucket || var.static_site.bucket_name != null
      error_message = "static_site.bucket_name is required when static_site.create_bucket is false."
    }
  }
}

data "aws_iam_policy_document" "static_site_cloudfront" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled && var.static_site.create_bucket ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site[0].arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static_site[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_site_cloudfront" {
  count = var.static_site.enabled && var.static_site.cloudfront_enabled && var.static_site.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.static_site[0].id
  policy = data.aws_iam_policy_document.static_site_cloudfront[0].json
}

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

output "ecr_repository_urls" {
  description = "ECR repository URLs by logical repository name."
  value       = { for name, repository in aws_ecr_repository.app : name => repository.repository_url }
}

output "database_secret_arn" {
  description = "Secrets Manager ARN containing PostgreSQL connection details."
  value       = var.enable_database ? aws_secretsmanager_secret.database[0].arn : null
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

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for the static S3 origin."
  value       = var.static_site.enabled && var.static_site.cloudfront_enabled ? aws_cloudfront_distribution.static_site[0].domain_name : null
}
