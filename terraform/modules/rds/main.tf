# ------------------------------
# DB Subnet Group
# ------------------------------

resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group-${random_id.suffix.hex}"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}


# ------------------------------
# RDS Postgres Instance
# ------------------------------

resource "aws_db_instance" "this" {
  identifier        = "strapi-postgres"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  publicly_accessible = false
  multi_az            = false

  skip_final_snapshot = true

  tags = {
    Name = "strapi-postgres"
  }
}
