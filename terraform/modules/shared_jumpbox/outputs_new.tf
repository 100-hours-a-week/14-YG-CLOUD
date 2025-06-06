# jumpbox 정보
output "jumpbox_external_ip" {
  description = "Jumpbox 외부 IP 주소"
  value       = google_compute_address.jumpbox_ip.address
}

output "jumpbox_internal_ip" {
  description = "Jumpbox 내부 IP 주소"
  value       = google_compute_instance.shared_jumpbox.network_interface[0].network_ip
}

output "jumpbox_instance_name" {
  description = "Jumpbox 인스턴스 이름"
  value       = google_compute_instance.shared_jumpbox.name
}

output "jumpbox_ssh_command" {
  description = "Jumpbox SSH 접속 명령어"
  value       = "ssh -i ~/.ssh/lsh-study-key ubuntu@${google_compute_address.jumpbox_ip.address}"
}

# 네트워크 정보
output "management_vpc_id" {
  description = "관리 VPC ID"
  value       = google_compute_network.management_vpc.id
}

output "management_vpc_name" {
  description = "관리 VPC 이름"
  value       = google_compute_network.management_vpc.name
}

output "management_subnet_id" {
  description = "관리 서브넷 ID"
  value       = google_compute_subnetwork.management_subnet.id
}

output "management_subnet_name" {
  description = "관리 서브넷 이름"
  value       = google_compute_subnetwork.management_subnet.name
}
