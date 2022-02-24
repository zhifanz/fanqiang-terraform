variable "instance_name" {
  type = string
}
variable "port" {
  type = number
}
variable "public_key" {
  type = string
}
variable "agent_user_access_key" {
  type = any
}
variable "artifacts" {
  type = object({
    root_uri              = string
    compose_file          = string
    compose_override_file = string
  })
}
