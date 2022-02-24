variable "dataset_id" {
  type = string
}
variable "table_id" {
  type = string
}
variable "service_account_id" {
  type = string
}
variable "s3" {
  type = object({
    bucket               = string
    proxy_artifacts_path = string
  })
}
