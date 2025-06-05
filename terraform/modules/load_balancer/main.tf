# Load Balancer 모듈 - HTTP/HTTPS 로드밸런서

# 글로벌 외부 IP 주소
resource "google_compute_global_address" "lb_ip" {
  name         = "${var.project_name}-${var.env}-lb-ip"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# 인스턴스 그룹 (Unmanaged) - Backend 서버용
resource "google_compute_instance_group" "backend_group" {
  name        = "${var.project_name}-${var.env}-backend-group"
  description = "Instance group for backend servers"
  zone        = var.zone
  network     = var.network_self_link

  instances = var.backend_instances

  named_port {
    name = "http"
    port = 8080
  }
}

# 인스턴스 그룹 (Unmanaged) - AI 서버용  
resource "google_compute_instance_group" "ai_group" {
  name        = "${var.project_name}-${var.env}-ai-group"
  description = "Instance group for AI servers"
  zone        = var.zone
  network     = var.network_self_link

  instances = var.ai_instances

  named_port {
    name = "http"
    port = 8100
  }
}

# 헬스 체크 - Backend
resource "google_compute_health_check" "backend_health_check" {
  name               = "${var.project_name}-${var.env}-backend-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3

  http_health_check {
    port               = 8080
    request_path       = "/health"  # Backend에 헬스 체크 엔드포인트 필요
    proxy_header       = "NONE"
  }
}

# 헬스 체크 - AI
resource "google_compute_health_check" "ai_health_check" {
  name               = "${var.project_name}-${var.env}-ai-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3

  http_health_check {
    port               = 8100
    request_path       = "/health"  # AI 서버에 헬스 체크 엔드포인트 필요
    proxy_header       = "NONE"
  }
}

# 백엔드 서비스 - Backend
resource "google_compute_backend_service" "backend_service" {
  name                    = "${var.project_name}-${var.env}-backend-service"
  description             = "Backend service for API servers"
  protocol                = "HTTP"
  port_name              = "http"
  load_balancing_scheme  = "EXTERNAL"
  timeout_sec            = 30
  enable_cdn             = false

  backend {
    group           = google_compute_instance_group.backend_group.id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.backend_health_check.id]
}

# 백엔드 서비스 - AI
resource "google_compute_backend_service" "ai_service" {
  name                    = "${var.project_name}-${var.env}-ai-service"
  description             = "Backend service for AI servers"
  protocol                = "HTTP"
  port_name              = "http"
  load_balancing_scheme  = "EXTERNAL"
  timeout_sec            = 120  # AI 추론 작업을 위해 길게 설정
  enable_cdn             = false

  backend {
    group           = google_compute_instance_group.ai_group.id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.ai_health_check.id]
}

# URL 맵 - 라우팅 규칙
resource "google_compute_url_map" "lb_url_map" {
  name            = "${var.project_name}-${var.env}-lb-url-map"
  description     = "URL map for routing traffic"
  default_service = google_compute_backend_service.backend_service.id

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.backend_service.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.backend_service.id
    }

    path_rule {
      paths   = ["/generation/*"]
      service = google_compute_backend_service.ai_service.id
    }
  }

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
}

# HTTP 프록시
resource "google_compute_target_http_proxy" "lb_http_proxy" {
  name   = "${var.project_name}-${var.env}-lb-http-proxy"
  url_map = google_compute_url_map.lb_url_map.id
}

# 글로벌 포워딩 규칙 (HTTP)
resource "google_compute_global_forwarding_rule" "lb_forwarding_rule" {
  name                  = "${var.project_name}-${var.env}-lb-forwarding-rule"
  description           = "Global forwarding rule for HTTP traffic"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.lb_http_proxy.id
  ip_address            = google_compute_global_address.lb_ip.id
}

# HTTPS 지원을 위한 SSL 인증서 (선택사항)
resource "google_compute_managed_ssl_certificate" "lb_ssl_cert" {
  count = var.enable_https ? 1 : 0
  name  = "${var.project_name}-${var.env}-lb-ssl-cert"

  managed {
    domains = var.ssl_domains
  }
}

# HTTPS 프록시 (선택사항)
resource "google_compute_target_https_proxy" "lb_https_proxy" {
  count           = var.enable_https ? 1 : 0
  name            = "${var.project_name}-${var.env}-lb-https-proxy"
  url_map         = google_compute_url_map.lb_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_ssl_cert[0].id]
}

# HTTPS 포워딩 규칙 (선택사항)
resource "google_compute_global_forwarding_rule" "lb_https_forwarding_rule" {
  count                 = var.enable_https ? 1 : 0
  name                  = "${var.project_name}-${var.env}-lb-https-forwarding-rule"
  description           = "Global forwarding rule for HTTPS traffic"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.lb_https_proxy[0].id
  ip_address            = google_compute_global_address.lb_ip.id
}
