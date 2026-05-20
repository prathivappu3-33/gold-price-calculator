module "playerhub_aws_stack" {
  source = "./modules/playerhub_aws_stack"

  name_prefix        = var.name_prefix
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs

  enable_nat_gateways  = var.enable_nat_gateways
  single_nat_gateway   = var.single_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints

  enable_eks         = var.enable_eks
  kubernetes_version = var.kubernetes_version
  eks_node_groups    = var.eks_node_groups

  app_repositories = var.app_repositories
  s3_buckets       = var.s3_buckets
  static_site      = var.static_site

  enable_database             = var.enable_database
  database_name               = var.database_name
  database_username           = var.database_username
  database_instance_class     = var.database_instance_class
  database_read_replica_count = var.database_read_replica_count

  enable_cache     = var.enable_cache
  redis_node_type  = var.redis_node_type
  redis_node_count = var.redis_node_count

  parameter_store_values = var.parameter_store_values
  secrets_manager_values = var.secrets_manager_values

  enable_regional_waf = var.enable_regional_waf
  tags                = var.tags
}
