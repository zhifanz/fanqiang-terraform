variable "instance_name" {
  type = string
}
variable "port" {
  type = number
}
variable "shadowsocks_config_uri" {
  type = string
}
variable "rule_analysis" {
  type = object({
    days_to_scan   = number
    ping_count     = number
    dynamodb_table = string
    image_uri      = string
    continent      = string
  })
  default = null
}
variable "public_key" {
  type = string
}
variable "agent_user" {
  type = object({
    name       = string
    access_key = any
  })
}
variable "log_group" {
  type    = string
  default = null
}
