# security-groups.tf
# Configuration des groupes de sécurité

# ============================================================================
# SECURITY GROUP - APPLICATION LOAD BALANCER
# ============================================================================

resource "aws_security_group" "alb" {
  name_prefix = "${local.common_prefix}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = local.service_ports.http
    to_port     = local.service_ports.http
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = local.service_ports.https
    to_port     = local.service_ports.https
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-alb-sg"
    Type = "security-group"
    Tier = "public"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - MICROSERVICES (EC2)
# ============================================================================

resource "aws_security_group" "microservices" {
  name_prefix = "${local.common_prefix}-microservices-"
  description = "Security group for microservices instances"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = local.service_ports.ssh
    to_port     = local.service_ports.ssh
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # Trafic depuis ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 8000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Communication inter-services
  ingress {
    description = "Inter-service communication"
    from_port   = 8000
    to_port     = 9000
    protocol    = "tcp"
    self        = true
  }

  # Eureka Server
  ingress {
    description = "Eureka Server"
    from_port   = 8761
    to_port     = 8761
    protocol    = "tcp"
    self        = true
  }

  # Config Server
  ingress {
    description = "Config Server"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    self        = true
  }

  # RabbitMQ
  ingress {
    description = "RabbitMQ"
    from_port   = local.service_ports.rabbitmq
    to_port     = local.service_ports.rabbitmq
    protocol    = "tcp"
    self        = true
  }

  # RabbitMQ Management
  ingress {
    description = "RabbitMQ Management"
    from_port   = local.service_ports.rabbitmq_management
    to_port     = local.service_ports.rabbitmq_management
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-microservices-sg"
    Type = "security-group"
    Tier = "private"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - ELASTICSEARCH & KIBANA
# ============================================================================

resource "aws_security_group" "elasticsearch" {
  name_prefix = "${local.common_prefix}-elasticsearch-"
  description = "Security group for Elasticsearch and Kibana"
  vpc_id      = aws_vpc.main.id

  # Elasticsearch HTTP
  ingress {
    description     = "Elasticsearch HTTP"
    from_port       = local.service_ports.elasticsearch
    to_port         = local.service_ports.elasticsearch
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices.id]
  }

  # Elasticsearch Transport
  ingress {
    description     = "Elasticsearch Transport"
    from_port       = local.service_ports.elasticsearch_transport
    to_port         = local.service_ports.elasticsearch_transport
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices.id]
  }

  # Kibana
  ingress {
    description = "Kibana"
    from_port   = local.service_ports.kibana
    to_port     = local.service_ports.kibana
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  # Logstash
  ingress {
    description     = "Logstash"
    from_port       = local.service_ports.logstash
    to_port         = local.service_ports.logstash
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices.id]
  }

  # SSH
  ingress {
    description = "SSH"
    from_port   = local.service_ports.ssh
    to_port     = local.service_ports.ssh
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-elasticsearch-sg"
    Type = "security-group"
    Tier = "private"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - RDS
# ============================================================================

resource "aws_security_group" "rds" {
  name_prefix = "${local.common_prefix}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL depuis les microservices
  ingress {
    description     = "PostgreSQL from microservices"
    from_port       = local.service_ports.postgresql
    to_port         = local.service_ports.postgresql
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices.id]
  }

  # PostgreSQL depuis le bastion (si nécessaire pour le debug)
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = local.service_ports.postgresql
    to_port     = local.service_ports.postgresql
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-rds-sg"
    Type = "security-group"
    Tier = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - VPC ENDPOINTS
# ============================================================================

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.common_prefix}-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # HTTPS pour les endpoints
  ingress {
    description = "HTTPS for VPC endpoints"
    from_port   = local.service_ports.https
    to_port     = local.service_ports.https
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-vpc-endpoints-sg"
    Type = "security-group"
    Tier = "private"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - BASTION HOST (optionnel)
# ============================================================================

resource "aws_security_group" "bastion" {
  count = var.environment == "dev" ? 1 : 0

  name_prefix = "${local.common_prefix}-bastion-"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  # SSH depuis l'extérieur
  ingress {
    description = "SSH"
    from_port   = local.service_ports.ssh
    to_port     = local.service_ports.ssh
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-bastion-sg"
    Type = "security-group"
    Tier = "public"
  })

  lifecycle {
    create_before_destroy = true
  }
}