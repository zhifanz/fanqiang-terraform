terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

locals {
  cidr_block = "192.168.0.0"
}

resource "aws_vpc" "default" {
  cidr_block = "${local.cidr_block}/16"
}
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}
resource "aws_route" "gateway" {
  route_table_id = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.default.id
}
resource "aws_subnet" "default" {
  cidr_block = "${local.cidr_block}/24"
  vpc_id = aws_vpc.default.id
  map_public_ip_on_launch = true
}
resource "aws_security_group_rule" "default" {
  from_port = var.port
  to_port = var.port
  protocol = "tcp"
  security_group_id = aws_vpc.default.default_security_group_id
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_ecs_cluster" "default" {
  name = var.service_name
}
resource "aws_ecs_service" "default" {
  name = var.service_name
  cluster = aws_ecs_cluster.default.arn
  desired_count = 1
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.default.arn
  network_configuration {
    subnets = [aws_subnet.default.id]
    assign_public_ip = true
  }
  wait_for_steady_state = true
}
resource "aws_ecs_task_definition" "default" {
  container_definitions = jsonencode([
    {
      name = "shadowsocks-server-rust"
      image = "zhifanz/ssserver-rust:1.0.0"
      command = ["-s", "[::]:${var.port}", "-m", var.encryption_algorithm, "-k", var.password, "--log-without-time", "-v"]
      portMappings = [{
        containerPort = var.port
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.default.name
          awslogs-region = data.aws_region.default.name
          awslogs-stream-prefix = var.service_name
        }
      }
    }
  ])
  execution_role_arn = aws_iam_role.default.arn
  family = "shadowsocks-server-rust"
  cpu = "256"
  memory = "512"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}
resource "aws_iam_role" "default" {
  name_prefix = "ecsTaskExecutionRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  force_detach_policies = true
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement= [
      {
        Sid = ""
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "default" {
  name = var.log_group_name
  retention_in_days = 1
}

data "aws_network_interface" "default" {
  filter {
    name = "subnet-id"
    values = [aws_subnet.default.id]
  }
  depends_on = [aws_ecs_service.default]
}
data "aws_region" "default" {}

