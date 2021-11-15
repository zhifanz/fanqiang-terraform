terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

resource "aws_lightsail_instance" "default" {
  availability_zone = data.aws_availability_zones.default.names[0]
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_2_0"
  name              = var.instance_name
  key_pair_name     = var.public_key != null ? aws_lightsail_key_pair.default[0].id : null
  user_data = templatefile("${path.module}/cloud-init.tpl", {
    port                  = var.port
    encryption_algorithm  = var.encryption_algorithm
    password              = var.password
    aws_access_key_id     = var.awslogs != null ? var.awslogs.agent_access_key.id : ""
    aws_secret_access_key = var.awslogs != null ? var.awslogs.agent_access_key.secret : ""
    awslogs_region        = var.awslogs != null ? var.awslogs.region : ""
    awslogs_group         = var.awslogs != null ? var.awslogs.group : ""
    awslogs_stream        = data.aws_region.default.name
  })
}
resource "aws_lightsail_instance_public_ports" "default" {
  instance_name = aws_lightsail_instance.default.name

  dynamic "port_info" {
    for_each = var.public_key != null ? [var.port, 22] : [var.port]
    content {
      protocol  = "tcp"
      from_port = port_info.value
      to_port   = port_info.value
    }
  }
}
resource "aws_lightsail_key_pair" "default" {
  count      = var.public_key != null ? 1 : 0
  public_key = var.public_key
}
data "aws_availability_zones" "default" {
  state = "available"
}
data "aws_region" "default" {}
