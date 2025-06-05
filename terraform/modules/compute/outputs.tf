output "instance_id" {
  description = "ID of the VM instance"
  value       = google_compute_instance.vm.id
}

output "instance_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.vm.name
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP address"
  value       = length(google_compute_instance.vm.network_interface[0].access_config) > 0 ? google_compute_instance.vm.network_interface[0].access_config[0].nat_ip : null
}

output "self_link" {
  description = "Self link of the VM instance"
  value       = google_compute_instance.vm.self_link
}
