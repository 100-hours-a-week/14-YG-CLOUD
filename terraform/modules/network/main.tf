# Network 모듈 - VPC, 서브넷, 방화벽 관리

# VPC 네트워크 생성
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.env}-vpc"
  auto_create_subnetworks = false
  description             = "${var.env} environment VPC for ${var.project_name}"
}

# 서브넷 생성
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-${var.env}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "${var.env} environment subnet"

  # Private Google Access 활성화 (GCP 서비스 접근용)
  private_ip_google_access = true
}

# 방화벽 규칙 - SSH 접근
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-${var.env}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]
}

# 방화벽 규칙 - HTTP/HTTPS
resource "google_compute_firewall" "allow_web" {
  name    = "${var.project_name}-${var.env}-allow-web"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

# 방화벽 규칙 - WireGuard
resource "google_compute_firewall" "allow_wireguard" {
  name    = "${var.project_name}-${var.env}-allow-wireguard"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["wireguard-server"]
}

# 방화벽 규칙 - 내부 통신 (WireGuard 네트워크)
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-${var.env}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3306", "6379", "8080", "8100", "9090", "9100", "3000"]
  }

  source_ranges = [var.wireguard_cidr]
  target_tags   = ["internal"]
}

# NAT Gateway (Private VM들의 인터넷 접근용)
resource "google_compute_router" "router" {
  name    = "${var.project_name}-${var.env}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_name}-${var.env}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
