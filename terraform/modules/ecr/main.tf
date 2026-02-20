resource "aws_ecr_repository" "this" {
  name                 = "strapi-fargate-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "strapi-fargate-repo"
  }
}
