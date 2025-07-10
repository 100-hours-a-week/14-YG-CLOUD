# ========================================
# Production Environment Variables
# ========================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "ktb-2-moongsan"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast3-a"
}

variable "domain" {
  description = "Production domain name"
  type        = string
  default     = "moongsan.com"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# SSH 설정
variable "ssh_user" {
  description = "SSH user name"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/lsh-study-key.pub"
}

# VM 설정
variable "database_machine_type" {
  description = "Database server machine type"
  type        = string
  default     = "custom-1-6656"  # 1vCPU, 6.5GB RAM
}

variable "backend_machine_type" {
  description = "Backend server machine type"
  type        = string
  default     = "custom-1-6656"  # 1vCPU, 6.5GB RAM
}

variable "ai_machine_type" {
  description = "AI server machine type"
  type        = string
  default     = "e2-highmem-2"  # AI 서버는 유지 (2vCPU, 16GB RAM)
}

# 네트워크 설정
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "internal_ips" {
  description = "Internal IP addresses for VMs"
  type        = map(string)
  default = {
    database = "10.1.0.2"
    backend  = "10.1.0.3"
    ai       = "10.1.0.4"
  }
}

# GCS 설정
variable "frontend_bucket_name" {
  description = "Frontend GCS bucket name"
  type        = string
  default     = "moongsan-prod-frontend"
}

# SSL 설정
variable "ssl_domains" {
  description = "Domains for SSL certificate"
  type        = list(string)
  default     = ["moongsan.com", "www.moongsan.com"]
}

# 태그
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    environment = "prod"
    project     = "moongsan"
    managed_by  = "terraform"
  }
}
