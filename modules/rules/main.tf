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
  artifacts_root_path = "proxy/extends"
}
resource "aws_s3_bucket_object" "proxy_artifacts_extends_main" {
  for_each      = toset(["docker-compose.override.yml", "fluent-bit-parsers.conf"])
  bucket        = var.s3_bucket
  key           = "${local.artifacts_root_path}/${each.key}"
  force_destroy = true
  source        = "${path.module}/${each.key}"
}
resource "aws_s3_bucket_object" "fluentbit_conf" {
  bucket        = var.s3_bucket
  key           = "${local.artifacts_root_path}/fluent-bit.conf"
  force_destroy = true
  content = templatefile("${path.module}/fluent-bit.conf.tpl", {
    bigquery = var.bigquery
  })
}
resource "aws_s3_bucket_object" "proxy_artifacts_extends_credentials" {
  bucket         = var.s3_bucket
  key            = "${local.artifacts_root_path}/credentials.json"
  force_destroy  = true
  content_base64 = google_service_account_key.default.private_key
}
resource "google_service_account" "default" {
  account_id = var.service_account_id
}
resource "google_service_account_key" "default" {
  service_account_id = google_service_account.default.name
}
resource "google_bigquery_dataset" "default" {
  dataset_id                  = var.bigquery.dataset_id
  delete_contents_on_destroy  = true
  default_table_expiration_ms = null
  access {
    role          = "OWNER"
    user_by_email = google_service_account.default.email
  }
}
resource "google_bigquery_table" "default" {
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = var.bigquery.table_id
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
      name = "access_timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    }
  ])
  clustering = ["access_timestamp"]
}

