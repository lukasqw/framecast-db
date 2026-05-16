# Local Values

locals {
  # ─── Configuração por microsserviço ────────────────────────────────────────
  # Cada entrada cria uma instância RDS independente.
  # O identifier deve ser único globalmente na conta AWS por região.
  databases = {
    ms1 = {
      identifier    = "${lower(var.project_name)}-ms1"
      database_name = "db_ms1"
      username      = "postgres"
    }
    ms2 = {
      identifier    = "${lower(var.project_name)}-ms2"
      database_name = "db_ms2"
      username      = "postgres"
    }
    ms3 = {
      identifier    = "${lower(var.project_name)}-ms3"
      database_name = "db_ms3"
      username      = "postgres"
    }
  }

  # ─── Rede ──────────────────────────────────────────────────────────────────
  # Requer pelo menos 2 AZs (exigência do RDS subnet group)
  filtered_subnet_ids = [
    for subnet in data.aws_subnet.selected : subnet.id
    if contains(["${var.aws_region}a", "${var.aws_region}b"], subnet.availability_zone)
  ]

  # SG IDs do EKS (do remote state da infra)
  eks_security_group_id         = data.terraform_remote_state.infra.outputs.eks_security_group_id
  eks_cluster_security_group_id = data.terraform_remote_state.infra.outputs.eks_cluster_security_group_id

  # ─── Tags ──────────────────────────────────────────────────────────────────
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "oficina-tech-db"
  }
}
