# RDS PostgreSQL Module

# Parameter Group para configurar SSL
resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-params"
  family = "postgres${split(".", var.engine_version)[0]}"

  # Permitir conexões sem SSL (para desenvolvimento)
  # Em produção, considere manter SSL obrigatório
  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = merge(
    var.tags,
    {
      Name         = "${var.identifier}-params"
      ResourceType = "db-parameter-group"
      Service      = "rds"
    }
  )
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name         = "${var.identifier}-subnet-group"
      ResourceType = "db-subnet-group"
      Service      = "rds"
    }
  )
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  db_name  = var.database_name
  username = var.username
  password = var.password
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  multi_az                  = var.multi_az
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = var.performance_insights_enabled
  deletion_protection             = var.deletion_protection

  tags = merge(
    var.tags,
    {
      Name                = var.identifier
      ResourceType        = "db-instance"
      Service             = "rds"
      Engine              = var.engine
      EngineVersion       = var.engine_version
      InstanceClass       = var.instance_class
      StorageType         = var.storage_type
      AllocatedStorage    = tostring(var.allocated_storage)
      MultiAZ             = tostring(var.multi_az)
      BackupRetention     = tostring(var.backup_retention_period)
      PerformanceInsights = tostring(var.performance_insights_enabled)
    }
  )
}
