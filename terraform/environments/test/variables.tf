# 프로젝트 설정
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "ktb-2-moongsan"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "moongsan"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-northeast3-a"
}

variable "gcp_credentials_path" {
  description = "Path to GCP credentials JSON file"
  type        = string
  default     = "/Users/lsh/workspace/downloads/keys/ktb-2-moongsan-d9d52232b71b.json"
}

# 네트워크 설정
variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "wireguard_cidr" {
  description = "CIDR block for WireGuard VPN"
  type        = string
  default     = "10.8.0.0/24"
}

variable "ssh_source_ranges" {
  description = "Source IP ranges allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # 보안을 위해 실제 사용 시 특정 IP로 제한
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/lsh-study-key.pub"
}

# WireGuard 설정
variable "wireguard_private_key" {
  description = "WireGuard server private key"
  type        = string
  sensitive   = true
}

variable "wireguard_public_key" {
  description = "WireGuard server public key"
  type        = string
}

variable "wireguard_clients" {
  description = "WireGuard client configurations"
  type = list(object({
    name        = string
    address     = string
    private_key = string
    public_key  = string
  }))
  default = [
    {
      name        = "backend"
      address     = "10.8.0.20/32"
      private_key = "" # terraform.tfvars에서 설정
      public_key  = "" # terraform.tfvars에서 설정
    },
    {
      name        = "ai"
      address     = "10.8.0.30/32"
      private_key = ""
      public_key  = ""
    },
    {
      name        = "database"
      address     = "10.8.0.40/32"
      private_key = ""
      public_key  = ""
    }
  ]
}

# VM 시작 스크립트 (제거됨 - Ansible로 대체)
# 인프라 레벨 설정만 startup_script 사용 (WireGuard 등)
# 애플리케이션 설정은 Ansible에서 관리

# Frontend 설정
variable "domain_name" {
  description = "Domain name for the frontend"
  type        = string
  default     = "test.moongsan.com"
}

# SSH 설정
