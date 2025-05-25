output "VPN_connection_shared_key" {
  value     = random_password.VPN_connection_shared_key.result
  sensitive = true
}