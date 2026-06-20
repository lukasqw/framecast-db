# Main Configuration - Database Infrastructure
#
# Provisiona:
#   - 1 Security Group para a instância RDS
#   - 1 instância RDS PostgreSQL 16 (framecast_db), compartilhada por api + worker
#
# O schema (users, videos, outbox_events) é responsabilidade da framecast-api
# via GORM AutoMigrate — esta instância é entregue em branco.
#
# A connection string NÃO é armazenada no Secrets Manager: a senha vive como
# GitHub secret (DB_PASSWORD) e o deploy.yml de api/worker monta o DATABASE_URL
# a partir dela + o output rds_address.

# ─── Security Group da instância RDS ─────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "framecast-rds-sg"
  description = "Security group for the framecast_db RDS instance"
  vpc_id      = data.aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name         = "framecast-rds-sg"
      ResourceType = "security-group"
      Service      = "ec2"
      Purpose      = "rds-database"
    }
  )
}

# EKS SG (módulo security-groups) → RDS
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from EKS cluster security group"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.eks_security_group_id
}

# EKS cluster SG (auto-criado pelo EKS) → RDS
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks_cluster_nodes" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from EKS cluster nodes (auto-created cluster SG)"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.eks_cluster_security_group_id

  tags = merge(
    local.common_tags,
    {
      Name    = "framecast-rds-from-eks-nodes"
      Purpose = "allow-eks-nodes-to-rds"
    }
  )
}

# VPC CIDR → RDS (permite pods sem SG explícito conectarem)
resource "aws_vpc_security_group_ingress_rule" "rds_from_vpc" {
  security_group_id = aws_security_group.rds.id
  description       = "PostgreSQL from VPC CIDR (allows all pods to connect)"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ─── RDS PostgreSQL — instância única compartilhada ──────────────────────────
#
# for_each em local.databases (1 entrada) cria:
#   module.rds["framecast"] → framecast_db
#
# Preservar o for_each mantém o padrão do repo base e permite adicionar bancos
# futuramente editando locals.tf. NÃO renomear a chave sem `terraform state mv`.

module "rds" {
  for_each = local.databases
  source   = "../../modules/rds"

  identifier     = each.value.identifier
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  database_name = each.value.database_name
  username      = each.value.username
  password      = var.db_password

  subnet_ids             = local.filtered_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]

  allocated_storage       = var.rds_allocated_storage
  backup_retention_period = var.rds_backup_retention_period
  multi_az                = var.rds_multi_az
  skip_final_snapshot     = var.rds_skip_final_snapshot
  deletion_protection     = var.rds_deletion_protection

  tags = merge(
    local.common_tags,
    {
      Database = each.value.database_name
    }
  )
}
