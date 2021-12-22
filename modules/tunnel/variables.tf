variable "proxies" {
  type = object({
    port            = number
    address_mapping = list(tuple([string, number]))
  })
}
variable "public_key" {
  type    = string
  default = null
}
variable "ram_role_name" {
  type = string
}
variable "launch_template_name" {
  type = string
}
variable "s3" {
  type = object({
    bucket             = string
    bucket_domain_name = string
  })
}
variable "rule_analysis" {
  type = object({
    dynamodb_table = string
    days_to_scan   = number
    ping_count     = number
    access_key = object({
      id     = string
      secret = string
    })
    image_uri = string
  })
  default = null
}
