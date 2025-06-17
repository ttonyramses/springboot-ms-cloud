# outputs.tf
# Définition des sorties Terraform

# ============================================================================
# INFORMATIONS RÉSEAU
# ============================================================================

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block du VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des subnets privés"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs des subnets de base de données"
  value       = aws_subnet.database[*].id
}

output "internet_gateway_id" {
  description = "ID de l'Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# ============================================================================
# INFORMATIONS SÉCURITÉ
# ============================================================================

output "microservices_security_group_id" {
  description = "ID du security group des microservices"
  value       = aws_security_group.microservices.id
}

output "alb_security_group_id" {
  description = "ID du security group de l'ALB"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "ID du security group RDS"
  value       = aws_security_group.rds.id
}

# ============================================================================
# INFORMATIONS BASE DE DONNÉES
# ============================================================================

output "rds_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = aws_db_instance.postgresql.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "Port de la base de données RDS"
  value       = aws_db_instance.postgresql.port
}

output "rds_database_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.postgresql.db_name
}

output "rds_username" {
  description = "Nom d'utilisateur de la base de données"
  value       = aws_db_instance.postgresql.username
  sensitive   = true
}

output "rds_secret_arn" {
  description = "ARN du secret contenant les credentials de la base de données"
  value       = aws_secretsmanager_secret.db_password.arn
}

# ============================================================================
# INFORMATIONS INSTANCES EC2
# ============================================================================

output "config_server_instance_id" {
  description = "ID de l'instance Config Server"
  value       = aws_instance.config_server.id
}

output "config_server_private_ip" {
  description = "IP privée du Config Server"
  value       = aws_instance.config_server.private_ip
}

output "eureka_server_instance_id" {
  description = "ID de l'instance Eureka Server"
  value       = aws_instance.eureka_server.id
}

output "eureka_server_private_ip" {
  description = "IP privée du Eureka Server"
  value       = aws_instance.eureka_server.private_ip
}

output "api_gateway_instance_id" {
  description = "ID de l'instance API Gateway"
  value       = aws_instance.api_gateway.id
}

output "api_gateway_private_ip" {
  description = "IP privée de l'API Gateway"
  value       = aws_instance.api_gateway.private_ip
}

output "users_service_instance_id" {
  description = "ID de l'instance Users Service"
  value       = aws_instance.users_service.id
}

output "users_service_private_ip" {
  description = "IP privée du Users Service"
  value       = aws_instance.users_service.private_ip
}

output "albums_service_instance_id" {
  description = "ID de l'instance Albums Service"
  value       = aws_instance.albums_service.id
}

output "albums_service_private_ip" {
  description = "IP privée de l'Albums Service"
  value       = aws_instance.albums_service.private_ip
}

output "elasticsearch_instance_id" {
  description = "ID de l'instance Elasticsearch"
  value       = var.enable_elasticsearch ? aws_instance.elasticsearch[0].id : null
}

output "elasticsearch_private_ip" {
  description = "IP privée d'Elasticsearch"
  value       = var.enable_elasticsearch ? aws_instance.elasticsearch[0].private_ip : null
}

output "bastion_instance_id" {
  description = "ID de l'instance Bastion (dev uniquement)"
  value       = var.environment == "dev" ? aws_instance.bastion[0].id : null
}

output "bastion_public_ip" {
  description = "IP publique du Bastion (dev uniquement)"
  value       = var.environment == "dev" ? aws_instance.bastion[0].public_ip : null
}

# ============================================================================
# INFORMATIONS LOAD BALANCER
# ============================================================================

output "load_balancer_arn" {
  description = "ARN de l'Application Load Balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].arn : null
}

output "load_balancer_dns_name" {
  description = "DNS name de l'Application Load Balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].dns_name : null
}

output "load_balancer_zone_id" {
  description = "Zone ID de l'Application Load Balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].zone_id : null
}

output "api_gateway_target_group_arn" {
  description = "ARN du target group API Gateway"
  value       = var.enable_load_balancer ? aws_lb_target_group.api_gateway[0].arn : null
}

# ============================================================================
# URLS D'ACCÈS
# ============================================================================

output "application_url" {
  description = "URL d'accès à l'application"
  value = var.enable_load_balancer ? (
    var.environment == "prod" ?
    "https://${aws_lb.main[0].dns_name}" :
    "http://${aws_lb.main[0].dns_name}"
  ) : "Load Balancer désactivé"
}

