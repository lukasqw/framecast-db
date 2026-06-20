# General Variables
variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado como prefixo nos identifiers RDS)"
  type        = string
  default     = "framecast"
}

variable "environment" {
  description = "Ambiente (production, staging, development)"
  type        = string
  default     = "production"
}

# ─── RDS Variables ────────────────────────────────────────────────────────────
# Uma única instância RDS compartilhada por framecast-api e framecast-worker.
variable "db_password" {
  description = "Senha do banco de dados RDS (master password)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nome do banco de dados criado na instância"
  type        = string
  default     = "framecast_db"
}

variable "db_username" {
  description = "Usuário master do banco (owner único, usado por api e worker)"
  type        = string
  default     = "framecast"
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
  default     = 7
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ na instância RDS"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Pular snapshot final ao destruir (true para a demo efêmera)"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Habilitar proteção contra deleção"
  type        = bool
  default     = false
}

# ─── Terraform State ──────────────────────────────────────────────────────────
variable "tf_state_bucket" {
  description = "Bucket S3 para state do Terraform. Configure TF_STATE_BUCKET nas variáveis do repositório no GitHub Actions. Default mantido para compatibilidade local."
  type        = string
  default     = "fiap-soat-tf-backend-framecast"
}
