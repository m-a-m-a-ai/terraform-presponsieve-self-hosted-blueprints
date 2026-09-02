resource "random_password" "app" {
  length  = 32
  special = false # Avoids URL-encoding problems in connection strings.
}

resource "aws_kms_key" "rds" {
  description             = "Encryption at rest for ${var.prefix} Postgres."
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = var.tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.prefix}-pg"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.prefix}-pg" })
}

resource "aws_security_group" "database" {
  name        = "${var.prefix}-pg"
  description = "Postgres access for the Presponsieve deployment."
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.prefix}-pg" })
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.database.id
  description                  = "Postgres from the cluster."
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.prefix}-pg16"
  family = "postgres16"
  tags   = var.tags

  # Presponsieve refuses to start against an instance that allows plaintext.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,vector"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.prefix}-pg"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = "presponsieve"
  username = "presponsieve"
  password = random_password.app.result
  port     = 5432

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot   = true

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.monitoring.arn
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.prefix}-pg-final"

  tags = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [password]
  }
}

resource "aws_iam_role" "monitoring" {
  name = "${var.prefix}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# The password lives in Secrets Manager so the services module can sync it into
# the cluster. It never transits a chart value.
resource "aws_secretsmanager_secret" "db_password" {
  name       = "${var.prefix}/database/password"
  kms_key_id = aws_kms_key.rds.arn
  tags       = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.app.result
}
