# Load Balancer 모듈 - HTTP/HTTPS 로드밸런서 (Option 4: 통합 구조)

# 글로벌 외부 IP 주소
resource "google_compute_global_address" "main_ip" {
  name         = "${var.project_name}-${var.env}-main-ip"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# Option 4: GCS CDN Backend Bucket (정적 파일용)
resource "google_compute_backend_bucket" "frontend_cdn" {
  name        = "${var.project_name}-${var.env}-frontend-cdn"
  bucket_name = var.gcs_bucket_name
  enable_cdn  = true
  
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                 = 3600
    max_ttl                     = 86400
    negative_caching            = true
    serve_while_stale           = 86400
  }
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
    request_path       = "/api/group-buys"  # Backend API 엔드포인트 사용
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
  timeout_sec            = 120  # AI 생성 API 호출을 위해 타임아웃 증가 (2025-07-08)
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

# Option 4: 통합 URL 맵 - 정적/동적 콘텐츠 모두 처리
resource "google_compute_url_map" "main_url_map" {
  name            = "${var.project_name}-${var.env}-main-url-map"
  description     = "Main URL map for routing all traffic (Option 4)"
  default_service = google_compute_backend_bucket.frontend_cdn.self_link

  # 도메인별 라우팅
  host_rule {
    hosts        = [var.domain_name]
    path_matcher = "main-routing"
  }
  
  path_matcher {
    name            = "main-routing"
    default_service = google_compute_backend_bucket.frontend_cdn.self_link
    
    # API 경로 - Backend Service로 라우팅
    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.backend_service.self_link
    }
    
    # AI/Generation 경로 - AI Service로 라우팅  
    path_rule {
      paths   = ["/generation/*", "/generate/*"]
      service = google_compute_backend_service.ai_service.self_link
    }
    
    # 정적 자산들은 CDN으로 (명시적)
    path_rule {
      paths   = ["/assets/*", "/static/*", "/icons/*", "/images/*", "/fonts/*", "/js/*", "/css/*"]
      service = google_compute_backend_bucket.frontend_cdn.self_link
    }
    
    # 특정 파일들도 CDN으로
    path_rule {
      paths   = ["/favicon.ico", "/manifest.json", "/robots.txt"]
      service = google_compute_backend_bucket.frontend_cdn.self_link
    }
    
    # SPA 경로들을 명시적으로 index.html로 라우팅 (CDN 캐시 활용)
    path_rule {
      paths = ["/", "/index.html", "/products", "/products/*", "/login", "/signup", "/mypage", "/chat", "/chat/*", "/writePost", "/editPost/*", "/signupInfo", "/editProfile", "/editPassword"]
      service = google_compute_backend_bucket.frontend_cdn.self_link
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/index.html"
        }
      }
    }
  }
}

# SSL 인증서 (HTTPS 지원)
resource "google_compute_managed_ssl_certificate" "main_ssl_cert" {
  name = "${var.project_name}-${var.env}-main-ssl-cert"

  managed {
    domains = [var.domain_name]
  }
}

# HTTPS 프록시 (메인)
resource "google_compute_target_https_proxy" "main_https_proxy" {
  name            = "${var.project_name}-${var.env}-main-https-proxy"
  url_map         = google_compute_url_map.main_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.main_ssl_cert.self_link]
}

# HTTPS 포워딩 규칙 (메인)
resource "google_compute_global_forwarding_rule" "main_https_forwarding_rule" {
  name       = "${var.project_name}-${var.env}-main-https-forwarding-rule"
  target     = google_compute_target_https_proxy.main_https_proxy.self_link
  port_range = "443"
  ip_address = google_compute_global_address.main_ip.address
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name = "${var.project_name}-${var.env}-http-redirect"
  
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "main_http_proxy" {
  name    = "${var.project_name}-${var.env}-main-http-proxy"
  url_map = google_compute_url_map.http_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "main_http_forwarding_rule" {
  name       = "${var.project_name}-${var.env}-main-http-forwarding-rule"
  target     = google_compute_target_http_proxy.main_http_proxy.self_link
  port_range = "80"
  ip_address = google_compute_global_address.main_ip.address
}
