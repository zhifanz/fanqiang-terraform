variable "ping_service" {
  type = object({
    service_name       = string
    function_name      = string
    ram_role_name      = string
    timeout_in_seconds = string
  })
}
variable "process_shadowsocks_logs_service" {
  type = object({
    name            = string
    log_filter_name = string
    log_group = object({
      name   = string
      arn    = string
      region = string
    })
    clash_rule_storage = object({
      bucket      = string
      object_path = string
    })
  })
}
variable "domain_table_name" {
  type = string
}
