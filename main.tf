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
    google = {
      source  = "hashicorp/google"
      version = "4.10.0"
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
provider "google" {
  project = var.rule_analysis_project
  region  = "us-central1"
}
locals {
  port_mapping = {
    auto = 8527
    ap   = 8528
    eu   = 8529
  }
  agent_user = var.dev.agent_user

  proxy = {
    instance_name = var.dev.proxy_instance_name
    port          = 8388
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
  source                = "./modules/proxy_template"
  instance_name         = local.proxy.instance_name
  port                  = local.proxy.port
  agent_user_access_key = module.common.agent_access_key
  artifacts = {
    root_uri              = module.common.artifacts.root_uri
    compose_file          = module.common.artifacts.compose_file
    compose_override_file = var.rule_analysis_project != null ? module.rules[0].compose_override_file : null
  }
  public_key = var.public_key
}
module "proxy_instance_ap" {
  count                 = var.multi_proxy ? 1 : 0
  source                = "./modules/proxy_template"
  instance_name         = local.proxy.instance_name
  port                  = local.proxy.port
  agent_user_access_key = module.common.agent_access_key
  artifacts = {
    root_uri              = module.common.artifacts.root_uri
    compose_file          = module.common.artifacts.compose_file
    compose_override_file = null
  }
  public_key = var.public_key
  providers = {
    aws = aws.ap
  }
}
module "proxy_instance_eu" {
  count                 = var.multi_proxy ? 1 : 0
  source                = "./modules/proxy_template"
  instance_name         = local.proxy.instance_name
  port                  = local.proxy.port
  agent_user_access_key = module.common.agent_access_key
  artifacts = {
    root_uri              = module.common.artifacts.root_uri
    compose_file          = module.common.artifacts.compose_file
    compose_override_file = null
  }
  public_key = var.public_key
  providers = {
    aws = aws.eu
  }
}
module "tunnel" {
  count  = var.client_region != null ? 1 : 0
  source = "./modules/tunnel"
  proxies = {
    port = local.proxy.port
    address_mapping = var.multi_proxy ? [
      [module.proxy_instance.public_ip, local.port_mapping.auto],
      [module.proxy_instance_ap[0].public_ip, local.port_mapping.ap],
      [module.proxy_instance_eu[0].public_ip, local.port_mapping.eu]
    ] : [[module.proxy_instance.public_ip, local.proxy.port]]
  }
  public_key           = var.public_key
  ram_role_name        = var.dev.tunnel_ram_role_name
  launch_template_name = var.dev.tunnel_launch_template_name
  s3                   = module.common.s3
}
module "rules" {
  count              = var.rule_analysis_project != null ? 1 : 0
  source             = "./modules/rules"
  dataset_id         = "fanqiang"
  table_id           = "internet_access_events"
  service_account_id = "lightsail-fluentbit"
  s3 = {
    bucket               = var.bucket
    proxy_artifacts_path = module.common.artifacts.root_path
  }
  depends_on = [
    module.common
  ]
}
module "clash" {
  source = "./modules/clash"
  s3     = module.common.s3
  client_config = {
    proxies = {
      auto = {
        server = var.client_region != null ? module.tunnel[0].public_ip : module.proxy_instance.public_ip
        port   = var.multi_proxy && var.client_region != null ? local.port_mapping.auto : local.proxy.port
      }
      others = var.multi_proxy ? [
        {
          continent = "ap"
          server    = var.client_region != null ? module.tunnel[0].public_ip : module.proxy_instance_ap[0].public_ip
          port      = var.client_region != null ? local.port_mapping.ap : local.proxy.port
        },
        {
          continent = "eu"
          server    = var.client_region != null ? module.tunnel[0].public_ip : module.proxy_instance_eu[0].public_ip
          port      = var.client_region != null ? local.port_mapping.eu : local.proxy.port
        }
      ] : []
    }
    cipher   = var.encryption_algorithm
    password = var.password
  }
  enable_rules = var.rule_analysis_project != null
}
