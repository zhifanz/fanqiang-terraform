variable "config" {
  type = object({
    instance_name          = string
    port                   = number
    shadowsocks_config_url = string
    agent_user = object({
      access_key = object({
        id     = string
        secret = string
      })
    })
    log_group = object({
      name   = string
      region = string
    })
  })
}
variable "public_key" {
  type = string
}
