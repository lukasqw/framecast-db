# Outputs - Database Infrastructure

# RDS Outputs
output "rds_endpoint" {
  description = "Endpoint do RDS (host:port)"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_address" {
  description = "Endereço do RDS (host apenas)"
  value       = module.rds.db_instance_address
  sensitive   = true
}

output "rds_port" {
  description = "Porta do RDS"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "Nome do banco de dados"
  value       = module.rds.db_instance_name
}

output "rds_username" {
  description = "Username do banco de dados"
  value       = module.rds.db_instance_username
  sensitive   = true
}

# Security Group Output
output "rds_security_group_id" {
  description = "ID do security group do RDS"
  value       = aws_security_group.rds.id
}

# General Outputs
output "aws_region" {
  description = "Região AWS"
  value       = var.aws_region
}
