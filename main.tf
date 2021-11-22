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
  region = "us-east-1"
}
provider "aws" {
  alias  = "ap"
  region = "ap-northeast-1"
}
provider "aws" {
  alias  = "eu"
  region = "eu-central-1"
}
provider "alicloud" {
  region = var.client_region
}
provider "archive" {}
locals {
  default_port        = 8388
  log_group           = "fanqiang-shadowsocks"
  proxy_instance_name = "shadowsocks-server"
  port_mapping = {
    default = 8527
    ap      = 8528
    eu      = 8529
  }
  shadowsocks_config_url = "https://${aws_s3_bucket.default.bucket_domain_name}/${aws_s3_bucket_object.shadowsocks_cfg.key}"
  awslogs = {
    agent_access_key = module.awslogs.agent_access_key
    region           = data.aws_region.default.name
    group            = local.log_group
  }
}
data "aws_region" "default" {}
resource "aws_s3_bucket" "default" {
  bucket        = var.bucket
  acl           = "public-read"
  force_destroy = true
}
resource "aws_s3_bucket_object" "shadowsocks_cfg" {
  bucket        = aws_s3_bucket.default.bucket
  key           = "shadowsocks/config.json"
  acl           = "public-read"
  force_destroy = true
  content = jsonencode({
    server      = "::"
    server_port = local.default_port
    password    = var.password
    method      = var.encryption_algorithm
  })
}


module "proxy" {
  source                 = "./modules/proxy"
  port                   = local.default_port
  instance_name          = local.proxy_instance_name
  shadowsocks_config_url = local.shadowsocks_config_url
  awslogs                = local.awslogs
  public_key             = var.public_key
}
module "proxy_ap" {
  source                 = "./modules/proxy"
  port                   = local.default_port
  instance_name          = local.proxy_instance_name
  shadowsocks_config_url = local.shadowsocks_config_url
  awslogs                = local.awslogs
  public_key             = var.public_key
  providers = {
    aws = aws.ap
  }
}
module "proxy_eu" {
  source                 = "./modules/proxy"
  port                   = local.default_port
  instance_name          = local.proxy_instance_name
  shadowsocks_config_url = local.shadowsocks_config_url
  awslogs                = local.awslogs
  public_key             = var.public_key
  providers = {
    aws = aws.eu
  }
}
module "awslogs" {
  source     = "./modules/awslogs"
  log_group  = local.log_group
  agent_user = "fanqiang-awslogs-agent"
}
module "tunnel" {
  source = "./modules/tunnel"
  proxies = {
    port = local.default_port
    address_mapping = [
      [module.proxy.public_ip, local.port_mapping.default],
      [module.proxy_ap.public_ip, local.port_mapping.ap],
      [module.proxy_eu.public_ip, local.port_mapping.eu]
    ]
  }
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
      region = data.aws_region.default.name
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
    server       = module.tunnel.public_ip
    cipher       = var.encryption_algorithm
    password     = var.password
    port_mapping = local.port_mapping
  }
}
