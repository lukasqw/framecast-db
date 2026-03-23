output "db_instance_id" {
  description = "ID da instância RDS"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN da instância RDS"
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "Endpoint do RDS (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "Endereço do RDS (host apenas)"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "Username do banco"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_subnet_group_id" {
  description = "ID do subnet group"
  value       = aws_db_subnet_group.this.id
}

output "db_subnet_group_arn" {
  description = "ARN do subnet group"
  value       = aws_db_subnet_group.this.arn
}