output "kibana_url" {
  description = "URL d'accès à Kibana"
  value = var.enable_load_balancer && var.enable_kibana ? (
    var.environment == "prod" ?
    "https://${aws_lb.main[0].dns_name}/kibana" :
    "http://${aws_lb.main[0].dns_name}/kibana"
  ) : (var.enable_elasticsearch ? "http://${aws_instance.elasticsearch[0].private_ip}:5601" : "Kibana désactivé")
}

output "eureka_dashboard_url" {
  description = "URL d'accès au dashboard Eureka (via tunnel SSH)"
  value       = "http://${aws_instance.eureka_server.private_ip}:8761"
}

output "rabbitmq_management_url" {
  description = "URL d'accès au management RabbitMQ (via tunnel SSH)"
  value       = "http://${aws_instance.config_server.private_ip}:15672"
}

# ============================================================================
# INFORMATIONS DE CONNEXION SSH
# ============================================================================

output "ssh_connection_commands" {
  description = "Commandes pour se connecter en SSH"
  value = {
    bastion = var.environment == "dev" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.bastion[0].public_ip}" : "Bastion non disponible en production"

    config_server = var.environment == "dev" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@${aws_instance.config_server.private_ip}" : "Connexion via Session Manager uniquement"

    eureka_server = var.environment == "dev" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@${aws_instance.eureka_server.private_ip}" : "Connexion via Session Manager uniquement"
  }
}

# ============================================================================
# TUNNELS SSH POUR DÉVELOPPEMENT
# ============================================================================

output "ssh_tunnel_commands" {
  description = "Commandes pour créer des tunnels SSH (dev uniquement)"
  value = var.environment == "dev" ? {
    kibana = "ssh -i ~/.ssh/${var.key_pair_name}.pem -L 5601:${var.enable_elasticsearch ? aws_instance.elasticsearch[0].private_ip : "N/A"}:5601 ubuntu@${aws_instance.bastion[0].public_ip}"

    eureka = "ssh -i ~/.ssh/${var.key_pair_name}.pem -L 8761:${aws_instance.eureka_server.private_ip}:8761 ubuntu@${aws_instance.bastion[0].public_ip}"

    rabbitmq = "ssh -i ~/.ssh/${var.key_pair_name}.pem -L 15672:${aws_instance.config_server.private_ip}:15672 ubuntu@${aws_instance.bastion[0].public_ip}"

    postgresql = "ssh -i ~/.ssh/${var.key_pair_name}.pem -L 5432:${aws_db_instance.postgresql.endpoint}:5432 ubuntu@${aws_instance.bastion[0].public_ip}"
  } : { "message" = "Tunnels SSH disponibles uniquement en développement" }
}

# ============================================================================
# INFORMATIONS GÉNÉRALES
# ============================================================================

output "environment" {
  description = "Environnement de déploiement"
  value       = var.environment
}

output "project_name" {
  description = "Nom du projet"
  value       = var.project_name
}

output "aws_region" {
  description = "Région AWS utilisée"
  value       = var.aws_region
}

output "account_id" {
  description = "ID du compte AWS"
  value       = data.aws_caller_identity.current.account_id
}

# ============================================================================
# INFORMATIONS DE CONFIGURATION
# ============================================================================

output "configuration_summary" {
  description = "Résumé de la configuration déployée"
  value = {
    vpc_cidr              = var.vpc_cidr
    instance_type         = var.instance_type
    database_engine       = "${var.db_engine} ${var.db_engine_version}"
    database_instance     = var.db_instance_class
    load_balancer_enabled = var.enable_load_balancer
    elasticsearch_enabled = var.enable_elasticsearch
    nat_gateway_enabled   = var.enable_nat_gateway
    environment           = var.environment
  }
}

# ============================================================================
# COMMANDES UTILES
# ============================================================================

output "useful_commands" {
  description = "Commandes utiles pour la gestion"
  value = {
    # Connexion à la base de données
    psql_command = "PGPASSWORD='[DB_PASSWORD]' psql -h ${aws_db_instance.postgresql.endpoint} -U ${var.db_username} -d ${var.db_name}"

    # Vérification du statut des services
    health_checks = {
      api_gateway    = "curl http://${aws_instance.api_gateway.private_ip}:8080/actuator/health"
      eureka_server  = "curl http://${aws_instance.eureka_server.private_ip}:8761/actuator/health"
      users_service  = "curl http://${aws_instance.users_service.private_ip}:8081/actuator/health"
      albums_service = "curl http://${aws_instance.albums_service.private_ip}:8082/actuator/health"
    }

    # Logs des services
    log_locations = {
      application_logs = "/var/log/microservices/"
      system_logs      = "/var/log/syslog"
      docker_logs      = "docker logs [container_name]"
    }
  }
}

