output "terraform_state_bucket" {
  description = "Terraform 상태 저장용 GCS 버킷 이름"
  value       = google_storage_bucket.terraform_state.name
}

output "terraform_state_bucket_url" {
  description = "Terraform 상태 저장용 GCS 버킷 URL"
  value       = google_storage_bucket.terraform_state.url
}

output "kms_key_id" {
  description = "Terraform 상태 암호화용 KMS 키 ID"
  value       = google_kms_crypto_key.terraform_state_key.id
}

output "enabled_apis" {
  description = "활성화된 GCP API 목록"
  value       = [for api in google_project_service.apis : api.service]
}

output "backend_config" {
  description = "환경별 Terraform 백엔드 설정 예시"
  value = {
    bucket         = google_storage_bucket.terraform_state.name
    prefix         = "environments"
    encryption_key = google_kms_crypto_key.terraform_state_key.id
  }
}
