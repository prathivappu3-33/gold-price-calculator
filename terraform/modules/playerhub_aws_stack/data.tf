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

  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.postgres[0].name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = true

  backup_retention_period   = var.database_backup_retention_period
  deletion_protection       = var.database_deletion_protection
  skip_final_snapshot       = var.database_skip_final_snapshot
  final_snapshot_identifier = var.database_skip_final_snapshot ? null : "${local.name}-postgres-final"

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
  deletion_protection     = var.database_deletion_protection
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
