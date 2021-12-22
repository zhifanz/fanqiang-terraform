variable "bucket" {
  type = string
}
variable "agent_user" {
  type = string
}
variable "shadowsocks" {
  type = object({
    server_port = number
    password    = string
    method      = string
  })
}
