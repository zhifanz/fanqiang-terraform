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
  }
}

provider "aws" {
  region = var.proxy_region
}
provider "alicloud" {
  region = var.tunnel_region
}

module "proxy" {
  source               = "./modules/awsecs"
  port                 = var.port
  encryption_algorithm = var.encryption_algorithm
  password             = var.password
  service_name = "shadowsocks"
  log_group_name = "fanqiang"
}

module "tunnel" {
  source          = "./modules/tunnel"
  proxy_port      = var.port
  proxy_public_ip = module.proxy.public_ip
  public_key      = var.public_key
}

module "rules" {
  source = "./modules/rules"
  domain_table_name = "domains"
  ping_service = {
    function_name = "ping"
    ram_role_name = "FangqiangFcInvokeAccessRole"
    service_name = "fanqiang"
    timeout = 20
  }
  process_shadowsocks_logs_service = {
    log_filter_name = "fanqiang-shadowsocks-connection-establish"
    log_group = module.proxy.log_group
    name = "fanqiang-process-shadowsocks-logs"
  }
  scan_domains_service = {
    name = "fanqiang-scan-domains"
    rate = "10 minutes"
    storage = {
      bucket = aws_s3_bucket.default.id
      object_path = aws_s3_bucket_object.clash_domestic_rule_provider.key
    }
  }
}

resource "aws_s3_bucket" "default" {
  bucket        = var.bucket
  acl           = "public-read"
  force_destroy = true
}
resource "aws_s3_bucket_object" "clash_domestic_rule_provider" {
  bucket = aws_s3_bucket.default.id
  key = "clash/direct_domains.yaml"
  acl = "public-read"
  force_destroy = true
  content = "payload: []"
}
resource "aws_s3_bucket_object" "clash_config" {
  bucket = aws_s3_bucket.default.id
  key = "clash/config.yaml"
  acl = "public-read"
  force_destroy = true
  content = templatefile("${path.module}/clash-config.yml.tpl", {
    server = module.tunnel.public_ip
    port = var.port
    cipher = var.encryption_algorithm
    password = var.password
    domestic_rule_provider_url = "https://${aws_s3_bucket.default.bucket_domain_name}/${aws_s3_bucket_object.clash_domestic_rule_provider.key}"
  })
}
