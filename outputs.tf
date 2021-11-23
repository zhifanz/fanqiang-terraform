output "clash_config_url" {
  value = module.clash.config_url
}
output "tunnel_public_ip" {
  value = module.tunnel.public_ip
}
output "proxy_public_ip" {
  value = module.proxy_instance.public_ip
}
output "proxy_ap_public_ip" {
  value = module.proxy_instance_ap.public_ip
}
output "proxy_eu_public_ip" {
  value = module.proxy_instance_eu.public_ip
}
