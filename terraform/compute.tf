# compute.tf
# Configuration des instances EC2 pour les microservices

# ============================================================================
# AMI DATA SOURCE
# ============================================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================================
# USER DATA TEMPLATES
# ============================================================================

# Template de base pour tous les services
locals {
  base_user_data = base64encode(templatefile("${path.module}/user-data/base-setup.sh", {
    ENVIRONMENT = var.environment
    PROJECT     = var.project_name
    REGION      = var.aws_region
    CPU_USAGE   = ""
    MEMORY_USAGE= ""
    DISK_USAGE= ""
  }))

  # config_server_user_data = base64encode(templatefile("${path.module}/user-data/config-server.sh", {
  #   ENVIRONMENT = var.environment
  #   PROJECT     = var.project_name
  #   DB_ENDPOINT = aws_db_instance.postgresql.endpoint
  # }))
  #
  # eureka_server_user_data = base64encode(templatefile("${path.module}/user-data/eureka-server.sh", {
  #   environment = var.environment
  #   project     = var.project_name
  # }))
  #
  # api_gateway_user_data = base64encode(templatefile("${path.module}/user-data/api-gateway.sh", {
  #   environment     = var.environment
  #   project         = var.project_name
  #   eureka_endpoint = aws_instance.eureka_server.private_ip
  #   config_endpoint = aws_instance.config_server.private_ip
  # }))

  # users_service_user_data = base64encode(templatefile("${path.module}/user-data/users-service.sh", {
  #   environment     = var.environment
  #   project         = var.project_name
  #   db_endpoint     = aws_db_instance.postgresql.endpoint
  #   eureka_endpoint = aws_instance.eureka_server.private_ip
  #   config_endpoint = aws_instance.config_server.private_ip
  # }))
  #
  # albums_service_user_data = base64encode(templatefile("${path.module}/user-data/albums-service.sh", {
  #   environment     = var.environment
  #   project         = var.project_name
  #   db_endpoint     = aws_db_instance.postgresql.endpoint
  #   eureka_endpoint = aws_instance.eureka_server.private_ip
  #   config_endpoint = aws_instance.config_server.private_ip
  # }))

  # elasticsearch_user_data = base64encode(templatefile("${path.module}/user-data/elasticsearch.sh", {
  #   environment = var.environment
  #   project     = var.project_name
  # }))
}

# ============================================================================
# INSTANCE - CONFIG SERVER + RABBITMQ
# ============================================================================

resource "aws_instance" "config_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.microservices.id]
  subnet_id              = aws_subnet.private[0].id
  user_data              = local.base_user_data

  monitoring                  = var.enable_detailed_monitoring
  associate_public_ip_address = false

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.common_prefix}-config-server-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-config-server"
    Type    = "ec2-instance"
    Service = "config-server"
    Tier    = "infrastructure"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INSTANCE - EUREKA SERVER
# ============================================================================

resource "aws_instance" "eureka_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.microservices.id]
  subnet_id              = aws_subnet.private[0].id
  user_data              = local.base_user_data

  monitoring                  = var.enable_detailed_monitoring
  associate_public_ip_address = false

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.common_prefix}-eureka-server-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-eureka-server"
    Type    = "ec2-instance"
    Service = "eureka-server"
    Tier    = "infrastructure"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INSTANCE - API GATEWAY
# ============================================================================

resource "aws_instance" "api_gateway" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.microservices.id]
  subnet_id              = aws_subnet.private[0].id
  user_data              = local.base_user_data

  monitoring                  = var.enable_detailed_monitoring
  associate_public_ip_address = false

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.common_prefix}-api-gateway-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-api-gateway"
    Type    = "ec2-instance"
    Service = "api-gateway"
    Tier    = "application"
  })

  depends_on = [aws_instance.eureka_server, aws_instance.config_server]

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INSTANCE - USERS SERVICE
# ============================================================================

resource "aws_instance" "users_service" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.microservices.id]
  subnet_id              = aws_subnet.private[1].id
  user_data              = local.base_user_data

  monitoring                  = var.enable_detailed_monitoring
  associate_public_ip_address = false

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.common_prefix}-users-service-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-users-service"
    Type    = "ec2-instance"
    Service = "users-service"
    Tier    = "application"
  })

  depends_on = [aws_instance.eureka_server, aws_instance.config_server, aws_db_instance.postgresql]

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INSTANCE - ALBUMS SERVICE
# ============================================================================

resource "aws_instance" "albums_service" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.microservices.id]
  subnet_id              = aws_subnet.private[1].id
  user_data              = local.base_user_data

  monitoring                  = var.enable_detailed_monitoring
  associate_public_ip_address = false

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.common_prefix}-albums-service-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-albums-service"
    Type    = "ec2-instance"
    Service = "albums-service"
    Tier    = "application"
  })

  depends_on = [aws_instance.eureka_server, aws_instance.config_server, aws_db_instance.postgresql]

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INSTANCE - ELASTICSEARCH & KIBANA
# ============================================================================

resource "aws_instance" "elasticsearch" {
  count = var.enable_elasticsearch ? 1 : 0

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.elasticsearch.id]
  subnet_id              = aws_subnet.private[0].id
  user_data              = local.base_user_data

  monitoring                  = var.enable_detailed_monitoring
  associate_public_ip_address = false

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = 30 # Plus d'espace pour Elasticsearch
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.common_prefix}-elasticsearch-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-elasticsearch"
    Type    = "ec2-instance"
    Service = "elasticsearch"
    Tier    = "monitoring"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# BASTION HOST (optionnel pour le développement)
# ============================================================================

resource "aws_instance" "bastion" {
  count = var.environment == "dev" ? 1 : 0

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.nano" # Plus petit pour économiser
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  subnet_id              = aws_subnet.public[0].id
  user_data              = local.base_user_data

  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.common_prefix}-bastion-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-bastion"
    Type    = "ec2-instance"
    Service = "bastion"
    Tier    = "management"
  })

  lifecycle {
    create_before_destroy = true
  }
}
