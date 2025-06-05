# ========================================
# Terraform Backend Configuration - Development
# Bootstrap 실행 후 활성화
# ========================================

# Bootstrap 완료 후 주석을 해제하세요
terraform {
  backend "gcs" {
    bucket = "ktb-2-moongsan-terraform-state"
    prefix = "environments/dev"
    # KMS 암호화 (선택사항)
    encryption_key = "projects/ktb-2-moongsan/locations/asia-northeast3/keyRings/terraform-state/cryptoKeys/terraform-state-key"
  }
}