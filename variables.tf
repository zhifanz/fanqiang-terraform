variable "proxy_region" {
  type    = string
  default = "us-east-1"
}
variable "tunnel_region" {
  type    = string
  default = "cn-shanghai"
}
variable "port" {
  type    = number
  default = 8388
}
variable "password" {
  type = string
}
variable "encryption_algorithm" {
  type    = string
  default = "aes-256-gcm"
}
variable "bucket" {
  type    = string
  default = "fanqiang"
}
variable "domain_access_timeout_in_seconds" {
  type    = string
  default = "1"
}
variable "public_key" {
  type    = string
  default = null
}
