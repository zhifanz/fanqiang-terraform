variable "tunnel_region" {
  type        = string
  default     = "cn-shanghai"
  description = "https://help.aliyun.com/document_detail/40654.html"
}
variable "password" {
  type = string
}
variable "encryption_algorithm" {
  type        = string
  default     = "aes-256-gcm"
  description = "https://github.com/shadowsocks/shadowsocks-crypto/blob/main/src/v1/cipher.rs"
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
