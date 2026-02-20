terraform {
  backend "s3" {
    bucket  = "terraform-backend-ak"
    key     = "strapi/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

############################
# Use Existing VPC
############################

data "aws_vpc" "selected" {
  id = "vpc-02394aac3f6ed622b"
}

############################
# Create Public Subnets
############################

resource "aws_subnet" "public_1" {
  vpc_id                  = data.aws_vpc.selected.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = data.aws_vpc.selected.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

############################
# Create Route Table
############################

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "igw-0467821153a534d5f"
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

############################
# Security Groups
############################

module "security" {
  source       = "./modules/security"
  vpc_id       = data.aws_vpc.selected.id
  project_name = "strapi"
}

############################
# ECR
############################

module "ecr" {
  source       = "./modules/ecr"
  project_name = "strapi"
}

############################
# RDS
############################

module "rds" {
  source = "./modules/rds"

  project_name = "strapi"

  subnet_ids = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  rds_sg_id  = module.security.rds_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

############################
# ECS FARGATE
############################

module "ecs" {
  source       = "./modules/ecs"
  project_name = "strapi"

  subnet_ids = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  ecs_sg_id  = module.security.ecs_sg_id
  image_uri  = var.image_uri

  db_endpoint = module.rds.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  execution_role_arn = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"
}