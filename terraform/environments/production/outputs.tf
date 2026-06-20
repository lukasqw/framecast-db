# Outputs - Database Infrastructure
#
# Consumidos por framecast-api/framecast-worker (deploy.yml → ConfigMap/Secret
# → env DATABASE_URL) e pelo pipeline CI/CD da action tf-apply.

output "rds_address" {
  description = "Host do RDS framecast_db (sem porta)"
  value       = module.rds["framecast"].db_instance_address
  sensitive   = true
}

output "rds_port" {
  description = "Porta do RDS framecast_db"
  value       = module.rds["framecast"].db_instance_port
}

output "rds_database_name" {
  description = "Nome do banco: framecast_db"
  value       = module.rds["framecast"].db_instance_name
}

output "rds_username" {
  description = "Usuário master do banco"
  value       = module.rds["framecast"].db_instance_username
  sensitive   = true
}

output "rds_endpoint" {
  description = "Endpoint do RDS framecast_db (host:port)"
  value       = module.rds["framecast"].db_instance_endpoint
  sensitive   = true
}

output "rds_security_group_id" {
  description = "ID do Security Group da instância RDS"
  value       = aws_security_group.rds.id
}

output "aws_region" {
  description = "Região AWS utilizada"
  value       = var.aws_region
}
