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
