output "clash_config_url" {
  value = module.clash.config_url
}
output "tunnel_public_ip" {
  value = var.mini ? null : module.tunnel[0].public_ip
}
output "proxy_public_ip" {
  value = module.proxy_instance.public_ip
}
output "proxy_ap_public_ip" {
  value = var.mini ? null : module.proxy_instance_ap[0].public_ip
}
output "proxy_eu_public_ip" {
  value = var.mini ? null : module.proxy_instance_eu[0].public_ip
}
