variable "s3_bucket" {
  type = string
}
variable "service_account_id" {
  type = string
}
variable "bigquery" {
  type = object({
    dataset_id = string
    table_id   = string
  })
}
variable "cloud_function" {
  type = object({
    bucket    = string
    name      = string
    topic     = string
    scheduler = string
  })
}
