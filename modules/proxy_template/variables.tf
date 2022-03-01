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
    common_uri  = string
    extends_uri = string
  })
}
