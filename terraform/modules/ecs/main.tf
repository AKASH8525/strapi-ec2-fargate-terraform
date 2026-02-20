# -----------------------------------
# ECS Cluster
# -----------------------------------

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

# -----------------------------------
# CloudWatch Log Group
# -----------------------------------

resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/${var.project_name}-akash"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-log-group"
  }
}

# -----------------------------------
# Task Definition (FARGATE)
# -----------------------------------

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "512"
  memory = "1024"

  execution_role_arn = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.image_uri
      essential = true

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "HOST", value = "0.0.0.0" },
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = var.db_endpoint },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USERNAME", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ])

  depends_on = [
    aws_cloudwatch_log_group.strapi
  ]
}

# -----------------------------------
# ECS Service (FARGATE)
# -----------------------------------

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service-v5"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  propagate_tags = "SERVICE"

  depends_on = [
    aws_ecs_task_definition.this
  ]
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "${var.project_name}-ecs-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0
        y = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-service-v5"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-service-v5"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "CPU and Memory Utilization"
        }
      },
      {
        type = "metric"
        x = 0
        y = 7
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-service-v5"],
            ["AWS/ECS", "NetworkRxBytes", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-service-v5"],
            ["AWS/ECS", "NetworkTxBytes", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-service-v5"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Task Count and Network Metrics"
        }
      }
    ]
  })
}