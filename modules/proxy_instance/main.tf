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
  name              = var.config.instance_name
  key_pair_name     = var.public_key != null ? aws_lightsail_key_pair.default[0].id : null
  user_data = templatefile("${path.module}/cloud-init.tpl", {
    shadowsocks_config_url = var.config.shadowsocks_config_url
    log_group              = var.config.log_group
    agent_user             = var.config.agent_user
  })
}
resource "aws_lightsail_instance_public_ports" "default" {
  instance_name = aws_lightsail_instance.default.name

  dynamic "port_info" {
    for_each = var.public_key != null ? [var.config.port, 22] : [var.config.port]
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

