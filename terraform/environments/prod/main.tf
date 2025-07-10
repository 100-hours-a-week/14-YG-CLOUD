# ========================================
# Production Environment Configuration
# ========================================

# Provider 설정
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 로컬 변수
locals {
  env         = "prod"
  common_tags = {
    environment = local.env
    project     = "moongsan"
    managed_by  = "terraform"
  }
  
  # Prod 환경 네트워크 설정 (test와 다른 대역)
  vpc_cidr = "10.1.0.0/16"
  
  # 내부 VM IP 설정 (test와 다른 대역)
  internal_ips = {
    database = "10.1.0.2"
    backend  = "10.1.0.3"
    ai       = "10.1.0.4"
  }
}

# ========================================
# 네트워크 구성
# ========================================

# VPC 생성
resource "google_compute_network" "prod_vpc" {
  name                    = "prod-vpc"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"
  description            = "Production VPC for moongsan project"
}

# 서브넷 생성 (prod 대역)
resource "google_compute_subnetwork" "prod_subnet" {
  name          = "prod-subnet"
  ip_cidr_range = local.vpc_cidr
  region        = var.region
  network       = google_compute_network.prod_vpc.id
  description   = "Production subnet for moongsan project"
  
  # Private Google Access 활성화 (GCP 서비스 접근용)
  private_ip_google_access = true
}

# 방화벽 규칙 - 내부 통신 허용
resource "google_compute_firewall" "prod_internal" {
  name    = "prod-allow-internal"
  network = google_compute_network.prod_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3306", "6379", "8080", "8100", "27017"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [local.vpc_cidr]
  target_tags   = ["prod-internal"]
}

# 방화벽 규칙 - SSH 접근 (제한적)
resource "google_compute_firewall" "prod_ssh" {
  name    = "prod-allow-ssh"
  network = google_compute_network.prod_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    "0.0.0.0/0"  # 실제 운영에서는 관리자 IP로 제한
  ]
  target_tags = ["prod-ssh"]
}

# 방화벽 규칙 - HTTP/HTTPS
resource "google_compute_firewall" "prod_web" {
  name    = "prod-allow-web"
  network = google_compute_network.prod_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["prod-web"]
}

# GCP Health Check를 위한 방화벽 규칙
resource "google_compute_firewall" "prod_health_check" {
  name    = "prod-allow-health-check"
  network = google_compute_network.prod_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8100"]  # Backend와 AI 포트 모두 포함
  }

  source_ranges = [
    "130.211.0.0/22",  # GCP Health Check IP ranges
    "35.191.0.0/16"
  ]

  target_tags = ["prod-internal"]  # 백엔드 서버는 prod-internal 태그를 가지고 있음
}

# ========================================
# NAT Gateway (prod 전용 인터넷 접근)
# ========================================

# Cloud Router
resource "google_compute_router" "prod_router" {
  name    = "prod-router"
  region  = var.region
  network = google_compute_network.prod_vpc.id
}

# NAT Gateway
resource "google_compute_router_nat" "prod_nat" {
  name                               = "prod-nat"
  router                             = google_compute_router.prod_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# 기본 인터넷 라우트 (0.0.0.0/0)
resource "google_compute_route" "prod_default_route" {
  name             = "prod-default-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.prod_vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

# ========================================
# VM 인스턴스 생성
# ========================================

# Database 서버 (MySQL + Redis + MongoDB)
resource "google_compute_instance" "prod_database" {
  name         = "prod-database"
  machine_type = var.database_machine_type  # custom-1-6656 (1vCPU, 6.5GB RAM)
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.prod_vpc.name
    subnetwork = google_compute_subnetwork.prod_subnet.name
    network_ip = local.internal_ips.database
  }

  tags = ["prod-internal", "prod-ssh", "database"]

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  labels = merge(local.common_tags, {
    role = "database"
  })
}

# Backend 서버 (Spring Boot API)
resource "google_compute_instance" "prod_backend" {
  name         = "prod-backend"
  machine_type = var.backend_machine_type  # custom-1-6656 (1vCPU, 6.5GB RAM)
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network    = google_compute_network.prod_vpc.name
    subnetwork = google_compute_subnetwork.prod_subnet.name
    network_ip = local.internal_ips.backend
  }

  tags = ["prod-internal", "prod-ssh", "backend"]

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  labels = merge(local.common_tags, {
    role = "backend"
  })
}

# AI 서버 (FastAPI)
resource "google_compute_instance" "prod_ai" {
  name         = "prod-ai"
  machine_type = var.ai_machine_type  # e2-highmem-2 (2vCPU, 16GB RAM)
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 40
    }
  }

  network_interface {
    network    = google_compute_network.prod_vpc.name
    subnetwork = google_compute_subnetwork.prod_subnet.name
    network_ip = local.internal_ips.ai
  }

  tags = ["prod-internal", "prod-ssh", "ai"]

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  labels = merge(local.common_tags, {
    role = "ai"
  })
}

