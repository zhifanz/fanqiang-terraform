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
provider "external" {}
locals {
  port_mapping = {
    default = 8527
    ap      = 8528
    eu      = 8529
  }
  agent_user = "fanqiang-agent"

  proxy = {
    instance_name = "shadowsocks-server"
    port          = 8388
    log_group     = "fanqiang-shadowsocks"
  }
  rule_analysis = {
    dynamodb_table = "domains"
    days_to_scan   = 30
    ping_count     = 10
    update_interval = "10 minutes"
    config_root_path = "clash"
  }
}
data "aws_region" "default" {}

module "common" {
  source     = "./modules/common"
  agent_user = local.agent_user
  bucket     = var.bucket
  shadowsocks = {
    server_port = local.proxy.port
    password    = var.password
    method      = var.encryption_algorithm
  }
}
module "proxy_instance" {
  source        = "./modules/proxy_template"
  instance_name = local.proxy.instance_name
  port          = local.proxy.port
  shadowsocks_config_uri = module.common.shadowsocks_config_uri
  agent_user = {
    name = local.agent_user
    access_key = module.common.agent_access_key
  }
  rule_analysis = {
    days_to_scan   = local.rule_analysis.days_to_scan
    ping_count     = local.rule_analysis.ping_count
    dynamodb_table = local.rule_analysis.dynamodb_table
    image_uri = "zhifanz/fanqiang-update-ping:1.0.0"
  }
  public_key = var.public_key
  log_group  = local.proxy.log_group
}
module "proxy_instance_ap" {
  source        = "./modules/proxy_template"
  instance_name = local.proxy.instance_name
  port          = local.proxy.port
  shadowsocks_config_uri = module.common.shadowsocks_config_uri
  agent_user = {
    name = local.agent_user
    access_key = module.common.agent_access_key
  }
  rule_analysis = {
    days_to_scan   = local.rule_analysis.days_to_scan
    ping_count     = local.rule_analysis.ping_count
    dynamodb_table = local.rule_analysis.dynamodb_table
    image_uri = "zhifanz/fanqiang-update-ping:1.0.0"
  }
  public_key = var.public_key
  providers = {
    aws = aws.ap
  }
}
module "proxy_instance_eu" {
  source        = "./modules/proxy_template"
  instance_name = local.proxy.instance_name
  port          = local.proxy.port
  shadowsocks_config_uri = module.common.shadowsocks_config_uri
  agent_user = {
    name = local.agent_user
    access_key = module.common.agent_access_key
  }
  rule_analysis = {
    days_to_scan   = local.rule_analysis.days_to_scan
    ping_count     = local.rule_analysis.ping_count
    dynamodb_table = local.rule_analysis.dynamodb_table
    image_uri = "zhifanz/fanqiang-update-ping:1.0.0"
  }
  public_key = var.public_key
  providers = {
    aws = aws.eu
  }
}
module "tunnel" {
  source = "./modules/tunnel"
  proxies = {
    port = local.proxy.port
    address_mapping = [
      [module.proxy_instance.public_ip, local.port_mapping.default],
      [module.proxy_instance_ap.public_ip, local.port_mapping.ap],
      [module.proxy_instance_eu.public_ip, local.port_mapping.eu]
    ]
  }
  public_key           = var.public_key
  ram_role_name        = "FangqiangEcsEipAccessRole"
  launch_template_name = "fanqiang-nginx"
  s3                   = module.common.s3
  rule_analysis        = {
    dynamodb_table = local.rule_analysis.dynamodb_table
    days_to_scan   = local.rule_analysis.days_to_scan
    ping_count     = local.rule_analysis.ping_count
    access_key = module.common.agent_access_key
    image_uri = "zhifanz/fanqiang-update-ping:1.0.0"
  }
  
}
module "rules" {
  source            = "./modules/rules"
  domain_table_name = local.rule_analysis.dynamodb_table
  process_shadowsocks_logs_service = {
    log_filter_name = "fanqiang-shadowsocks-connection-establish"
    log_group       = {
      name = local.proxy.log_group
      arn = module.proxy_instance.log_group_arn
      region = data.aws_region.default.name
    }
    name            = "fanqiang-process-shadowsocks-logs"
    docker_repo = {
      registry = "zhifanz"
      name = "fanqiang-extract-domain"
      version = "1.0.0"
    }
  }
  update_rules_service = {
    name = "fanqiang-update-rules"
    update_interval = local.rule_analysis.update_interval
    days_to_scan = local.rule_analysis.days_to_scan
    rules_storage = {
      bucket      = var.bucket
      config_root_path = local.rule_analysis.config_root_path
    }
    docker_repo = {
      registry = "zhifanz"
      name = "fanqiang-update-rules"
      version = "1.0.0"
    }
  }
}
module "clash" {
  source = "./modules/clash"
  s3     = module.common.s3
  client_config = {
    server       = module.tunnel.public_ip
    cipher       = var.encryption_algorithm
    password     = var.password
    port_mapping = local.port_mapping
  }
}
