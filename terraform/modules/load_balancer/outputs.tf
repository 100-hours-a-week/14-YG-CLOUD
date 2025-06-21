# Load Balancer 모듈 출력 (Option 4 구조)

output "main_ip_address" {
  description = "메인 Load Balancer 외부 IP 주소"
  value       = google_compute_global_address.main_ip.address
}

output "main_ip_name" {
  description = "메인 Load Balancer IP 리소스 이름"
  value       = google_compute_global_address.main_ip.name
}

output "frontend_url" {
  description = "프론트엔드 접속 URL"
  value       = "https://${var.domain_name}"
}

output "backend_service_id" {
  description = "Backend 서비스 ID"
  value       = google_compute_backend_service.backend_service.id
}

output "ai_service_id" {
  description = "AI 서비스 ID"
  value       = google_compute_backend_service.ai_service.id
}

output "frontend_cdn_backend_id" {
  description = "프론트엔드 CDN Backend ID"
  value       = google_compute_backend_bucket.frontend_cdn.id
}

output "main_url_map_id" {
  description = "메인 URL 맵 ID (통합 라우팅)"
  value       = google_compute_url_map.main_url_map.id
}

output "backend_group_id" {
  description = "Backend 인스턴스 그룹 ID"
  value       = google_compute_instance_group.backend_group.id
}

output "ai_group_id" {
  description = "AI 인스턴스 그룹 ID"
  value       = google_compute_instance_group.ai_group.id
}

output "ssl_certificate_id" {
  description = "SSL 인증서 ID"
  value       = google_compute_managed_ssl_certificate.main_ssl_cert.id
}
