# jumpbox 정보
output "jumpbox_internal_ip" {
  description = "Jumpbox 내부 IP 주소"
  value       = google_compute_instance.shared_jumpbox.network_interface[0].network_ip
}

output "jumpbox_external_ip" {
  description = "Jumpbox 외부 IP 주소"
  value       = google_compute_address.jumpbox_ip.address
}

output "jumpbox_ssh_command" {
  description = "Jumpbox SSH 접속 명령어"
  value       = "ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${google_compute_address.jumpbox_ip.address}"
}

# 네트워크 정보
output "shared_vpc_id" {
  description = "공유 VPC ID"
  value       = google_compute_network.shared_vpc.id
}

output "shared_vpc_name" {
  description = "공유 VPC 이름"
  value       = google_compute_network.shared_vpc.name
}

output "shared_subnet_id" {
  description = "공유 서브넷 ID"
  value       = google_compute_subnetwork.shared_subnet.id
}

output "shared_subnet_name" {
  description = "공유 서브넷 이름"
  value       = google_compute_subnetwork.shared_subnet.name
}

# WireGuard 설정 정보
output "wireguard_server_ip" {
  description = "WireGuard 서버 IP 주소 (내부)"
  value       = google_compute_instance.shared_jumpbox.network_interface[0].network_ip
}

output "wireguard_server_external_ip" {
  description = "WireGuard 서버 외부 IP 주소"
  value       = google_compute_address.jumpbox_ip.address
}
