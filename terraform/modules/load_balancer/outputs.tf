# Load Balancer 모듈 출력

output "load_balancer_ip" {
  description = "Load Balancer 외부 IP 주소"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip_name" {
  description = "Load Balancer IP 리소스 이름"
  value       = google_compute_global_address.lb_ip.name
}

output "backend_service_id" {
  description = "Backend 서비스 ID"
  value       = google_compute_backend_service.backend_service.id
}

output "ai_service_id" {
  description = "AI 서비스 ID"
  value       = google_compute_backend_service.ai_service.id
}

output "url_map_id" {
  description = "URL 맵 ID"
  value       = google_compute_url_map.lb_url_map.id
}

output "backend_group_id" {
  description = "Backend 인스턴스 그룹 ID"
  value       = google_compute_instance_group.backend_group.id
}

output "ai_group_id" {
  description = "AI 인스턴스 그룹 ID"
  value       = google_compute_instance_group.ai_group.id
}
