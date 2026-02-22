terraform {
  backend "s3" {
    bucket  = "terraform-backend-ak"
    key     = "strapi/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}

################################
# VPC
################################

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

################################
# SECURITY
################################

module "security" {
  source       = "./modules/security"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
}

################################
# ECR
################################

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

################################
# IAM (Execution Role)
################################

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

################################
# ALB
################################

module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

################################
# RDS (PRIVATE SUBNETS)
################################

module "rds" {
  source = "./modules/rds"

  project_name = var.project_name

  # IMPORTANT: private subnets
  subnet_ids = module.vpc.private_subnet_ids

  rds_sg_id  = module.security.rds_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

################################
# ECS (PRIVATE + ALB ATTACHED)
################################

module "ecs" {
  source = "./modules/ecs"

  project_name = var.project_name

  # PRIVATE subnets
  subnet_ids = module.vpc.private_subnet_ids
  ecs_sg_id  = module.security.ecs_sg_id

  # ALB integration
  target_group_arn = module.alb.target_group_arn

  # ECR image (latest tag from CI/CD)
  image_uri = var.image_uri

  # Database
  db_endpoint = module.rds.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # IAM execution role
  execution_role_arn = module.iam.execution_role_arn

  # Region
  aws_region = var.aws_region
}