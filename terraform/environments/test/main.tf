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

# Jump Box는 shared 환경의 공유 jump box를 사용
# 별도의 test jump box는 생성하지 않음

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
  disk_size           = 30                 # 최적화: 50GB → 30GB (Spring Boot + 로그용)
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
  machine_type        = "e2-highmem-2"     # 16GB 메모리 유지, 비용 최적화
  disk_size           = 40                 # 최적화: 50GB → 40GB (AI 모델용 여유 유지)
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

# Load Balancer - 3-tier 아키텍처 완성
module "load_balancer" {
  source = "../../modules/load_balancer"

  project_name        = var.project_name
  env                 = var.env
  zone                = var.zone
  network_self_link   = module.network.vpc_self_link
  backend_instances   = [module.backend.self_link]
  ai_instances        = [module.ai.self_link]
  enable_https        = false  # 초기에는 HTTP만 사용
  ssl_domains         = []
}
