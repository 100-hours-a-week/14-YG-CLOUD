# Shared Jump Box 모듈 - 모든 환경에 접근 가능한 통합 관리 서버

# Management VPC 네트워크 생성
resource "google_compute_network" "management_vpc" {
  name                    = "${var.project_name}-management-vpc"
  auto_create_subnetworks = false
  description             = "Management VPC for shared infrastructure"
}

# Management 서브넷 생성
resource "google_compute_subnetwork" "management_subnet" {
  name          = "${var.project_name}-management-subnet"
  ip_cidr_range = var.management_vpc_cidr
  region        = var.region
  network       = google_compute_network.management_vpc.id
  description   = "Management subnet for shared jumpbox and tools"

  # Private Google Access 활성화 (GCP 서비스 접근용)
  private_ip_google_access = true
}

# 공용 고정 IP 주소
resource "google_compute_address" "jumpbox_ip" {
  name         = "${var.project_name}-shared-jumpbox-ip"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for shared jumpbox"
}

# 공유 Jump Box VM
resource "google_compute_instance" "shared_jumpbox" {
  name         = "${var.project_name}-shared-jumpbox"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network    = google_compute_network.management_vpc.name
    subnetwork = google_compute_subnetwork.management_subnet.name
    
    access_config {
      nat_ip = google_compute_address.jumpbox_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["shared-jumpbox", "wireguard-server", "ssh"]

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  labels = {
    environment = "shared"
    tier        = "management"
    role        = "jumpbox"
  }
}

# 방화벽 규칙 - SSH 접근
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-management-allow-ssh"
  network = google_compute_network.management_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]
}

# 방화벽 규칙 - WireGuard
resource "google_compute_firewall" "allow_wireguard" {
  name    = "${var.project_name}-management-allow-wireguard"
  network = google_compute_network.management_vpc.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["wireguard-server"]
}

# 방화벽 규칙 - 환경별 네트워크 접근
resource "google_compute_firewall" "allow_environment_access" {
  for_each = var.environment_networks
  
  name    = "${var.project_name}-management-to-${each.key}"
  network = google_compute_network.management_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3306", "6379", "8080", "8100", "3000", "9090", "9100"]
  }

  allow {
    protocol = "icmp"
  }

  source_tags = ["shared-jumpbox"]
  # destination_ranges는 VPC 피어링 후 설정
}

# NAT Gateway (인터넷 접근용)
resource "google_compute_router" "management_router" {
  name    = "${var.project_name}-management-router"
  region  = var.region
  network = google_compute_network.management_vpc.id
}

resource "google_compute_router_nat" "management_nat" {
  name                               = "${var.project_name}-management-nat"
  router                             = google_compute_router.management_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
