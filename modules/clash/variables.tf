variable "s3" {
  type = object({
    bucket             = string
    bucket_domain_name = string
  })
}
variable "client_config" {
  type = object({
    cipher   = string
    password = string
    proxies = object({
      auto = object({
        server = string
        port   = number
      })
      others = list(object({
        continent = string
        server    = string
        port      = number
      }))
    })
  })
}
variable "enable_rules" {
  type = bool
}
