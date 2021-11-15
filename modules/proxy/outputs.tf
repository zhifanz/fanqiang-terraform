output "public_ip" {
  value = aws_lightsail_instance.default.public_ip_address
}
