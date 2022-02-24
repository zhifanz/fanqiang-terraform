terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.10.0"
    }
  }
}
locals {
  extends_path_component          = "extends"
  extends_files                   = ["docker-compose.override.yml", "fluent-bit-parsers.conf", "fluent-bit.conf"]
  s3_proxy_artifacts_extends_path = "${var.s3.proxy_artifacts_path}/${local.extends_path_component}"
}
resource "aws_s3_bucket_object" "proxy_artifacts_extends_main" {
  for_each      = toset(local.extends_files)
  bucket        = var.s3.bucket
  key           = "${local.s3_proxy_artifacts_extends_path}/${each.key}"
  force_destroy = true
  source        = "${path.module}/${each.key}"
}
resource "aws_s3_bucket_object" "proxy_artifacts_extends_credentials" {
  bucket         = var.s3.bucket
  key            = "${local.s3_proxy_artifacts_extends_path}/credentials.json"
  force_destroy  = true
  content_base64 = google_service_account_key.default.private_key
}
resource "aws_s3_bucket_object" "proxy_artifacts_extends_env" {
  bucket        = var.s3.bucket
  key           = "${local.s3_proxy_artifacts_extends_path}/fluent-bit.env"
  force_destroy = true
  content       = <<EOT
    DATASET_ID=${var.dataset_id}
    TABLE_ID=${var.table_id}
  EOT
}
resource "google_service_account" "default" {
  account_id = var.service_account_id
}
resource "google_service_account_key" "default" {
  service_account_id = google_service_account.default.name
}
resource "google_bigquery_dataset" "default" {
  dataset_id                  = var.dataset_id
  delete_contents_on_destroy  = true
  default_table_expiration_ms = null
  access {
    role          = "OWNER"
    user_by_email = google_service_account.default.email
  }
}
resource "google_bigquery_table" "default" {
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = var.table_id
  expiration_time     = null
  deletion_protection = false
  schema = jsonencode([
    {
      name = "host"
      type = "STRING"
      mode = "REQUIRED"
      }, {
      name = "port"
      type = "INT64"
      mode = "REQUIRED"
      }, {
      name = "date"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    }
  ])
  clustering = ["date"]
}

