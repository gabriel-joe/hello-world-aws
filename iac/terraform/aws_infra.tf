# Configure AWS Provider
provider "aws" {
  region = var.aws_region  # Update with your desired region
}

locals {
  app_name      = "hello-world-aws"
}

# VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = false
}

resource "aws_ecr_repository" "ecr_image_repository" {
  name                 = local.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name = "alb-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol = "tcp"
  }
}

resource "aws_security_group" "private_sg" {
  name = "private-subnet-security-group"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_alb" {
  security_group_id = aws_security_group.private_sg.id

  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_security_group" "postgresql_sg" {
  name = "postgresql-security-group"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_app" {
  security_group_id = aws_security_group.postgresql_sg.id

  referenced_security_group_id = aws_security_group.private_sg.id
  from_port   = 5432
  ip_protocol = "tcp"
  to_port     = 5432
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name         = "${local.app_name}-lb"
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets        = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]  # Public subnet for ALB
}

resource "aws_lb_target_group" "app_target_group" {
  name     = "${local.app_name}-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.main.id
}


resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "hello_world_cluster"
}

# IAM role for task definition
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  inline_policy {
    name = "ecs-task-execution-policy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family = "hello-world-definition"

  cpu    = var.ecs_container_cpu
  memory = var.ecs_container_memory
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "hello-world-aws"
      image     = "${aws_ecr_repository.ecr_image_repository.repository_url}:latest"
      cpu       = 1
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}


# ECS Task Definition
resource "aws_ecs_task_definition" "postgresql" {
  family = "postgresql"

  cpu    = var.ecs_container_cpu
  memory = var.ecs_container_memory
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "postgresql"
      image     = "postgresql"
      cpu       = 1
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 5432
          hostPort      = 5432
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name = "${local.app_name}"
  cluster = aws_ecs_cluster.app_cluster.arn
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.app_task.arn
  force_new_deployment = true
  network_configuration {
    subnets = [aws_subnet.subnet_b.id] #Private subnet
    security_groups = [aws_security_group.private_sg.id]
  }

  desired_count = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name    = local.app_name
    container_port    = 80  # Replace with your application port
  }

}


resource "aws_ecs_service" "postgresql" {
  name = "postgreqsl-ecs"
  cluster = aws_ecs_cluster.app_cluster.arn
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.postgresql.arn
  network_configuration {
    subnets = [aws_subnet.subnet_b.id] #Private subnet
    security_groups = [aws_security_group.postgresql_sg.id]
  }

  desired_count = 2
}