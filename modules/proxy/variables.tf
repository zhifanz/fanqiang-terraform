variable "port" {
  type = number
}
variable "instance_name" {
  type = string
}
variable "public_key" {
  type = string
}
variable "shadowsocks_config_url" {
  type = string
}
variable "awslogs" {
  type = object({
    agent_access_key = object({
      id     = string
      secret = string
    })
    region = string
    group  = string
  })
}
