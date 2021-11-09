variable "ping_service" {
  type = object({
    app_name = string
    service_name = string
    function_name = string
    ram_role_name = string
    timeout = number
  })
  default = {
    app_name = "fanqiang_ping_client"
    service_name = "fanqiang"
    function_name = "ping"
    ram_role_name = "FangqiangFcInvokeAccessRole"
    timeout = 20
  }
}
variable "log_process_service_name" {
  type = string
  default = "fanqiang-process-shadowsocks-logs"
}
variable "log_filter_name" {
  type = string
  default = "fanqiang-shadowsocks-domains"
}
variable "log_group" {
  type = object({
    name = string
    arn = string
    region = string
  })
}
