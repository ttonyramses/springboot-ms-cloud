# main.tf
# Configuration principale du projet microservices

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  # Backend S3 pour l'état distant (décommentez après avoir créé le bucket)
  # backend "s3" {
  #   bucket         = "terraform-state-microservices-dev"
  #   key            = "microservices/terraform.tfstate"
  #   region         = "eu-west-3"
  #   dynamodb_table = "terraform-lock-microservices"
  #   encrypt        = true
  # }
}

# Configuration du provider AWS
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
      CreatedDate = timestamp()
    }
  }
}

# Provider pour les ressources aléatoires
provider "random" {}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Génération d'un suffixe aléatoire pour les ressources globales
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

