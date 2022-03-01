variable "service_account_id" {
  type = string
}
variable "s3_bucket" {
  type = string
}
variable "bigquery" {
  type = object({
    dataset_id = string
    table_id   = string
  })
}
