# GCS + CDN 모듈 - Frontend 정적 웹사이트 호스팅

# GCS 버킷 생성
resource "google_storage_bucket" "frontend_bucket" {
  name          = "${var.project_name}-${var.env}-frontend"
  location      = "ASIA"
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# 버킷을 public으로 설정
resource "google_storage_bucket_iam_member" "frontend_bucket_public" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Cloud CDN을 위한 Backend Service
resource "google_compute_backend_bucket" "frontend_backend" {
  name        = "${var.project_name}-${var.env}-frontend-backend"
  bucket_name = google_storage_bucket.frontend_bucket.name
  enable_cdn  = true
  
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                 = 3600
    max_ttl                     = 86400
    negative_caching            = true
    serve_while_stale           = 86400
  }
}

# Global HTTP(S) Load Balancer
resource "google_compute_url_map" "frontend_url_map" {
  name            = "${var.project_name}-${var.env}-frontend-urlmap"
  default_service = google_compute_backend_bucket.frontend_backend.self_link
}

# HTTP(S) Proxy
resource "google_compute_target_https_proxy" "frontend_https_proxy" {
  name   = "${var.project_name}-${var.env}-frontend-https-proxy"
  url_map = google_compute_url_map.frontend_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend_ssl_cert.self_link]
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "frontend_ssl_cert" {
  name = "${var.project_name}-${var.env}-ssl-cert"
  
  managed {
    domains = [var.domain_name]
  }
}

# Global Static IP for Load Balancer
resource "google_compute_global_address" "frontend_ip" {
  name = "${var.project_name}-${var.env}-frontend-ip"
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "frontend_https" {
  name       = "${var.project_name}-${var.env}-frontend-https"
  target     = google_compute_target_https_proxy.frontend_https_proxy.self_link
  port_range = "443"
  ip_address = google_compute_global_address.frontend_ip.address
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "frontend_http_redirect" {
  name = "${var.project_name}-${var.env}-frontend-http-redirect"
  
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "frontend_http_proxy" {
  name    = "${var.project_name}-${var.env}-frontend-http-proxy"
  url_map = google_compute_url_map.frontend_http_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "frontend_http" {
  name       = "${var.project_name}-${var.env}-frontend-http"
  target     = google_compute_target_http_proxy.frontend_http_proxy.self_link
  port_range = "80"
  ip_address = google_compute_global_address.frontend_ip.address
}
