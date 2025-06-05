# Test 환경 Terraform 설정

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
  credentials = file(var.gcp_credentials_path)
  project     = var.project_id
  region      = var.region
}

# 네트워크 모듈
module "network" {
  source = "../../modules/network"

  project_name      = var.project_name
  env               = var.env
  region            = var.region
  subnet_cidr       = var.subnet_cidr
  wireguard_cidr    = var.wireguard_cidr
  ssh_source_ranges = var.ssh_source_ranges
}

# Jump Box용 고정 IP
module "jumpbox_ip" {
  source = "../../modules/static_ip"

  project_name = var.project_name
  env          = var.env
  ip_name      = "jumpbox"
  region       = var.region
}

# WireGuard 설정
module "wireguard" {
  source = "../../modules/wireguard"

  wireguard_server_ip       = "10.8.0.1/24"
  wireguard_port            = 51820
  wireguard_private_key     = var.wireguard_private_key
  wireguard_public_key      = var.wireguard_public_key
  wireguard_server_endpoint = module.jumpbox_ip.ip_address
  wireguard_clients         = var.wireguard_clients
  allowed_ips               = "10.8.0.0/24,10.0.0.0/24"
}

# Jump Box VM (WireGuard 서버)
module "jumpbox" {
  source = "../../modules/compute"

  project_name        = var.project_name
  env                 = var.env
  vm_name             = "jumpbox"
  vm_role             = "jumpbox"
  tier                = "management"
  machine_type        = "e2-medium"
  zone                = var.zone
  network_name        = module.network.vpc_name
  subnet_name         = module.network.subnet_name
  assign_external_ip  = true
  external_ip_address = module.jumpbox_ip.ip_address
  network_tags        = ["ssh", "wireguard-server"]
  ssh_public_key_path = var.ssh_public_key_path
  startup_script      = module.wireguard.startup_script
}

# GCS + CDN for Frontend Static Hosting
module "frontend_hosting" {
  source = "../../modules/gcs_cdn"

  project_name = var.project_name
  env          = var.env
  domain_name  = var.domain_name
}

# Backend VM
module "backend" {
  source = "../../modules/compute"

  project_name        = var.project_name
  env                 = var.env
  vm_name             = "backend"
  vm_role             = "backend"
  tier                = "app"
  machine_type        = "e2-standard-2"
  zone                = var.zone
  network_name        = module.network.vpc_name
  subnet_name         = module.network.subnet_name
  assign_external_ip  = false
  network_tags        = ["internal"]
  ssh_public_key_path = var.ssh_public_key_path
  # startup_script 제거 - Ansible로 애플리케이션 설정 관리
}

# AI VM
module "ai" {
  source = "../../modules/compute"

  project_name        = var.project_name
  env                 = var.env
  vm_name             = "ai"
  vm_role             = "ai"
  tier                = "app"
  machine_type        = "e2-highmem-2"
  zone                = var.zone
  network_name        = module.network.vpc_name
  subnet_name         = module.network.subnet_name
  assign_external_ip  = false
  network_tags        = ["internal"]
  ssh_public_key_path = var.ssh_public_key_path
  # startup_script 제거 - Ansible로 애플리케이션 설정 관리
}

# Database VM
module "database" {
  source = "../../modules/compute"

  project_name        = var.project_name
  env                 = var.env
  vm_name             = "database"
  vm_role             = "database"
  tier                = "data"
  machine_type        = "e2-standard-2"
  zone                = var.zone
  disk_size           = 100
  network_name        = module.network.vpc_name
  subnet_name         = module.network.subnet_name
  assign_external_ip  = false
  network_tags        = ["internal"]
  ssh_public_key_path = var.ssh_public_key_path
  # startup_script 제거 - Ansible로 애플리케이션 설정 관리
}
