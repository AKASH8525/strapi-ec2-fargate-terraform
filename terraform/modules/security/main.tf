# ------------------------------------
# Random suffix to avoid duplicate names
# ------------------------------------

resource "random_id" "suffix" {
  byte_length = 2
}

# ------------------------------------
# ECS Security Group (Fargate)
# ------------------------------------

resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg-${random_id.suffix.hex}"
  description = "Security group for ECS Fargate"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP to Strapi"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# ------------------------------------
# RDS Security Group
# ------------------------------------

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg-${random_id.suffix.hex}"
  description = "Security group for RDS Postgres"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow Postgres from ECS only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
