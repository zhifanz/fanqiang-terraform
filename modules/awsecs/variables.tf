variable "port" {
  type = number
}
variable "encryption_algorithm" {
  type = string
}
variable "password" {
  type = string
}
variable "service_name" {
  type = string
  default = "shadowsocks"
}
variable "log_group_name" {
  type = string
  default = "fanqiang"
}