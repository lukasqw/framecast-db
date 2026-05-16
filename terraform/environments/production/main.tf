# Main Configuration - Database Infrastructure
#
# Provisiona:
#   - 1 Security Group compartilhado pelas 3 instâncias RDS
#   - 3 instâncias RDS PostgreSQL 16 (db_ms1, db_ms2, db_ms3)
#   - 1 tabela DynamoDB (order_history) para ms-order-service
#
# ATENÇÃO: migrar de uma instância única para for_each destrói e recria
# os recursos RDS. Fazer backup antes de aplicar em ambiente existente.

# ─── Security Group (compartilhado pelas 3 instâncias) ───────────────────────

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS databases (db_ms1, db_ms2, db_ms3)"
  vpc_id      = data.aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-rds-sg"
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
      Name    = "${var.project_name}-rds-from-eks-nodes"
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

# ─── RDS PostgreSQL — uma instância por microsserviço ────────────────────────
#
# for_each em local.databases cria:
#   module.rds["ms1"] → db_ms1  (ms-identity)
#   module.rds["ms2"] → db_ms2  (ms-order-service)
#   module.rds["ms3"] → db_ms3  (ms-workshop)

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
      Microservice = each.key
      Database     = each.value.database_name
      Description  = each.value.description
    }
  )
}

# ─── DynamoDB — histórico de OS do ms-order-service ──────────────────────────
#
# Tabela com billing PAY_PER_REQUEST (sem capacity planning manual).
# Partition key: order_id (UUID da OS)
# Sort key:      occurred_at (ISO 8601 — garante ordenação cronológica)

resource "aws_dynamodb_table" "order_history" {
  name         = var.dynamodb_order_history_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"
  range_key    = "occurred_at"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "occurred_at"
    type = "S"
  }

  # TTL opcional — desabilitado (histórico mantido indefinidamente)
  # Para habilitar: adicionar ttl { attribute_name = "expires_at"; enabled = true }

  tags = merge(
    local.common_tags,
    {
      Name         = var.dynamodb_order_history_table
      Microservice = "ms2"
      Purpose      = "service-order-status-history"
    }
  )
}
