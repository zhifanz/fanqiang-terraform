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
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
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
data "google_project" "default" {
}
resource "google_app_engine_application" "default" {
  project       = data.google_project.default.project_id
  location_id   = "us-central"
  database_type = "CLOUD_FIRESTORE"
}
resource "google_project_service" "iam" {
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_service_account" "default" {
  account_id = var.service_account_id
  depends_on = [
    google_project_service.iam
  ]
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
data "archive_file" "fra" {
  type        = "zip"
  output_path = "${path.module}/files/fra.zip"
  source_dir  = "${path.module}/cloudfunction"
}
resource "google_storage_bucket" "default" {
  name          = var.cloud_function.bucket
  force_destroy = true
  location      = "US-CENTRAL1"
}
resource "google_storage_bucket_object" "fra_archive" {
  name   = "fra.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.fra.output_path
}
resource "google_project_service" "cloudfunctions" {
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_cloudfunctions_function" "default" {
  name                  = var.cloud_function.name
  runtime               = "python39"
  timeout               = 540
  ingress_settings      = "ALLOW_INTERNAL_ONLY"
  entry_point           = "handle_event"
  source_archive_bucket = google_storage_bucket.default.name
  source_archive_object = google_storage_bucket_object.fra_archive.name
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.default.name
  }
  depends_on = [google_project_service.cloudfunctions]
}
resource "google_project_service" "cloudscheduler" {
  service                    = "cloudscheduler.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_cloud_scheduler_job" "default" {
  name     = var.cloud_function.scheduler
  schedule = "0 0 * * *"
  pubsub_target {
    topic_name = google_pubsub_topic.default.id
    data       = base64encode("{}")
  }
  depends_on = [google_project_service.cloudscheduler]
}
resource "google_project_service" "pubsub" {
  service                    = "pubsub.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_pubsub_topic" "default" {
  name = var.cloud_function.topic
  depends_on = [
    google_project_service.pubsub
  ]
}
