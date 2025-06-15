# Shared Jump Box 모듈 - 모든 환경에 접근 가능한 통합 관리 서버

# Management VPC 네트워크 생성
resource "google_compute_network" "management_vpc" {
  name                    = var.management_vpc_name
  auto_create_subnetworks = false
  description             = "Management VPC for shared infrastructure"
}

# Management 서브넷 생성
resource "google_compute_subnetwork" "management_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.management_vpc.id
  description   = "Management subnet for shared jumpbox and tools"

  # Private Google Access 활성화 (GCP 서비스 접근용)
  private_ip_google_access = true
}

# 공용 고정 IP 주소
resource "google_compute_address" "jumpbox_ip" {
  name         = "${var.jumpbox_name}-ip"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for shared jumpbox"
}

# 공유 Jump Box VM
resource "google_compute_instance" "shared_jumpbox" {
  name         = var.jumpbox_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/${var.image_family}"
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.management_subnet.id
    access_config {
      nat_ip = google_compute_address.jumpbox_ip.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/compute"
    ]
  }

  tags = var.tags
}

# SSH 접근을 위한 방화벽 규칙
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.management_vpc_name}-allow-ssh"
  network = google_compute_network.management_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.tags
}

# WireGuard 포트를 위한 방화벽 규칙
resource "google_compute_firewall" "allow_wireguard" {
  name    = "${var.management_vpc_name}-allow-wireguard"
  network = google_compute_network.management_vpc.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.tags
}

# 환경별 VPC 접근을 위한 방화벽 규칙
resource "google_compute_firewall" "allow_environment_access" {
  for_each = var.environment_vpc_cidrs

  name    = "${var.management_vpc_name}-allow-${each.key}"
  network = google_compute_network.management_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3000", "8080", "5432", "6379"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [each.value]
  target_tags   = var.tags
}

# 관리 VPC에서 환경별 VPC로의 접근을 위한 방화벽 규칙
resource "google_compute_firewall" "allow_management_to_environments" {
  for_each = var.environment_vpc_cidrs

  name    = "${var.management_vpc_name}-to-${each.key}"
  network = google_compute_network.management_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3000", "8080", "5432", "6379"]
  }

  allow {
    protocol = "icmp"
  }

  destination_ranges = [each.value]
  target_tags        = var.tags
}
