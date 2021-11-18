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
