variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명용)"
  type        = string
  default     = "moongsan"
}

variable "region" {
  description = "GCP 리전"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP 존"
  type        = string
  default     = "asia-northeast3-a"
}

variable "jumpbox_name" {
  description = "Jumpbox 인스턴스 이름"
  type        = string
  default     = "shared-jumpbox"
}

variable "machine_type" {
  description = "Jumpbox 머신 타입"
  type        = string
  default     = "e2-small"
}

variable "disk_size" {
  description = "Jumpbox 디스크 크기 (GB)"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "부트 디스크 타입"
  type        = string
  default     = "pd-standard"
}

variable "image" {
  description = "부트 디스크 이미지"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "image_family" {
  description = "Jumpbox OS 이미지 패밀리"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "management_vpc_name" {
  description = "관리 VPC 이름"
  type        = string
  default     = "management-vpc"
}

variable "management_vpc_cidr" {
  description = "관리 VPC CIDR"
  type        = string
  default     = "10.100.0.0/16"
}

variable "subnet_name" {
  description = "관리 서브넷 이름"
  type        = string
  default     = "management-subnet"
}

variable "subnet_cidr" {
  description = "관리 서브넷 CIDR"
  type        = string
  default     = "10.100.0.0/24"
}

variable "environment_vpc_cidrs" {
  description = "환경별 VPC CIDR 블록 (방화벽 규칙용)"
  type = map(string)
  default = {
    dev  = "10.0.0.0/16"
    test = "10.1.0.0/16"
    prod = "10.2.0.0/16"
  }
}

variable "ssh_public_key" {
  description = "SSH 공개 키"
  type        = string
}

variable "ssh_public_key_path" {
  description = "SSH 공개 키 파일 경로"
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH 사용자명"
  type        = string
  default     = "lsh"
}

variable "ssh_source_ranges" {
  description = "SSH 접근 허용 IP 범위"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "wireguard_port" {
  description = "WireGuard 포트"
  type        = number
  default     = 51820
}

variable "wireguard_cidr" {
  description = "WireGuard VPN CIDR"
  type        = string
  default     = "10.8.0.0/24"
}

variable "tags" {
  description = "리소스 태그"
  type        = list(string)
  default     = ["shared", "management", "jumpbox"]
}
