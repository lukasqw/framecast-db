# Main Configuration - Database Infrastructure

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS database"
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

# Regra: EKS SG (módulo security-groups) → RDS
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from EKS cluster security group"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.eks_security_group_id
}

# Regra: EKS cluster SG (auto-criado pelo EKS) → RDS
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

# Regra: VPC CIDR → RDS (permite pods conectarem)
resource "aws_vpc_security_group_ingress_rule" "rds_from_vpc" {
  security_group_id = aws_security_group.rds.id
  description       = "PostgreSQL from VPC CIDR (allows pods to connect)"
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

# RDS PostgreSQL
module "rds" {
  source = "../../modules/rds"

  identifier     = "${lower(var.project_name)}-db"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  database_name = local.db_name
  username      = local.db_username
  password      = var.db_password

  subnet_ids             = local.filtered_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]

  allocated_storage       = var.rds_allocated_storage
  backup_retention_period = var.rds_backup_retention_period
  multi_az                = var.rds_multi_az
  skip_final_snapshot     = var.rds_skip_final_snapshot
  deletion_protection     = var.rds_deletion_protection

  tags = local.common_tags
}
