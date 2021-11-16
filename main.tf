terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.134.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
  }
}
provider "aws" {
  region = var.proxy_region
}
provider "alicloud" {
  region = var.tunnel_region
}
provider "archive" {}

locals {
  log_group = "fanqiang-shadowsocks"
}

module "awslogs" {
  source     = "./modules/awslogs"
  log_group  = local.log_group
  agent_user = "fanqiang-awslogs-agent"
}
module "proxy" {
  source               = "./modules/proxy"
  port                 = var.port
  encryption_algorithm = var.encryption_algorithm
  password             = var.password
  instance_name        = "shadowsocks-server"
  awslogs = {
    agent_access_key = module.awslogs.agent_access_key
    region           = var.proxy_region
    group            = local.log_group
  }
  public_key = var.public_key
}
module "tunnel" {
  source               = "./modules/tunnel"
  proxy_port           = var.port
  proxy_public_ip      = module.proxy.public_ip
  public_key           = var.public_key
  ram_role_name        = "FangqiangEcsEipAccessRole"
  launch_template_name = "fanqiang-nginx"
  s3                   = aws_s3_bucket.default
}
module "rules" {
  source            = "./modules/rules"
  domain_table_name = "domains"
  ping_service = {
    function_name      = "ping"
    ram_role_name      = "FangqiangFcInvokeAccessRole"
    service_name       = "fanqiang"
    timeout_in_seconds = var.domain_access_timeout_in_seconds
  }
  process_shadowsocks_logs_service = {
    log_filter_name = "fanqiang-shadowsocks-connection-establish"
    log_group = {
      name   = local.log_group
      arn    = module.awslogs.arn
      region = var.proxy_region
    }
    name = "fanqiang-process-shadowsocks-logs"
    clash_rule_storage = {
      bucket      = aws_s3_bucket.default.id
      object_path = module.clash.rule_path
    }
  }
}
module "clash" {
  source = "./modules/clash"
  s3     = aws_s3_bucket.default
  client_config = {
    server   = module.tunnel.public_ip
    port     = var.port
    cipher   = var.encryption_algorithm
    password = var.password
  }
}

resource "aws_s3_bucket" "default" {
  bucket        = var.bucket
  acl           = "public-read"
  force_destroy = true
}
