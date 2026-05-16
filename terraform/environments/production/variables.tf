# General Variables
variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado como prefixo nos identifiers RDS)"
  type        = string
  default     = "EKS-OFICINA-TECH"
}

variable "environment" {
  description = "Ambiente (production, staging, development)"
  type        = string
  default     = "production"
}

# ─── RDS Variables (aplicadas às 3 instâncias) ────────────────────────────────
# Uma única senha é usada nas 3 instâncias por simplicidade.
# Para senhas independentes por MS, substituir por db_password_ms1/2/3.
variable "db_password" {
  description = "Senha do banco de dados RDS (compartilhada entre as 3 instâncias)"
  type        = string
  sensitive   = true
}

variable "rds_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "16"
}

variable "rds_instance_class" {
  description = "Classe da instância RDS (aplicada às 3 instâncias)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Storage alocado em GB por instância"
  type        = number
  default     = 20
}

variable "rds_backup_retention_period" {
  description = "Período de retenção de backup em dias"
  type        = number
  default     = 7
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ nas instâncias RDS"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Pular snapshot final ao destruir (false em produção)"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Habilitar proteção contra deleção"
  type        = bool
  default     = false
}

# ─── DynamoDB Variables ───────────────────────────────────────────────────────
variable "dynamodb_order_history_table" {
  description = "Nome da tabela DynamoDB para histórico de OS do ms-order-service"
  type        = string
  default     = "order_history"
}

# ─── Terraform State ──────────────────────────────────────────────────────────
variable "tf_state_bucket" {
  description = "Bucket S3 para state do Terraform. Configure TF_STATE_BUCKET nas variáveis do repositório no GitHub Actions. Default mantido para compatibilidade local."
  type        = string
  default     = "fiap-soat-tf-backend-oficina-tech"
}
