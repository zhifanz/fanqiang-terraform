variable "process_shadowsocks_logs_service" {
  type = object({
    name            = string
    log_filter_name = string
    log_group = object({
      name   = string
      arn    = string
      region = string
    })
    docker_repo = object({
      registry = string
      name     = string
      version  = string
    })
  })
}
variable "update_rules_service" {
  type = object({
    name            = string
    update_interval = string
    days_to_scan    = number
    rules_storage = object({
      bucket           = string
      config_root_path = string
    })
    docker_repo = object({
      registry = string
      name     = string
      version  = string
    })
  })
}
variable "domain_table_name" {
  type = string
}
variable "agent_user" {
  type = string
}
