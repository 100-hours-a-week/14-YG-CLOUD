terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Shared VPC 네트워크 생성
resource "google_compute_network" "shared_vpc" {
  name                    = "shared-vpc"
  auto_create_subnetworks = false
  description             = "Shared VPC for shared infrastructure"
}

# Shared 서브넷 생성
resource "google_compute_subnetwork" "shared_subnet" {
  name          = "shared-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.shared_vpc.id
  description   = "Shared subnet for shared jumpbox and tools"

  # Private Google Access 활성화 (GCP 서비스 접근용)
  private_ip_google_access = true
}

# 공용 고정 IP 주소
resource "google_compute_address" "jumpbox_ip" {
  name         = "moongsan-shared-jumpbox-ip"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for shared jumpbox"
}

# 공유 Jump Box VM
resource "google_compute_instance" "shared_jumpbox" {
  name         = var.jumpbox_name
  machine_type = var.jumpbox_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.jumpbox_disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.shared_vpc.name
    subnetwork = google_compute_subnetwork.shared_subnet.name
    
    access_config {
      nat_ip = google_compute_address.jumpbox_ip.address
    }
  }

  metadata = {
    ssh-keys = "lsh:${var.ssh_public_key}"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  tags = var.tags
}

# SSH 접근 허용 방화벽 규칙
resource "google_compute_firewall" "allow_ssh" {
  name    = "shared-allow-ssh"
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.tags
}

# WireGuard VPN 접근 허용 방화벽 규칙
resource "google_compute_firewall" "allow_wireguard" {
  name    = "shared-allow-wireguard"
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.tags
}

# 환경별 VPC 접근 허용 방화벽 규칙
resource "google_compute_firewall" "allow_environment_access" {
  name    = "shared-allow-environments"
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3000", "5000", "8000", "8080", "3306", "5432"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    for cidr in var.environment_vpc_cidrs : cidr
  ]

  target_tags = var.tags
}

# 기존 환경별 VPC 정보 가져오기 (data source)
# 현재 배포된 환경들만 포함
data "google_compute_network" "test_vpc" {
  name = "moongsan-test-vpc"
}

# VPC 피어링 모듈 - 공유 VPC와 환경별 VPC 연결
module "vpc_peering" {
  source = "../../modules/vpc_peering"

  project_name         = "moongsan"
  shared_vpc_self_link = google_compute_network.shared_vpc.self_link
  
  environment_vpcs = {
    test = data.google_compute_network.test_vpc.self_link
    # dev와 prod는 해당 환경 배포 후 추가
    # dev  = data.google_compute_network.dev_vpc.self_link
    # prod = data.google_compute_network.prod_vpc.self_link
  }
}
