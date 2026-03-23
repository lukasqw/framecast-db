# General Variables
variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "EKS-OFICINA-TECH"
}

variable "environment" {
  description = "Ambiente (production, staging, development)"
  type        = string
  default     = "production"
}

# RDS Variables
variable "db_password" {
  description = "Senha do banco de dados RDS"
  type        = string
  sensitive   = true
}

variable "rds_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "16"
}

variable "rds_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Storage alocado em GB"
  type        = number
  default     = 20
}

variable "rds_backup_retention_period" {
  description = "Período de retenção de backup em dias"
  type        = number
  default     = 1
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Pular snapshot final ao destruir"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Habilitar proteção contra deleção"
  type        = bool
  default     = false
}
