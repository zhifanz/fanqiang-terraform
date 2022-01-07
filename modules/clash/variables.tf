variable "s3" {
  type = object({
    bucket             = string
    bucket_domain_name = string
  })
}
variable "client_config" {
  type = object({
    server   = string
    cipher   = string
    password = string
    port_mapping = object({
      auto = number
      others = list(object({
        continent = string
        port      = number
      }))
    })
  })
}
