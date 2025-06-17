# variables.tf
# Déclaration de toutes les variables du projet

# ============================================================================
# VARIABLES GLOBALES
# ============================================================================

variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-3"

  validation {
    condition = contains([
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
      "us-east-1", "us-east-2", "us-west-1", "us-west-2"
    ], var.aws_region)
    error_message = "La région AWS doit être une région supportée."
  }
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être dev, staging ou prod."
  }
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "users-albums-ms"
}

variable "owner" {
  description = "Propriétaire du projet"
  type        = string
  default     = "dev-team"
}

variable "cost_center" {
  description = "Centre de coût pour la facturation"
  type        = string
  default     = "development"
}

# ============================================================================
# VARIABLES RÉSEAU
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks pour les subnets publics"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks pour les subnets privés"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks pour les subnets de base de données"
  type        = list(string)
  default     = ["10.0.50.0/24", "10.0.60.0/24"]
}

variable "enable_nat_gateway" {
  description = "Activer la NAT Gateway pour les subnets privés"
  type        = bool
  default     = false # Désactivé pour économiser les coûts en dev
}

variable "enable_dns_hostnames" {
  description = "Activer les noms d'hôtes DNS dans le VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Activer le support DNS dans le VPC"
  type        = bool
  default     = true
}

# ============================================================================
# VARIABLES EC2
# ============================================================================

variable "key_pair_name" {
  description = "Nom de la paire de clés SSH pour les instances EC2"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"

  validation {
    condition = contains([
      "t2.nano", "t2.micro", "t2.small", "t2.medium",
      "t3.nano", "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Le type d'instance doit être dans la gamme t2/t3."
  }
}

variable "enable_detailed_monitoring" {
  description = "Activer la surveillance détaillée pour les instances EC2"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Taille du volume racine en GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type de volume EBS"
  type        = string
  default     = "gp3"
}

# ============================================================================
# VARIABLES RDS
# ============================================================================

variable "db_engine" {
  description = "Moteur de base de données"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Version du moteur de base de données"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "microservicesdb"
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Stockage alloué en GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Stockage maximum alloué en GB"
  type        = number
  default     = 100
}

variable "db_backup_retention_period" {
  description = "Période de rétention des sauvegardes en jours"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Fenêtre de sauvegarde"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Fenêtre de maintenance"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_deletion_protection" {
  description = "Protection contre la suppression"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Ignorer le snapshot final lors de la suppression"
  type        = bool
  default     = true
}

# ============================================================================
# VARIABLES LOAD BALANCER
# ============================================================================

variable "enable_load_balancer" {
  description = "Activer l'Application Load Balancer"
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "Type de Load Balancer"
  type        = string
  default     = "application"
}

variable "enable_deletion_protection" {
  description = "Protection contre la suppression du Load Balancer"
  type        = bool
  default     = false
}

# ============================================================================
# VARIABLES MICROSERVICES
# ============================================================================

variable "microservices" {
  description = "Configuration des microservices"
  type = map(object({
    port              = number
    health_check_path = string
    min_capacity      = number
    max_capacity      = number
    desired_capacity  = number
  }))
  default = {
    config-server = {
      port              = 8888
      health_check_path = "/actuator/health"
      min_capacity      = 1
      max_capacity      = 1
      desired_capacity  = 1
    }
    eureka-server = {
      port              = 8761
      health_check_path = "/actuator/health"
      min_capacity      = 1
      max_capacity      = 1
      desired_capacity  = 1
    }
    api-gateway = {
      port              = 8080
      health_check_path = "/actuator/health"
      min_capacity      = 1
      max_capacity      = 2
      desired_capacity  = 1
    }
    users-service = {
      port              = 8081
      health_check_path = "/actuator/health"
      min_capacity      = 1
      max_capacity      = 3
      desired_capacity  = 1
    }
    albums-service = {
      port              = 8082
      health_check_path = "/actuator/health"
      min_capacity      = 1
      max_capacity      = 3
      desired_capacity  = 1
    }
  }
}

# ============================================================================
# VARIABLES MONITORING
# ============================================================================

variable "enable_elasticsearch" {
  description = "Activer Elasticsearch pour les logs"
  type        = bool
  default     = true
}

variable "elasticsearch_version" {
  description = "Version d'Elasticsearch"
  type        = string
  default     = "8.11"
}

variable "enable_kibana" {
  description = "Activer Kibana pour la visualisation"
  type        = bool
  default     = true
}

# ============================================================================
# VARIABLES SÉCURITÉ
# ============================================================================

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks autorisés pour SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # À restreindre en production
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks autorisés pour HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


# ============================================================================
# VARIABLES LOCALES
# ============================================================================

locals {
  # Préfixe commun pour toutes les ressources
  common_prefix = replace(lower("${var.environment}-${var.project_name}"), "/[^a-z0-9-.]/", "-") # Remplace les espaces par des underscores
  # common_prefix = replace(local.common_prefix, "_", "-")  # Convert underscores to hyphens
  # common_prefix = replace(local.common_prefix, ".", "-")  # Convert periods to hyphens
  # common_prefix = lower(local.common_prefix)  # Ensure lowercase


  # Tags communs
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }

  # Configuration des availability zones
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  # Ports des services
  service_ports = {
    ssh                     = 22
    http                    = 80
    https                   = 443
    postgresql              = 5432
    rabbitmq                = 5672
    rabbitmq_management     = 15672
    elasticsearch           = 9200
    elasticsearch_transport = 9300
    kibana                  = 5601
    logstash                = 5044
  }
}