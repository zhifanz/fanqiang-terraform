variable "proxy_public_ip" {
  type = string
}
variable "proxy_port" {
  type = number
}
variable "public_key" {
  type    = string
  default = null
}
variable "ram_role_name" {
  type = string
  default = "FangqiangEcsEipAccessRole"
}
variable "launch_template_name" {
  type = string
  default = "fanqiang"
}
