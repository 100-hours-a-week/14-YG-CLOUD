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
  shared_vpc_cidr   = var.shared_vpc_cidr
}

# Jump Box는 shared 환경의 공유 jump box를 사용
# 별도의 test jump box는 생성하지 않음

# GCS 정적 호스팅 (Option 4: 버킷만 생성)
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
  network_ip          = "10.0.0.3"        # 고정 IP 지정
  assign_external_ip  = false
  network_tags        = ["internal", "ssh"]
  ssh_public_key_path = var.ssh_public_key_path
  ssh_user            = var.ssh_user
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
  network_ip          = "10.0.0.4"        # AI 서버 IP를 10.0.0.4로 변경
  assign_external_ip  = false
  network_tags        = ["internal", "ssh"]
  ssh_public_key_path = var.ssh_public_key_path
  ssh_user            = var.ssh_user
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
  network_ip          = "10.0.0.2"        # 고정 IP 지정 (원래 IP로 복원)
  assign_external_ip  = false
  network_tags        = ["internal", "ssh"]
  ssh_public_key_path = var.ssh_public_key_path
  ssh_user            = var.ssh_user
  # startup_script 제거 - Ansible로 애플리케이션 설정 관리
}

# Load Balancer - Option 4: 통합 구조 (정적 + 동적 콘텐츠)
module "load_balancer" {
  source = "../../modules/load_balancer"

  project_name        = var.project_name
  env                 = var.env
  zone                = var.zone
  network_self_link   = module.network.vpc_self_link
  backend_instances   = [module.backend.self_link]
  ai_instances        = [module.ai.self_link]
  enable_https        = true  # HTTPS 활성화
  ssl_domains         = [var.domain_name]
  
  # Option 4: GCS 연결
  gcs_bucket_name     = module.frontend_hosting.bucket_name
  domain_name         = var.domain_name
}

# GCP Health Check를 위한 방화벽 규칙
resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = module.network.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8100"]  # Backend와 AI 포트 모두 포함
  }

  source_ranges = [
    "130.211.0.0/22",  # GCP Health Check IP ranges
    "35.191.0.0/16"
  ]

  target_tags = ["internal"]  # 백엔드 서버는 internal 태그를 가지고 있음
}
