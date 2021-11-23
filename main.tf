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
    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
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
provider "external" {}
locals {
  port_mapping = {
    default = 8527
    ap      = 8528
    eu      = 8529
  }
  proxy_instance_constants = {
    instance_name   = "shadowsocks-server"
    port            = 8388
    agent_user_name = "fanqiang-awslogs-agent"
    log_group_name  = "fanqiang-shadowsocks"
  }
  proxy_instance_config = {
    instance_name          = local.proxy_instance_constants.instance_name
    port                   = local.proxy_instance_constants.port
    shadowsocks_config_url = module.proxy_common.shadowsocks_config_url
    agent_user = {
      name       = local.proxy_instance_constants.agent_user_name
      access_key = module.proxy_common.agent_access_key
    }
    log_group = {
      name   = local.proxy_instance_constants.log_group_name
      region = data.aws_region.default.name
      arn    = module.proxy_common.log_group_arn
    }
  }
}
data "aws_region" "default" {}
resource "aws_s3_bucket" "default" {
  bucket        = var.bucket
  force_destroy = true
}
module "proxy_common" {
  source               = "./modules/proxy_common"
  s3                   = aws_s3_bucket.default
  port                 = local.proxy_instance_constants.port
  password             = var.password
  encryption_algorithm = var.encryption_algorithm
  log_group            = local.proxy_instance_constants.log_group_name
  agent_user           = local.proxy_instance_constants.agent_user_name
}
module "proxy_instance" {
  source     = "./modules/proxy_instance"
  config     = local.proxy_instance_config
  public_key = var.public_key
}
module "proxy_instance_ap" {
  source     = "./modules/proxy_instance"
  config     = local.proxy_instance_config
  public_key = var.public_key
  providers = {
    aws = aws.ap
  }
}
module "proxy_instance_eu" {
  source     = "./modules/proxy_instance"
  config     = local.proxy_instance_config
  public_key = var.public_key
  providers = {
    aws = aws.eu
  }
}
module "tunnel" {
  source = "./modules/tunnel"
  proxies = {
    port = local.proxy_instance_config.port
    address_mapping = [
      [module.proxy_instance.public_ip, local.port_mapping.default],
      [module.proxy_instance_ap.public_ip, local.port_mapping.ap],
      [module.proxy_instance_eu.public_ip, local.port_mapping.eu]
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
    log_group       = local.proxy_instance_config.log_group
    name            = "fanqiang-process-shadowsocks-logs"
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
