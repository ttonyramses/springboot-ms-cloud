# networking.tf
# Configuration de l'infrastructure réseau

# ============================================================================
# VPC PRINCIPAL
# ============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-vpc"
    Type = "vpc"
  })
}

# ============================================================================
# INTERNET GATEWAY
# ============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-igw"
    Type = "internet-gateway"
  })
}

# ============================================================================
# SUBNETS PUBLICS
# ============================================================================

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    Tier = "public"
    AZ   = local.availability_zones[count.index]
  })
}

# ============================================================================
# SUBNETS PRIVÉS
# ============================================================================

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-private-subnet-${count.index + 1}"
    Type = "private-subnet"
    Tier = "private"
    AZ   = local.availability_zones[count.index]
  })
}

# ============================================================================
# SUBNETS BASE DE DONNÉES
# ============================================================================

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-database-subnet-${count.index + 1}"
    Type = "database-subnet"
    Tier = "database"
    AZ   = local.availability_zones[count.index]
  })
}

# ============================================================================
# ELASTIC IP POUR NAT GATEWAY (si activée)
# ============================================================================

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
  })
}

# ============================================================================
# NAT GATEWAY (si activée)
# ============================================================================

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# TABLE DE ROUTAGE PUBLIQUE
# ============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-public-rt"
    Type = "route-table"
    Tier = "public"
  })
}

# ============================================================================
# ASSOCIATION SUBNETS PUBLICS - TABLE DE ROUTAGE
# ============================================================================

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# TABLES DE ROUTAGE PRIVÉES
# ============================================================================

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  # Route vers NAT Gateway si activée
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
  })
}

# ============================================================================
# ASSOCIATION SUBNETS PRIVÉS - TABLES DE ROUTAGE
# ============================================================================

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ============================================================================
# TABLE DE ROUTAGE BASE DE DONNÉES
# ============================================================================

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-database-rt"
    Type = "route-table"
    Tier = "database"
  })
}

# ============================================================================
# ASSOCIATION SUBNETS BASE DE DONNÉES - TABLE DE ROUTAGE
# ============================================================================

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# ============================================================================
# DB SUBNET GROUP
# ============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${local.common_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-db-subnet-group"
    Type = "db-subnet-group"
  })
}

# ============================================================================
# VPC ENDPOINTS (optionnels pour optimiser les coûts et la sécurité)
# ============================================================================

# Endpoint S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], aws_route_table.private[*].id)

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-s3-endpoint"
    Type = "vpc-endpoint"
  })
}

# Endpoint EC2
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-ec2-endpoint"
    Type = "vpc-endpoint"
  })
}

# ============================================================================
# NACL (Network ACLs) pour sécurité supplémentaire
# ============================================================================

resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  # Autoriser le trafic PostgreSQL depuis les subnets privés
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = local.service_ports.postgresql
    to_port    = local.service_ports.postgresql
  }

  # Autoriser les réponses
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-database-nacl"
    Type = "network-acl"
  })
}

