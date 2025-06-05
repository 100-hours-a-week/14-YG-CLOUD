output "startup_script" {
  description = "WireGuard installation and configuration script"
  value       = local.wireguard_startup_script
}

output "client_configs" {
  description = "WireGuard client configuration files"
  value       = local.wireguard_client_configs
  sensitive   = true
}
