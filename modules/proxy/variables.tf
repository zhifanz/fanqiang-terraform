variable "port" {
  type = number
}
variable "encryption_algorithm" {
  type = string
}
variable "password" {
  type = string
}
variable "instance_name" {
  type = string
}
variable "public_key" {
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
