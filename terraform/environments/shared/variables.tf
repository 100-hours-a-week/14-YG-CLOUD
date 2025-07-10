variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
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
  default     = "moongsan-shared-jumpbox"
}

variable "jumpbox_machine_type" {
  description = "Jumpbox 머신 타입"
  type        = string
  default     = "e2-medium"  # 1vCPU, 4GB RAM
}

variable "jumpbox_disk_size" {
  description = "Jumpbox 디스크 크기 (GB)"
  type        = number
  default     = 20
}

variable "jumpbox_image_family" {
  description = "Jumpbox OS 이미지 패밀리"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "shared_vpc_name" {
  description = "공유 VPC 이름"
  type        = string
  default     = "shared-vpc"
}

variable "subnet_name" {
  description = "공유 서브넷 이름"
  type        = string
  default     = "shared-subnet"
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

variable "ssh_user" {
  description = "SSH 사용자명"
  type        = string
  default     = "ubuntu"
}

variable "tags" {
  description = "리소스 태그"
  type        = list(string)
  default     = ["shared", "management", "jumpbox"]
}

variable "elk_name" {
  description = "ELK 인스턴스 이름"
  type        = string
  default     = "shared-elk"
}

variable "elk_machine_type" {
  description = "ELK 머신 타입 (예: e2-standard-2, custom-2-12288 등)"
  type        = string
  default     = "custom-1-6656"  # 1vCPU, 6.5GB RAM
}

variable "elk_disk_size" {
  description = "ELK 디스크 크기 (GB)"
  type        = number
  default     = 50
}

variable "elk_image_family" {
  description = "ELK OS 이미지 패밀리"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "elk_subnet_name" {
  description = "ELK 인스턴스가 속할 서브넷 이름"
  type        = string
  default     = "shared-subnet"
}

variable "elk_tags" {
  description = "ELK 인스턴스 리소스 태그"
  type        = list(string)
  default     = ["shared", "elk"]
}

variable "elk_ssh_user" {
  description = "ELK 인스턴스 SSH 사용자명"
  type        = string
  default     = "lsh"
}

variable "elk_firewall_source_ranges" {
  description = "ELK 인스턴스 방화벽 허용 소스 IP 범위"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
