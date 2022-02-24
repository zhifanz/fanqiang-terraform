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
variable "bucket" {
  type    = string
  default = "fanqiang"
}
variable "multi_proxy" {
  type    = bool
  default = false
}
variable "client_region" {
  type        = string
  default     = null
  description = "https://help.aliyun.com/document_detail/40654.html"
}
variable "rule_analysis_project" {
  type    = string
  default = null
}
variable "public_key" {
  type    = string
  default = null
}
# All variable defined below is for develop purpose only, end user should just keep the default value
variable "dev" {
  type = any
  default = {
    agent_user                  = "fanqiang-agent"
    proxy_instance_name         = "shadowsocks-server"
    tunnel_ram_role_name        = "FangqiangEcsEipAccessRole"
    tunnel_launch_template_name = "fanqiang-nginx"
  }
}
