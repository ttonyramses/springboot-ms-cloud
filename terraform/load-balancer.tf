# load-balancer.tf
# Configuration de l'Application Load Balancer

# ============================================================================
# APPLICATION LOAD BALANCER
# ============================================================================

resource "aws_lb" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name               = "${substr(local.common_prefix, 0, 20)}-alb"
  internal           = false
  load_balancer_type = var.load_balancer_type
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  # Logs d'accès (optionnel)
  # access_logs {
  #   bucket  = aws_s3_bucket.alb_logs[0].bucket
  #   prefix  = "alb-logs"
  #   enabled = var.environment == "prod"
  # }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-alb"
    Type = "application-load-balancer"
    Tier = "public"
  })

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# ============================================================================
# S3 BUCKET POUR LES LOGS ALB
# ============================================================================

resource "aws_s3_bucket" "alb_logs" {
  count = var.enable_load_balancer && var.environment == "prod" ? 1 : 0

  bucket        = "${local.common_prefix}-alb-logs-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-alb-logs"
    Type = "s3-bucket"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count = var.enable_load_balancer && var.environment == "prod" ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "alb_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = "alb-logs/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count = var.enable_load_balancer && var.environment == "prod" ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      }
    ]
  })
}

# Data source pour l'account ELB
data "aws_elb_service_account" "main" {}

# ============================================================================
# LISTENER HTTP (redirection vers HTTPS)
# ============================================================================

resource "aws_lb_listener" "http" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-alb-http-listener"
    Type = "alb-listener"
  })
}

# ============================================================================
# LISTENER HTTPS (si certificat SSL disponible)
# ============================================================================

resource "aws_lb_listener" "https" {
  count = var.enable_load_balancer && var.environment == "prod" ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway[0].arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-alb-https-listener"
    Type = "alb-listener"
  })
}

# ============================================================================
# LISTENER HTTP SIMPLE (pour dev/staging)
# ============================================================================

resource "aws_lb_listener" "http_simple" {
  count = var.enable_load_balancer && var.environment != "prod" ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway[0].arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-alb-http-simple-listener"
    Type = "alb-listener"
  })
}

# ============================================================================
# TARGET GROUPS
# ============================================================================

# Target Group pour API Gateway
resource "aws_lb_target_group" "api_gateway" {
  count = var.enable_load_balancer ? 1 : 0

  name     = "${substr(local.common_prefix, 0, 20)}-api-gw-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Sticky sessions
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = merge(local.common_tags, {
    Name    = "${local.common_prefix}-api-gw-tg"
    Type    = "target-group"
    Service = "api-gateway"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group pour Kibana
resource "aws_lb_target_group" "kibana" {
  count = var.enable_load_balancer && var.enable_kibana ? 1 : 0

  name     = "${substr(local.common_prefix, 0, 20)}-kibana-tg"
  port     = 5601
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/app/kibana"
    matcher             = "200,302"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(local.common_tags, {
    Name    = "${substr(local.common_prefix, 0, 20)}-kibana-tg"
    Type    = "target-group"
    Service = "kibana"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# TARGET GROUP ATTACHMENTS
# ============================================================================

resource "aws_lb_target_group_attachment" "api_gateway" {
  count = var.enable_load_balancer ? 1 : 0

  target_group_arn = aws_lb_target_group.api_gateway[0].arn
  target_id        = aws_instance.api_gateway.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "kibana" {
  count = var.enable_load_balancer && var.enable_kibana && var.enable_elasticsearch ? 1 : 0

  target_group_arn = aws_lb_target_group.kibana[0].arn
  target_id        = aws_instance.elasticsearch[0].id
  port             = 5601
}

# ============================================================================
# LISTENER RULES POUR ROUTING
# ============================================================================

# Route pour Kibana
resource "aws_lb_listener_rule" "kibana" {
  count = var.enable_load_balancer && var.enable_kibana ? 1 : 0

  listener_arn = var.environment == "prod" ? aws_lb_listener.https[0].arn : aws_lb_listener.http_simple[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana[0].arn
  }

  condition {
    path_pattern {
      values = ["/kibana*", "/app/*", "/api/*", "/bundles/*"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-kibana-rule"
    Type = "alb-listener-rule"
  })
}

# Route pour RabbitMQ Management (dev uniquement)
resource "aws_lb_listener_rule" "rabbitmq" {
  count = var.enable_load_balancer && var.environment == "dev" ? 1 : 0

  listener_arn = aws_lb_listener.http_simple[0].arn
  priority     = 200

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "RabbitMQ Management - Access via SSH tunnel"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/rabbitmq*"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-rabbitmq-rule"
    Type = "alb-listener-rule"
  })
}

# ============================================================================
# CERTIFICAT SSL/TLS (pour production)
# ============================================================================

resource "aws_acm_certificate" "main" {
  count = var.enable_load_balancer && var.environment == "prod" ? 1 : 0

  domain_name       = "microservices.${var.project_name}.com" # À adapter selon votre domaine
  validation_method = "DNS"

  subject_alternative_names = [
    "*.microservices.${var.project_name}.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.common_prefix}-ssl-certificate"
    Type = "acm-certificate"
  })
}

# ============================================================================
# ROUTE 53 POUR LA VALIDATION DU CERTIFICAT (optionnel)
# ============================================================================

# resource "aws_route53_zone" "main" {
#   count = var.enable_load_balancer && var.environment == "prod" ? 1 : 0
#
#   name = "microservices.${var.project_name}.com"
#
#   tags = merge(local.common_tags, {
#     Name = "${local.common_prefix}-dns-zone"
#     Type = "route53-zone"
#   })
# }

# ============================================================================
# CLOUDWATCH ALARMS POUR ALB
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  count = var.enable_load_balancer ? 1 : 0

  alarm_name          = "${substr(local.common_prefix, 0, 20)}-alb-target-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ALB target response time"

  dimensions = {
    LoadBalancer = aws_lb.main[0].arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-alb-response-time-alarm"
    Type = "cloudwatch-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.enable_load_balancer ? 1 : 0

  alarm_name          = "${substr(local.common_prefix, 0, 20)}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors ALB unhealthy hosts"

  dimensions = {
    TargetGroup  = aws_lb_target_group.api_gateway[0].arn_suffix
    LoadBalancer = aws_lb.main[0].arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${substr(local.common_prefix, 0, 20)}-alb-unhealthy-hosts-alarm"
    Type = "cloudwatch-alarm"
  })
}
