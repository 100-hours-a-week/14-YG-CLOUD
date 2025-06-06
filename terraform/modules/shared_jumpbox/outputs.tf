output "jumpbox_external_ip" {
  description = "External IP address of the shared jumpbox"
  value       = google_compute_address.jumpbox_ip.address
}

output "jumpbox_internal_ip" {
  description = "Internal IP address of the shared jumpbox"
  value       = google_compute_instance.shared_jumpbox.network_interface[0].network_ip
}

output "jumpbox_instance_name" {
  description = "Name of the shared jumpbox instance"
  value       = google_compute_instance.shared_jumpbox.name
}

output "jumpbox_self_link" {
  description = "Self link of the shared jumpbox instance"
  value       = google_compute_instance.shared_jumpbox.self_link
}

output "management_vpc_name" {
  description = "Name of the management VPC"
  value       = google_compute_network.management_vpc.name
}

output "management_vpc_self_link" {
  description = "Self link of the management VPC"
  value       = google_compute_network.management_vpc.self_link
}

output "management_subnet_name" {
  description = "Name of the management subnet"
  value       = google_compute_subnetwork.management_subnet.name
}

output "management_subnet_cidr" {
  description = "CIDR block of the management subnet"
  value       = google_compute_subnetwork.management_subnet.ip_cidr_range
}

output "ssh_command" {
  description = "SSH command to connect to the shared jumpbox"
  value       = "ssh ${var.ssh_user}@${google_compute_address.jumpbox_ip.address}"
}

output "wireguard_server_endpoint" {
  description = "WireGuard server endpoint for client configuration"
  value       = "${google_compute_address.jumpbox_ip.address}:51820"
}
