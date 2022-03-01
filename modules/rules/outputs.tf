output "artifacts_uri" {
  value = "s3://${var.s3_bucket}/${local.artifacts_root_path}"
}
