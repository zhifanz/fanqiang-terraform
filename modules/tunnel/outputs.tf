output "public_ip" {
  value = alicloud_eip_address.default.ip_address
}
