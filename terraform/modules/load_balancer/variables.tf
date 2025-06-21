# Load Balancer 모듈 변수

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "env" {
  description = "환경 (test, dev, prod)"
  type        = string
}

variable "zone" {
  description = "GCP 존"
  type        = string
}

variable "network_self_link" {
  description = "VPC 네트워크 self link"
  type        = string
}

variable "backend_instances" {
  description = "Backend 인스턴스 self link 목록"
  type        = list(string)
}

variable "ai_instances" {
  description = "AI 인스턴스 self link 목록"
  type        = list(string)
}

variable "enable_https" {
  description = "HTTPS 지원 활성화 여부"
  type        = bool
  default     = false
}

variable "ssl_domains" {
  description = "SSL 인증서용 도메인 목록"
  type        = list(string)
  default     = []
}

# Option 4: GCS CDN Backend 관련 변수들
variable "gcs_bucket_name" {
  description = "프론트엔드 정적 파일이 저장된 GCS 버킷 이름"
  type        = string
}

variable "domain_name" {
  description = "메인 도메인 이름 (SSL 인증서 및 라우팅용)"
  type        = string
}
