# database.tf
# Configuration de la base de données RDS PostgreSQL

# ============================================================================
# PARAMETER GROUP PERSONNALISÉ
# ============================================================================

resource "aws_db_parameter_group" "postgresql" {
  family = "postgres15"
  name   = "${substr(local.common_prefix, 0, 20)}-postgresql-params"

  # Optimisations pour l'environnement de développement
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log des requêtes > 1 seconde
  }

  parameter {
    name  = "max_connections"
    value = "100"
  }

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-postgresql-params"
    Type = "db-parameter-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# OPTION GROUP (si nécessaire pour des extensions)
# ============================================================================

resource "aws_db_option_group" "postgresql" {
  name                     = "${substr(local.common_prefix, 0, 20)}-postgresql-options"
  option_group_description = "Option group for PostgreSQL"
  engine_name              = var.db_engine
  major_engine_version     = split(".", var.db_engine_version)[0]

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-postgresql-options"
    Type = "db-option-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# GÉNÉRATION DU MOT DE PASSE (si non fourni)
# ============================================================================

resource "random_password" "db_password" {
  count = var.db_password == "" ? 1 : 0

  length  = 16
  special = true
}

# ============================================================================
# SECRET MANAGER POUR LE MOT DE PASSE
# ============================================================================

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${substr(local.common_prefix, 0, 20)}-db-password"
  description             = "PostgreSQL password for microservices"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-db-password"
    Type = "secret"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password != "" ? var.db_password : random_password.db_password[0].result
    engine   = var.db_engine
    host     = aws_db_instance.postgresql.endpoint
    port     = aws_db_instance.postgresql.port
    dbname   = var.db_name
  })
}

# ============================================================================
# RDS INSTANCE PRINCIPALE
# ============================================================================

resource "aws_db_instance" "postgresql" {
  # Identification
  identifier = "${substr(local.common_prefix, 0, 20)}-postgresql"

  # Configuration du moteur
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Base de données
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password != "" ? var.db_password : random_password.db_password[0].result

  # Stockage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  # Réseau et sécurité
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Paramètres et options
  parameter_group_name = aws_db_parameter_group.postgresql.name
  option_group_name    = aws_db_option_group.postgresql.name

  # Sauvegarde et maintenance
  backup_retention_period    = var.db_backup_retention_period
  backup_window              = var.db_backup_window
  maintenance_window         = var.db_maintenance_window
  auto_minor_version_upgrade = var.environment != "prod"

  # Snapshots
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${substr(local.common_prefix, 0, 20)}-postgresql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  snapshot_identifier       = var.environment != "prod" ? null : null # Pour restaurer depuis un snapshot en prod

  # Protection et performance
  deletion_protection = var.db_deletion_protection
  monitoring_interval = var.enable_detailed_monitoring ? 60 : 0
  monitoring_role_arn = var.enable_detailed_monitoring ? aws_iam_role.rds_monitoring[0].arn : null

  performance_insights_enabled          = var.environment == "prod"
  performance_insights_retention_period = var.environment == "prod" ? 7 : null

  # Logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Multi-AZ pour la production
  multi_az = var.environment == "prod"

  tags = merge(local.common_tags, {
    Name    = "${substr(local.common_prefix, 0, 20)}-postgresql"
    Type    = "rds-instance"
    Engine  = var.db_engine
    Version = var.db_engine_version
    Tier    = "database"
  })

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.rds
  ]

  lifecycle {
    prevent_destroy = false # Changez à true en production
    ignore_changes = [
      password, # Le mot de passe est géré par Secrets Manager
    ]
  }
}

# ============================================================================
# KMS KEY POUR LE CHIFFREMENT RDS
# ============================================================================

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-rds-kms-key"
    Type = "kms-key"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${substr(local.common_prefix, 0, 20)}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ============================================================================
# IAM ROLE POUR MONITORING RDS
# ============================================================================

resource "aws_iam_role" "rds_monitoring" {
  count = var.enable_detailed_monitoring ? 1 : 0

  name = "${substr(local.common_prefix, 0, 20)}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-rds-monitoring-role"
    Type = "iam-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enable_detailed_monitoring ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ============================================================================
# CLOUDWATCH LOG GROUPS POUR RDS
# ============================================================================

resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "aws-rds-instance-${aws_db_instance.postgresql.identifier}/postgresql"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-postgresql-logs"
    Type = "cloudwatch-log-group"
  })
}

resource "aws_cloudwatch_log_group" "postgresql_upgrade" {
  name              = "aws-rds-instance-${aws_db_instance.postgresql.identifier}/upgrade"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-postgresql-upgrade-logs"
    Type = "cloudwatch-log-group"
  })
}

# ============================================================================
# REPLICA READ-ONLY (pour la production uniquement)
# ============================================================================

resource "aws_db_instance" "postgresql_replica" {
  count = var.environment == "prod" ? 1 : 0

  identifier                 = "${substr(local.common_prefix, 0, 20)}-postgresql-replica"
  replicate_source_db        = aws_db_instance.postgresql.identifier
  instance_class             = var.db_instance_class
  publicly_accessible        = false
  auto_minor_version_upgrade = false

  monitoring_interval = var.enable_detailed_monitoring ? 60 : 0
  monitoring_role_arn = var.enable_detailed_monitoring ? aws_iam_role.rds_monitoring[0].arn : null

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-postgresql-replica"
    Type = "rds-replica"
    Tier = "database"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================================
# ALARMES CLOUDWATCH POUR MONITORING
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "${substr(local.common_prefix, 0, 20)}-db-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-db-cpu-alarm"
    Type = "cloudwatch-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "${substr(local.common_prefix, 0, 20)}-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS connection count"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-db-connections-alarm"
    Type = "cloudwatch-alarm"
  })
}