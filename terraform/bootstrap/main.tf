# ========================================
# Terraform Bootstrap Configuration
# GCS 백엔드 설정을 위한 초기 리소스 생성
# ========================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# GCP Provider 설정
provider "google" {
  project = var.project_id
  region  = var.region
}

# Terraform 상태 저장용 GCS 버킷
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-terraform-state"
  location      = var.region
  force_destroy = true  # 개발/테스트 환경에서는 정리 허용
  
  # 버전 관리 활성화
  versioning {
    enabled = true
  }
  
  # 수명 주기 관리
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  # KMS 암호화 설정
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state_key.id
  }
  
  # 공개 액세스 방지
  public_access_prevention = "enforced"
  
  labels = {
    environment = var.environment
    purpose     = "terraform-state"
    managed_by  = "terraform"
  }
  
  lifecycle {
    prevent_destroy = false  # Bootstrap 환경에서는 테스트/정리를 위해 false 설정
  }
}

# KMS 키링 생성
resource "google_kms_key_ring" "terraform_state" {
  name     = "terraform-state-keyring"
  location = var.region
}

# KMS 암호화 키 생성
resource "google_kms_crypto_key" "terraform_state_key" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.terraform_state.id
  purpose  = "ENCRYPT_DECRYPT"
  
  lifecycle {
    prevent_destroy = false  # Bootstrap 환경에서는 테스트/정리를 위해 false 설정
  }
}

# 필요한 API들 활성화
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "compute.googleapis.com", 
    "storage-component.googleapis.com",
    "dns.googleapis.com",
    "vpcaccess.googleapis.com",
    "cloudkms.googleapis.com"
  ])
  
  service = each.value
  disable_dependent_services = true
}