# ========================================
# 로드 밸런서 설정
# ========================================

# 백엔드 서비스 헬스체크
resource "google_compute_health_check" "prod_backend_health" {
  name = "prod-backend-health"

  http_health_check {
    port         = 8080
    request_path = "/api/group-buys"  # Backend API 엔드포인트 사용
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# AI 서비스 헬스체크
resource "google_compute_health_check" "prod_ai_health" {
  name = "prod-ai-health"

  http_health_check {
    port         = 8100
    request_path = "/health"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# 인스턴스 그룹 - Backend
resource "google_compute_instance_group" "prod_backend_group" {
  name = "prod-backend-group"
  zone = var.zone

  instances = [
    google_compute_instance.prod_backend.id
  ]

  named_port {
    name = "http"
    port = "8080"
  }
}

# 인스턴스 그룹 - AI
resource "google_compute_instance_group" "prod_ai_group" {
  name = "prod-ai-group"
  zone = var.zone

  instances = [
    google_compute_instance.prod_ai.id
  ]

  named_port {
    name = "http"
    port = "8100"
  }
}

# 백엔드 서비스
resource "google_compute_backend_service" "prod_backend_service" {
  name                   = "prod-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 120  # AI 생성 API 호출을 위해 타임아웃 증가 (2025-07-08)
  health_checks         = [google_compute_health_check.prod_backend_health.id]

  backend {
    group           = google_compute_instance_group.prod_backend_group.id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

# AI 서비스
resource "google_compute_backend_service" "prod_ai_service" {
  name                   = "prod-ai-service"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 120  # AI 추론 작업을 위해 길게 설정
  health_checks         = [google_compute_health_check.prod_ai_health.id]

  backend {
    group           = google_compute_instance_group.prod_ai_group.id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

# URL 맵 설정
resource "google_compute_url_map" "prod_url_map" {
  name            = "prod-url-map"
  default_service = google_compute_backend_bucket.prod_cdn_backend.id

  # 도메인별 라우팅
  host_rule {
    hosts        = [var.domain]
    path_matcher = "api-matcher"
  }

  path_matcher {
    name            = "api-matcher"
    default_service = google_compute_backend_bucket.prod_cdn_backend.id

    # API 경로 - Backend Service로 라우팅
    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.prod_backend_service.id
    }

    # AI/Generation 경로 - AI Service로 라우팅
    path_rule {
      paths   = ["/generation/*", "/generate/*"]
      service = google_compute_backend_service.prod_ai_service.id
    }

    # 정적 자산들은 CDN으로
    path_rule {
      paths   = ["/assets/*", "/static/*", "/icons/*", "/images/*", "/fonts/*", "/js/*", "/css/*"]
      service = google_compute_backend_bucket.prod_cdn_backend.id
    }

    # 특정 파일들도 CDN으로
    path_rule {
      paths   = ["/favicon.ico", "/manifest.json", "/robots.txt"]
      service = google_compute_backend_bucket.prod_cdn_backend.id
    }

    # SPA 경로들을 명시적으로 index.html로 라우팅
    path_rule {
      paths = ["/", "/index.html", "/products", "/products/*", "/login", "/signup", "/mypage", "/chat", "/chat/*", "/writePost", "/editPost/*", "/signupInfo", "/editProfile", "/editPassword"]
      service = google_compute_backend_bucket.prod_cdn_backend.id
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/index.html"
        }
      }
    }
  }
}

# 글로벌 외부 IP 주소
resource "google_compute_global_address" "prod_main_ip" {
  name         = "prod-main-ip"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# 글로벌 로드밸런서 프론트엔드 (HTTPS)
resource "google_compute_global_forwarding_rule" "prod_forwarding_rule" {
  name       = "prod-forwarding-rule"
  target     = google_compute_target_https_proxy.prod_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.prod_main_ip.address
}

# HTTPS 프록시
resource "google_compute_target_https_proxy" "prod_https_proxy" {
  name             = "prod-https-proxy"
  url_map          = google_compute_url_map.prod_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.prod_ssl_cert.id]
}

# SSL 인증서
resource "google_compute_managed_ssl_certificate" "prod_ssl_cert" {
  name = "prod-ssl-cert"

  managed {
    domains = [var.domain]
  }
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "prod_http_redirect" {
  name = "prod-http-redirect"
  
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "prod_http_proxy" {
  name    = "prod-http-proxy"
  url_map = google_compute_url_map.prod_http_redirect.id
}

resource "google_compute_global_forwarding_rule" "prod_http_forwarding_rule" {
  name       = "prod-http-forwarding-rule"
  target     = google_compute_target_http_proxy.prod_http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.prod_main_ip.address
}

# ========================================
# 프론트엔드 설정 (GCS + CDN)
# ========================================

# GCS 버킷 (프론트엔드 호스팅)
resource "google_storage_bucket" "prod_frontend" {
  name          = "moongsan-prod-frontend"
  location      = "ASIA-NORTHEAST3"
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["https://${var.domain}"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = local.common_tags
}

# GCS 버킷 권한 설정 (공개 읽기)
resource "google_storage_bucket_iam_member" "prod_frontend_public" {
  bucket = google_storage_bucket.prod_frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Cloud CDN 백엔드 버킷
resource "google_compute_backend_bucket" "prod_cdn_backend" {
  name        = "prod-cdn-backend"
  bucket_name = google_storage_bucket.prod_frontend.name
  enable_cdn  = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    client_ttl                   = 3600
    negative_caching             = true
    serve_while_stale            = 86400
  }
}

# ========================================
# VPC 피어링 (shared 환경과 연결)
# ========================================

# Shared VPC와 피어링 (prod → shared)
resource "google_compute_network_peering" "prod_to_shared" {
  name         = "prod-to-shared-peering"
  network      = google_compute_network.prod_vpc.id
  peer_network = "projects/${var.project_id}/global/networks/shared-vpc"

  import_custom_routes = true
  export_custom_routes = true
}

# Shared VPC에서 prod로 피어링 (shared → prod)
resource "google_compute_network_peering" "shared_to_prod" {
  name         = "shared-to-prod-peering"
  network      = "projects/${var.project_id}/global/networks/shared-vpc"
  peer_network = google_compute_network.prod_vpc.id

  import_custom_routes = true
  export_custom_routes = true
}

# ========================================
# 출력값
# ========================================

# 생성된 리소스 정보 출력
output "prod_environment_info" {
  description = "Production environment information"
  value = {
    vpc_name    = google_compute_network.prod_vpc.name
    subnet_name = google_compute_subnetwork.prod_subnet.name
    vpc_cidr    = local.vpc_cidr
    region      = var.region
    zone        = var.zone
  }
}

output "prod_vm_info" {
  description = "Production VM information"
  value = {
    database = {
      name        = google_compute_instance.prod_database.name
      internal_ip = google_compute_instance.prod_database.network_interface[0].network_ip
      machine_type = google_compute_instance.prod_database.machine_type
    }
    backend = {
      name        = google_compute_instance.prod_backend.name
      internal_ip = google_compute_instance.prod_backend.network_interface[0].network_ip  
      machine_type = google_compute_instance.prod_backend.machine_type
    }
    ai = {
      name        = google_compute_instance.prod_ai.name
      internal_ip = google_compute_instance.prod_ai.network_interface[0].network_ip
      machine_type = google_compute_instance.prod_ai.machine_type
    }
  }
}

output "prod_lb_info" {
  description = "Production load balancer information"
  value = {
    ip_address = google_compute_global_address.prod_main_ip.address
    domain     = var.domain
  }
}

output "prod_frontend_info" {
  description = "Production frontend information"
  value = {
    bucket_name = google_storage_bucket.prod_frontend.name
    bucket_url  = google_storage_bucket.prod_frontend.url
    cdn_enabled = google_compute_backend_bucket.prod_cdn_backend.enable_cdn
  }
}

# Ansible 호스트 파일 생성
resource "local_file" "prod_ansible_hosts" {
  content = jsonencode({
    jumpbox = {
      shared-jumpbox = {
        ansible_host = "34.22.110.81"  # shared jumpbox IP
        ansible_user = "lsh"
      }
    }
    backend = {
      prod-backend = {
        ansible_host = google_compute_instance.prod_backend.network_interface[0].network_ip
        ansible_user = "ubuntu"
      }
    }
    ai = {
      prod-ai = {
        ansible_host = google_compute_instance.prod_ai.network_interface[0].network_ip
        ansible_user = "ubuntu"
      }
    }
    database = {
      prod-database = {
        ansible_host = google_compute_instance.prod_database.network_interface[0].network_ip
        ansible_user = "ubuntu"
      }
    }
    _meta = {
      hostvars = {
        "shared-jumpbox" = {
          ansible_host = "34.22.110.81"
          ansible_user = "lsh"
        }
        "prod-backend" = {
          ansible_host = google_compute_instance.prod_backend.network_interface[0].network_ip
          ansible_user = "ubuntu"
          internal_ip = google_compute_instance.prod_backend.network_interface[0].network_ip
        }
        "prod-ai" = {
          ansible_host = google_compute_instance.prod_ai.network_interface[0].network_ip
          ansible_user = "ubuntu"
          internal_ip = google_compute_instance.prod_ai.network_interface[0].network_ip
        }
        "prod-database" = {
          ansible_host = google_compute_instance.prod_database.network_interface[0].network_ip
          ansible_user = "ubuntu"
          internal_ip = google_compute_instance.prod_database.network_interface[0].network_ip
        }
      }
    }
  })
  filename = "${path.module}/ansible_hosts.json"
}
