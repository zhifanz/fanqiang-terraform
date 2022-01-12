variable "client_region" {
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
  validation {
    condition     = var.encryption_algorithm != "plain"
    error_message = "You must specify an encryption algorithm."
  }
}
variable "scale" {
  type        = string
  default     = "mini"
  description = "Determine how many features will be included in final infrastructure"
  validation {
    condition     = contains(["minimal", "moderate", "premium"], var.scale)
    error_message = "The scale value must be in [minimal, moderate, premium]."
  }
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
