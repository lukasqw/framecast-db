# Outputs - Database Infrastructure
#
# Cada MS tem seus próprios outputs com o prefixo rds_ms1/ms2/ms3.
# Consumidos pelos microsserviços via AWS Secrets Manager ou referência direta.

# ─── MS1 — ms-identity (db_ms1) ──────────────────────────────────────────────

output "rds_ms1_address" {
  description = "Endereço do RDS db_ms1 (ms-identity)"
  value       = module.rds["ms1"].db_instance_address
  sensitive   = true
}

output "rds_ms1_port" {
  description = "Porta do RDS db_ms1"
  value       = module.rds["ms1"].db_instance_port
}

output "rds_ms1_database_name" {
  description = "Nome do banco db_ms1"
  value       = module.rds["ms1"].db_instance_name
}

output "rds_ms1_username" {
  description = "Usuário do banco db_ms1"
  value       = module.rds["ms1"].db_instance_username
  sensitive   = true
}

# ─── MS2 — ms-order-service (db_ms2) ─────────────────────────────────────────

output "rds_ms2_address" {
  description = "Endereço do RDS db_ms2 (ms-order-service)"
  value       = module.rds["ms2"].db_instance_address
  sensitive   = true
}

output "rds_ms2_port" {
  description = "Porta do RDS db_ms2"
  value       = module.rds["ms2"].db_instance_port
}

output "rds_ms2_database_name" {
  description = "Nome do banco db_ms2"
  value       = module.rds["ms2"].db_instance_name
}

output "rds_ms2_username" {
  description = "Usuário do banco db_ms2"
  value       = module.rds["ms2"].db_instance_username
  sensitive   = true
}

# ─── MS3 — ms-workshop (db_ms3) ──────────────────────────────────────────────

output "rds_ms3_address" {
  description = "Endereço do RDS db_ms3 (ms-workshop)"
  value       = module.rds["ms3"].db_instance_address
  sensitive   = true
}

output "rds_ms3_port" {
  description = "Porta do RDS db_ms3"
  value       = module.rds["ms3"].db_instance_port
}

output "rds_ms3_database_name" {
  description = "Nome do banco db_ms3"
  value       = module.rds["ms3"].db_instance_name
}

output "rds_ms3_username" {
  description = "Usuário do banco db_ms3"
  value       = module.rds["ms3"].db_instance_username
  sensitive   = true
}

# ─── DynamoDB — ms-order-service (order_history) ─────────────────────────────

output "dynamodb_order_history_table_name" {
  description = "Nome da tabela DynamoDB order_history (ms-order-service)"
  value       = aws_dynamodb_table.order_history.name
}

output "dynamodb_order_history_table_arn" {
  description = "ARN da tabela DynamoDB order_history"
  value       = aws_dynamodb_table.order_history.arn
}

# ─── Infraestrutura compartilhada ────────────────────────────────────────────

output "rds_security_group_id" {
  description = "ID do security group compartilhado pelas 3 instâncias RDS"
  value       = aws_security_group.rds.id
}

output "aws_region" {
  description = "Região AWS"
  value       = var.aws_region
}
