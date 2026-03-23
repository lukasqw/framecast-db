variable "identifier" {
  description = "Identificador único do RDS"
  type        = string
}

variable "engine" {
  description = "Engine do banco de dados"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Versão do engine"
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "Classe da instância"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage alocado em GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage máximo para autoscaling"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Tipo de storage"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Habilitar encriptação do storage"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "username" {
  description = "Username do banco"
  type        = string
}

variable "password" {
  description = "Senha do banco"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Porta do banco"
  type        = number
  default     = 5432
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "IDs dos security groups"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Tornar o RDS publicamente acessível"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Período de retenção de backup em dias"
  type        = number
  default     = 1
}

variable "backup_window" {
  description = "Janela de backup"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Janela de manutenção"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "multi_az" {
  description = "Habilitar Multi-AZ"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Pular snapshot final ao destruir"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Logs para exportar ao CloudWatch"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "performance_insights_enabled" {
  description = "Habilitar Performance Insights"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Habilitar proteção contra deleção"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}
