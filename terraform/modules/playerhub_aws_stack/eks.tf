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

resource "aws_eks_cluster" "main" {
  count = var.enable_eks ? 1 : 0

  name     = "${local.name}-eks"
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = var.kubernetes_version

  vpc_config {
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
    subnet_ids              = [for subnet in aws_subnet.private : subnet.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.eks_cluster
  ]
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_eks ? 1 : 0

  name              = "/aws/eks/${local.name}-eks/cluster"
  retention_in_days = 30

  tags = local.common_tags
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

resource "aws_security_group_rule" "database_from_eks_cluster" {
  count = var.enable_eks ? 1 : 0

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id
  security_group_id        = aws_security_group.database.id
  description              = "Allow PostgreSQL from EKS cluster security group"
}

resource "aws_security_group_rule" "redis_from_eks_cluster" {
  count = var.enable_eks ? 1 : 0

  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id
  security_group_id        = aws_security_group.redis.id
  description              = "Allow Redis from EKS cluster security group"
}
