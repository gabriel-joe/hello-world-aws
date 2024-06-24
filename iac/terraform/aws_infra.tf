# Configure AWS Provider
provider "aws" {
  region = var.aws_region  # Update with your desired region
}

locals {
  app_name      = "hello-world-aws"
}

########################################################
############# NETWORK INFRA ############################
########################################################

# VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_route_table" "route_private" {
  vpc_id = aws_vpc.main.id

  route {
     cidr_block = "0.0.0.0/0"
     nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table" "route_public" {
  vpc_id = aws_vpc.main.id

  route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.ig_gateway.id
  }
}

resource "aws_internet_gateway" "ig_gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "nat_gateway" {
  connectivity_type                  = "private"
  subnet_id                          = aws_subnet.subnet_a.id
  secondary_private_ip_address_count = 7
}

resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "subnet_public_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_public.id
}

resource "aws_route_table_association" "subnet_private_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.route_private.id
}

########################################################
########################################################

########################################################
#################### SECURITY AND ROLES ################
########################################################


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

resource "aws_vpc_security_group_egress_rule" "egress_rule_for_security" {
  security_group_id = aws_security_group.postgresql_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}


resource "aws_security_group" "alb_sg" {
  name = "alb-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port   = 80
    protocol = "tcp"
  }
}
########################################################
################# CONTAINER INFRA ######################
########################################################

resource "aws_ecr_repository" "ecr_image_repository" {
  name                 = local.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_service_discovery_private_dns_namespace" "service_discovery_dns" {
  name        = "service-discovery-dns-namespace"
  description = "Service discovery namespace for ecs cluster"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "postgresql_service_discovery" {
  name = "postgresql-discovery"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.service_discovery_dns.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
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
      image     = "${aws_ecr_repository.ecr_image_repository.repository_url}:${var.ecs_app_hello_world_tag}"
      cpu       = 1
      memory    = 512
      essential = true
      environment = [
        {
            "name": "SPRING_DATASOURCE_URL", 
            "value": "jdbc:postgresql://postgresql-discovery.service-discovery-dns-namespace:5432/database"
        },
        {
            "name": "SPRING_DATASOURCE_USERNAME", 
            "value": "postgres"
        },
        {
            "name": "SPRING_DATASOURCE_PASSWORD", 
            "value": "password" ### Should come from system parameter store or secret manager
        },
      ]
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
      environment = [
        {
            "name": "POSTGRES_USER", 
            "value": "postgres"
        },
        {
            "name": "POSTGRES_PASSWORD", 
            "value": "password" ### Should come from system parameter store or secret manager
        },
        {
            "name": "POSTGRES_DB", 
            "value": "database"
        }
      ]
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
    assign_public_ip = true
  }

  desired_count = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name    = local.app_name
    container_port    = 80 
  }

}

resource "aws_ecs_service" "postgresql" {
  name = "postgreqsl-ecs"
  cluster = aws_ecs_cluster.app_cluster.arn
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.postgresql.arn
  network_configuration {
    subnets = [aws_subnet.subnet_b.id]
    security_groups = [aws_security_group.postgresql_sg.id]
    assign_public_ip = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.postgresql_service_discovery.arn
    #port = 5432
    #container_port = 5432
    container_name = "postgresql"
  }

  desired_count = 2
}

#######################################
######### Load Balancer ###############
#######################################

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

