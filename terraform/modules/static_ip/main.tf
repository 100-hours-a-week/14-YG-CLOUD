# Static IP 모듈 - 고정 IP 주소 관리

# 고정 외부 IP 주소 생성
resource "google_compute_address" "static_ip" {
  name         = "${var.project_name}-${var.env}-${var.ip_name}"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for ${var.ip_name} in ${var.env} environment"
}
