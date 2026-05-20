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
