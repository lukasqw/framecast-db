# Local Values

locals {
  # ─── Configuração do banco ─────────────────────────────────────────────────
  # for_each preservado com UMA entrada: mantém o padrão arquitetural do repo
  # base e permite adicionar bancos no futuro editando este mapa.
  # ATENÇÃO: a chave "framecast" compõe o identifier — mudá-la destrói/recria
  # a instância (usar `terraform state mv` para renomear sem perda de dados).
  databases = {
    framecast = {
      identifier    = "${lower(var.project_name)}-db" # framecast-db
      database_name = var.db_name                     # framecast_db
      username      = var.db_username                 # framecast
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
    Repository  = "framecast-db"
    application = "framecast"
  }
}
