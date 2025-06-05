output "ip_address" {
  description = "The static IP address"
  value       = google_compute_address.static_ip.address
}

output "ip_name" {
  description = "Name of the static IP"
  value       = google_compute_address.static_ip.name
}

output "self_link" {
  description = "Self link of the static IP"
  value       = google_compute_address.static_ip.self_link
}
